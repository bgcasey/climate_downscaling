#' Replace Outliers in Raster Data
#'
#' This function identifies and replaces outlier pixels in a raster 
#' dataset. Outliers are defined as values that fall outside a 
#' specified number of standard deviations from the mean. The 
#' function replaces these outliers with the upper bound of the 
#' normal range.
#'
#' @param raster SpatRaster. The input raster dataset.
#' @param n_sd Numeric. The number of standard deviations to use for 
#' defining outliers. Default is 3.
#' @return SpatRaster. The raster dataset with outliers replaced.
#' 
#' @example 
#' # Example usage of the function
#' library(terra)
#' r <- rast(nrows=10, ncols=10)
#' values(r) <- rnorm(ncell(r), mean=10, sd=5)
#' r <- replace_outliers(r, n_sd = 3)
#' plot(r)
replace_outliers <- function(raster, n_sd = 3) {
  # Step 1: Calculate mean and standard deviation of the raster values
  raster_stats <- global(raster, c("mean", "sd"), na.rm = TRUE)
  raster_mean <- raster_stats$mean
  raster_sd <- raster_stats$sd
  
  # Step 2: Define the normal range
  lower_bound <- raster_mean - n_sd * raster_sd
  upper_bound <- raster_mean + n_sd * raster_sd
  
  # Step 3: Extract raster values as a matrix
  raster_values <- values(raster)
  
  # Step 4: Identify outliers
  outliers <- raster_values < lower_bound | raster_values > upper_bound
  
  # Step 5: Replace outliers with the maximum of the normal range
  raster_values[outliers] <- upper_bound
  
  # Step 6: Assign the modified values back to the raster
  values(raster) <- raster_values
  
  return(raster)
}