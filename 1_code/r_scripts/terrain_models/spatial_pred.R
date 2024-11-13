# ---
# title: "5_spatial_predictions"
# author: "Brendan Casey"
# created: "2024-06-20"
# description: >
#   This script generates spatial predictions from a list of
#   bootstrapped models and a prediction grid of model
#   covariates. It outputs mean and standard deviation
#   predictive rasters.
# ---

# 1. Setup ----
## 1.1 Load packages ----
library(terra) # For working with rasters
library(parallel) # For parallel processing
library(dismo) # For species distribution modeling
library(gbm) # for processing gbm models
library(sf)
library(dplyr)
library(snakecase)
library(raster)


aoi <- st_read("0_data/external/alberta_bc_boundary/alberta_bc.shp")

## 1.2 Load prediction grid----
pred_raster <- rast("0_data/manual/raster_mosaics/all_fixed_90.tif")
# pred_geo <- rast("0_data/manual/raster_mosaics/geomorpho.tif")
# pred_geo <- project(pred_geo, crs(pred_raster))
# 
# # Align the extent and resolution of pred_geo to match pred_raster
# pred_geo_aligned <- resample(pred_geo, pred_raster, method = "bilinear")
# writeRaster(
#   pred_geo_aligned,
#   filename = "0_data/manual/raster_mosaics/geomorpho_aligned.tif",
#   overwrite = TRUE
# )
# 
# pred_raster <- c(pred_raster, pred_geo)


layer_names <- names(pred_raster)

# Remove the suffix '_first_0' from each layer name
new_layer_names <- gsub("_first_0$", "", gsub("\\-", "_", layer_names))

aoi <- st_transform(aoi, crs(pred_raster))

season_4 <- rast(pred_raster$CHILI)
values(season_4) <- "Spring"
names(season_4) <- "season_4"
season_4 <- mask(season_4, aoi)

Lat <- init(pred_raster, fun = "y")
names(Lat) <- "Lat"
Lat <- mask(Lat, aoi)

pred_raster <- c(pred_raster, season_4, Lat)

## 1.3 Load bootstrapped models ----
load("3_output/models/terrain/bootstrap_models_avg.rData")

## 1.4 Load custom functions ----
source("1_code/r_scripts/functions/replace_outliers.R")
source("1_code/r_scripts/functions/make_spatial_pred.R")

# 2. Filter prediction grid ----
## 2.1 Keep layers that match model covariates ----
# Extract covariate names from the first model in
# bootstrap_models
model_covariates <- bootstrap_models$models$model_1$var.names

# Identify the names in model_covariates that are not in
# pred_raster
pred_raster_names <- names(pred_raster)
missing_in_pred_raster <- setdiff(
  model_covariates,
  pred_raster_names
)

# Subset the pred_raster to keep only the layers that match
# the model covariates
pred_raster <- subset(pred_raster, model_covariates)

## 2.2 Create cropped raster for testing ----
##  Dummy AOI
# source("1_code/r_scripts/functions/utils.R")
# aoi <- create_buffered_area(lon = -113.578, lat = 55.266,
#                             buffer_dist = 10)
# aoi <- st_transform(aoi, crs(pred_raster))
# pred_raster <- crop(pred_raster, aoi)

# 3. Clean environment ----
# Clean environment to avoid memory issues.
# Remove all objects except pred_raster and bootstrap_models
rm(list = setdiff(ls(), c(
  "pred_raster", "bootstrap_models",
  "make_spatial_pred",
  "replace_outliers"
)))

# Run garbage collection to free up memory
gc()

# 4. Generate spatial predictions ----
output_dir <- "3_output/models/terrain/avg/spring"

spatial_pred <- make_spatial_pred(
  bootstrap_models$models[1:25],
  pred_raster,
  n_cores = 2, # Reduce the number of cores
  output_dir = output_dir
)

# 5. Clean Prediction Rasters ----
## 5.2 Mask water pixels ----
# Create mask
water_mask <- ifel(pred_raster$nfiLandCover_mode_500 != 8, 1, NA)
water_mask <- project(water_mask, crs(spatial_pred[[1]]))

# Apply mask
spatial_pred <- lapply(spatial_pred, function(raster) {
  masked_raster <- mask(raster, water_mask)
  masked_raster <- ifel(is.na(masked_raster), 0, masked_raster)
  return(masked_raster)
})

## 5.3 Mask grassland pixels ----
# Define the specific nsrname values to mask
nsrname_values <- c(
  "dry_mixedgrass", "foothills_fescue",
  "mixedgrass", "northern_fescue"
)

# Create a mask
nsrname_mask <- ifel(!(pred_raster$nsrname %in% nsrname_values), 1, NA)
nsrname_mask <- project(nsrname_mask, crs(spatial_pred[[1]]))

# Apply mask and replace NA values with 0
spatial_pred <- lapply(spatial_pred, function(raster) {
  masked_raster <- mask(raster, nsrname_mask)
  masked_raster <- ifel(is.na(masked_raster), 0, masked_raster)
  return(masked_raster)
})


## 5.1 Mask pixels outside of AOI ----
aoi <- st_transform(aoi, crs(spatial_pred$mean_raster))

spatial_pred <- lapply(spatial_pred, function(raster) {
  mask(raster, aoi)
})


## 5.3 Replace outlier pixels ----
n_sd_value <- 2

spatial_pred <- lapply(spatial_pred, function(raster) {
  replace_outliers(raster, n_sd = n_sd_value)
})

## 5.4 Rescale ----
# reduce size of raster by converting values to 8bit
scale_to_8bit <- function(raster) {
  # Scale the values to the 8-bit range (0-255)
  raster_8bit <- raster * 255
  
  # Ensure the values are within the 8-bit range
  raster_8bit[raster_8bit < 0] <- 0
  raster_8bit[raster_8bit > 255] <- 255
  
  # Convert the raster to 8-bit unsigned integer using the app function
  raster_8bit <- app(raster_8bit,
                     fun = function(x) as.integer(round(x))
  )
  
  return(raster_8bit)
}

spatial_pred_rescale_8bit <- lapply(spatial_pred, scale_to_8bit)

# Rescale to 0-1
rescale_raster <- function(raster) {
  min_val <- minmax(raster)[1]
  max_val <- minmax(raster)[2]
  (raster - min_val) / (max_val - min_val)
}

spatial_pred_rescale <- lapply(
  spatial_pred_rescale_8bit,
  rescale_raster
)

## 5.4 Save ----
writeRaster(spatial_pred$mean_raster,
            paste0(output_dir, "/mean_raster.tif"),
            overwrite = TRUE
)

writeRaster(spatial_pred$sd_raster,
            paste0(output_dir, "/sd_raster.tif"),
            overwrite = TRUE
)

writeRaster(spatial_pred_rescale$mean_raster,
            paste0(output_dir, "/mean_raster_rescale.tif"),
            overwrite = TRUE,
            gdal = c("COMPRESS=LZW") # apply LZW compression
)

writeRaster(spatial_pred_rescale$sd_raster,
            paste0(output_dir, "/sd_raster_rescale.tif"),
            overwrite = TRUE,
            gdal = c("COMPRESS=LZW") # apply LZW compression
)
