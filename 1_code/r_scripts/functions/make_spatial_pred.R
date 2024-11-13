#' Generate Spatial Predictions from Models
#'
#' This function generates spatial predictions from a list of models
#' and a prediction grid. It calculates and returns the mean and
#' standard deviation of the predictions across all models.
#'
#' @param models_list list. A list of models to make predictions from.
#' @param prediction_grid SpatRaster. A SpatRaster object with
#' covariates matching those used in the models.
#' @param n_cores integer. The number of cores to use for parallel
#' processing.
#' @param output_dir character. The directory to save the prediction
#' rasters. Default is "output".
#' @return list. A list containing two SpatRaster objects:
#' \item{mean_raster}{The mean of the predictions across all models.}
#' \item{sd_raster}{The standard deviation of the predictions across
#' all models.}
#'
#' @example
#' # Example usage of the function
#' models_list <- list(model1, model2, model3) # Replace with actual
#' models
#' prediction_grid <- rast("path_to_prediction_grid.tif") # Replace
#' with actual SpatRaster
#' result <- make_spatial_pred(models_list, prediction_grid,
#' n_cores = 4)
#' print(result$mean_raster)
#' print(result$sd_raster)
make_spatial_pred <- function(models_list, prediction_grid, n_cores,
                              output_dir = "output") {
  # Step 1: Create output directory if it doesn't exist
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }

  # Step 2: Define the function to run a single prediction
  run_prediction <- function(i) {
    tryCatch(
      {
        model <- models_list[[i]]

        # Generate predictions
        prediction <- predict(prediction_grid, model,
          type = "response",
          n.trees = model$gbm.call$best.trees,
          na.rm = FALSE
        )

        # Define file path
        file_path <- file.path(
          output_dir,
          paste("/raw/prediction", i, ".tif",
            sep = ""
          )
        )

        # Save prediction raster to TIFF file
        writeRaster(prediction, file_path, overwrite = TRUE)

        # Print completion message
        print(paste("Completed and saved raster", i))
        
        # Remove prediction 
        rm(prediction)
        
        # Trigger garbage collection
        gc()

        return(TRUE)
      },
      error = function(e) {
        # Log the error message
        message(paste("Error in model", i, ":", e$message))
        return(FALSE)
      }
    )
  }

  # Step 3: Process all models in parallel
  results <- mclapply(seq_along(models_list), run_prediction,
    mc.cores = n_cores
  )

  # Step 4: Check for any errors in the results
  if (any(!unlist(results))) {
    message("Some models encountered errors.")
  }

  # Step 5: Calculate mean and standard deviation of the predictions
  prediction_files <- list.files(paste0(output_dir, "/raw"),
    pattern = "prediction.*\\.tif$",
    full.names = TRUE
  )
  prediction_stack <- rast(prediction_files)
  mean_raster <- mean(prediction_stack, na.rm = TRUE)
  sd_raster <- stdev(prediction_stack, na.rm = TRUE)
  return(list(mean_raster = mean_raster, sd_raster = sd_raster))
}
