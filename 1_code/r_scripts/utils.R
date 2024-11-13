# ---
# title: "misc_functions"
# author: "Brendan Casey"
# created: "2024-05-24"
# description: " Miscellaneous R functions."
# ---

## ////////////////////////////////////////////////////////////////

## points_to_squares----
# Function to create a square from a center point and radius
create_square <- function(center, radius) {
  # Calculate the half side length of the square (which is the radius 
  # of the circle)
  half_side <- radius
  
  # Coordinates of the center
  x <- center[1]
  y <- center[2]
  
  # Calculate the vertices of the square
  vertices <- matrix(nrow = 5, ncol = 2,
                     data = c(x - half_side, y - half_side,
                              x + half_side, y - half_side,
                              x + half_side, y + half_side,
                              x - half_side, y + half_side,
                              x - half_side, y - half_side), 
                     byrow = TRUE)
  
  # Create an sf polygon
  square <- st_polygon(list(vertices))
  return(square)
}

# Function to convert sf points to sf squares
points_to_squares <- function(points, radius) {
  # Extract coordinates from points
  coords <- st_coordinates(points)
  
  # Create a list to store squares
  squares <- list()
  
  # Loop over each point and create a square
  for (i in 1:nrow(coords)) {
    center <- coords[i, ]
    square <- create_square(center, radius)
    squares[[i]] <- square
  }
  
  # Convert list of squares to sf object
  squares_sf <- st_sfc(squares)
  
  # Create a new sf object that includes the fields from the points
  squares_sf <- st_sf(data = st_drop_geometry(points), 
                      geometry = squares_sf)
  
  # Remove 'data.' prefix from field names
  names(squares_sf) <- gsub("^data\\.", "", names(squares_sf))
  
  # Return sf object of squares
  return(squares_sf)
}

# Example usage
# Load the sf package
# library(sf)

## Create some example points
# points <- st_as_sf(data.frame(x = c(1, 2, 3), y = c(1, 2, 3)), 
#                    coords = c("x", "y"), crs = 4326)
# points <- st_transform(points, crs=3348) #convert to meters

## Define the radius
# radius <- 50

## Convert the points to squares
# squares <- points_to_squares(points, radius)

## Check the result
# plot(squares)

## ////////////////////////////////////////////////////////////////

# ## calculate_brt_stats ----
# # Funtion to get statistics from a brt model.
# calculate_brt_stats <- function(model) {
#   # Automatically get the name of the model variable
#   model_name <- deparse(substitute(model))
#   
#   # Calculate CV stats
#   cvstats <- as.data.frame(model$cv.statistics[c(1, 3, 5)])
#   cvstats$deviance.null <- model$self.statistics$mean.null
#   cvstats$deviance.explained <- 
#     (cvstats$deviance.null - cvstats$deviance.mean) / 
#     cvstats$deviance.null
#   cvstats$model_name<- rep(model_name, nrow(cvstats))
#   colnames(cvstats)[colnames(cvstats) == "discrimination.mean"] <- "AUC"
  
  # Calculate variable importance
## calculate_brt_stats ----
# Funtion to get statistics from a brt model.
calculate_brt_stats <- function(model) {
  # Automatically get the name of the model variable
  model_name <- deparse(substitute(model))
  
  # Calculate CV stats
  cvstats <- as.data.frame(model$cv.statistics[c(1, 3, 5)])
  cvstats$deviance.null <- model$self.statistics$mean.null
  cvstats$deviance.explained <- 
    (cvstats$deviance.null - cvstats$deviance.mean) / 
    cvstats$deviance.null
  cvstats$model<- rep(model_name, nrow(cvstats))

  # Calculate variable importance
  varimp <- as.data.frame(model$contributions) %>%
    pivot_wider(names_from = var, values_from = rel.inf)
  
  # Combine cvstats and varimp into a single data frame
  combined_df <- bind_cols(cvstats, varimp)
  
  # Move "model_name" to the first column
  combined_df <- combined_df[c("model", 
                               setdiff(names(combined_df), 
                                       "model"))]
  
  # Return a list containing both CV stats and variable importance
  return(combined_df)
}


create_buffered_area <- function(lon, lat, buffer_dist_km) {
  # This function creates a buffered area around a given point.
  # Requirements: sf package
  # Args:
  #   lon: Longitude of the point (numeric).
  #   lat: Latitude of the point (numeric).
  #   buffer_dist_km: Distance to buffer around the point (km).
  #
  # Returns:
  #   An sf object representing the AOI as a buffered polygon
  #   around the given point, in WGS 84 CRS.

  # Convert buffer distance from kilometers to meters
  buffer_dist_m <- buffer_dist_km * 1000
  
  # Create a point from the provided coordinates
  point <- st_sfc(st_point(c(lon, lat)), crs = 4326)
  
  # Transform the point to a projected CRS that uses meters (e.g., UTM)
  point_utm <- st_transform(point, crs = st_crs(32632)) # Example UTM zone
  
  # Calculate the square bounds
  min_x <- st_coordinates(point_utm)[1] - buffer_dist_m
  max_x <- st_coordinates(point_utm)[1] + buffer_dist_m
  min_y <- st_coordinates(point_utm)[2] - buffer_dist_m
  max_y <- st_coordinates(point_utm)[2] + buffer_dist_m
  
  # Create a square polygon
  square <- st_polygon(list(rbind(c(min_x, min_y), c(min_x, max_y), 
                                  c(max_x, max_y), c(max_x, min_y), 
                                  c(min_x, min_y))))
  square_sf <- st_sfc(square, crs = st_crs(32632))
  
  # Transform the square back to WGS 84
  square_wgs84 <- st_transform(square_sf, crs = 4326)
  
  # Create an sf object from the square polygon
  aoi_sf <- st_sf(data.frame(id = 1), geometry = square_wgs84)
  
  # Return the area of interest as an sf object
  return(aoi_sf)
}

