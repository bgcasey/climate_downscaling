#' Calculate Statistics from a BRT Model
#'
#' This function calculates various statistics from a boosted 
#' regression tree (BRT) model, including cross-validation (CV) 
#' statistics and variable importance.
#'
#' @param model gbm object. The BRT model from which to calculate 
#' statistics.
#' @return data.frame. A dataframe containing the CV statistics and 
#' variable importance for the model.
#' 
#' @example 
#' # Example usage of the function
#' library(gbm)
#' library(dplyr)
#' library(tidyr)
#' 
#' # Example data
#' random_data <- data.frame(
#'   PIWO_occ = sample(0:1, 100, replace = TRUE),
#'   var1 = rnorm(100),
#'   var2 = rnorm(100)
#' )
#' 
#' # Example tuned parameters
#' tuned_param <- data.frame(
#'   interaction.depth = 3,
#'   n.minobsinnode = 20,
#'   shrinkage = 0.01,
#'   bag.fraction = 0.75
#' )
#' 
#' # Fit a model
#' model <- gbm.step(
#'   data = random_data,
#'   gbm.x = 2:ncol(random_data),
#'   gbm.y = 1,
#'   family = "bernoulli",
#'   tree.complexity = tuned_param$interaction.depth[1],
#'   n.minobsinnode = tuned_param$n.minobsinnode[1],
#'   learning.rate = tuned_param$shrinkage[1],
#'   bag.fraction = tuned_param$bag.fraction[1],
#'   silent = FALSE,
#'   plot.main = FALSE
#' )
#' 
#' # Calculate statistics
#' stats <- calculate_brt_stats(model)
#' 
#' # Print the results
#' print(stats)
calculate_brt_stats <- function(model) {
  # Step 1: Automatically get the name of the model variable
  model_name <- deparse(substitute(model))
  
  # Step 2: Calculate CV stats
  cvstats <- as.data.frame(model$cv.statistics[c(1, 3, 5)])
  cvstats$deviance.null <- model$self.statistics$mean.null
  cvstats$deviance.explained <- 
    (cvstats$deviance.null - cvstats$deviance.mean) / 
    cvstats$deviance.null
  cvstats$model <- rep(model_name, nrow(cvstats))
  cvstats$discrimination.mean <- model$cv.statistics$discrimination.mean
  
  # Step 3: Calculate variable importance
  varimp <- as.data.frame(model$contributions) %>%
    pivot_wider(names_from = var, values_from = rel.inf)
  
  # Step 4: Combine cvstats and varimp into a single data frame
  combined_df <- bind_cols(cvstats, varimp)
  
  # Step 5: Move "model" to the first column
  combined_df <- combined_df[c("model", 
                               setdiff(names(combined_df), 
                                       "model"))]
  
  return(combined_df)
}