# Example usage:
# calling_lake_coords <- c(lon = -113.578, lat = 55.266)
# calling_lake_study_area <- create_buffered_area(
#   lon = calling_lake_coords["lon"], 
#   lat = calling_lake_coords["lat"], 
#   buffer_dist = 50
# )




#' Extract raster values point count locations
#'
#' @param xy_locations An sf object containing point locations.
#' @param raster A terra raster object from which to extract values.
#' @param buffer A numeric value specifying the buffer distance in meters 
#' (optional).
#' @param fun A function to apply to the extracted raster values 
#' (optional).
#' @return A data frame with the extracted values and the results of the 
#' applied function.
#' 
#' @example
#' # points_df <- data.frame(
#   x = c(6.13750, 6.14412, 6.141592, 6.133408, 6.13088),
#   y = c(49.82086, 49.81776, 49.812736, 49.812736, 49.81776)
# )
# xy_locations <- st_as_sf(points_df, coords = c("x", "y"), crs = 4326)
# 
# raster <- rast(system.file("ex/elev.tif", package = "terra"))
# buffer <- 500
# fun <- "mean"
# result <- extract_raster_values(xy_locations, raster, buffer, fun)
# print(result)
extract_raster_values <- function(xy_locations, raster, buffer = NULL, fun = NULL) {
  # Ensure the input points are in the same CRS as the raster
  xy_locations <- st_transform(xy_locations, crs(raster))
  
  # Create buffers around the point locations if buffer is provided
  if (!is.null(buffer)) {
    if (!is.numeric(buffer)) {
      stop("The buffer argument must be numeric.")
    }
    xy_locations <- st_buffer(xy_locations, dist = buffer)
  }
  
  # Extract raster values within the (buffered) point locations
  if (is.null(fun)) {
    extracted_values <- terra::extract(raster, xy_locations, ID = FALSE)
    fun_name <- "first"
  } else {
    extracted_values <- terra::extract(raster, xy_locations, fun = fun, ID = FALSE)
    fun_name <- deparse(substitute(fun))
  }
  
  # Append function name and buffer distance to the new extracted column names
  if (!is.null(buffer)) {
    colnames(extracted_values) <- paste0(colnames(extracted_values), "_", fun_name, "_", buffer)
  } else {
    colnames(extracted_values) <- paste0(colnames(extracted_values), "_", fun_name)
  }
  
  # Combine the extracted values with the original point locations
  result <- cbind(st_drop_geometry(xy_locations), extracted_values)
  
  return(result)
}



#' Calculate Focal Statistics on a Raster
#'
#' This function calculates focal statistics on a given raster using a 
#' specified window size and function.
#'
#' @param raster_input RasterLayer. The input raster on which to perform 
#' focal statistics.
#' @param window_size_meters Numeric. The desired window size in meters.
#' @param fun Function or character. The function to apply (e.g., 
#' "mean", "modal", "sd").
#' @return RasterLayer. A raster with the focal statistics calculated 
#' and the band names updated accordingly.
#' 
#' @example 
#' # Example usage of the function
#' # Create a sample raster
#' r <- raster(nrows=10, ncols=10)
#' r[] <- runif(ncell(r), 0, 100)
#' 
#' # Apply the function with mean
#' result_mean <- calculate_focal_stat(r, 500, mean)
#' print(names(result_mean))
calculate_focal_stat <- function(raster_input, window_size_meters, fun) {
  # Step 1: Get the cell size (assuming x and y resolution are the same)
  cell_size <- res(raster_input)[1]  
  
  # Step 2: Calculate window size
  window_size <- ceiling(window_size_meters / cell_size)
  
  # Step 3: Store the original raster band names
  original_names <- names(raster_input)
  
  # Step 4: Apply the terra::focal function
  focal_result <- focal(raster_input, 
                        w = matrix(1, 
                                   nrow = window_size, 
                                   ncol = window_size), 
                        fun = fun, na.rm = TRUE)
  
  # Step 5: Determine the function name for band naming
  fun_name <- ifelse(fun == "modal", "mode", fun)
  
  # Step 6: Create new names for the resulting raster bands
  new_names <- paste0(original_names, "_", fun_name, "_", 
                      window_size_meters)
  names(focal_result) <- new_names
  
  return(focal_result)
}

