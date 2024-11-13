# ---
# title: "Boosted regression trees"
# author: "Brendan Casey"
# created: "September 8, 2023"
# description: >
#   This script performs a series of operations to fit
#   boosted regression tree models to Pileated Woodpecker
#   data. It includes model fitting with tuned parameters,
#   simplification of the initial model by dropping
#   non-informative variables, and a bootstrap procedure
#   to assess model stability. Custom functions are
#   utilized for calculating model statistics. The script
#   saves output files containing the bootstrapped models,
#   and a dataframe with model statistics.
# ---

# 1. Setup ----
## 1.1. Load Packages ----
library(tidyverse)  # For data manipulation
library(dismo)      # For species distribution modeling and BRTs
library(gbm)        # For boosted regression trees
library(pROC)       # For AUC calculation
library(Metrics)   # Model evaluation metrics

## 1.2. Load custom functions ----
# including function for getting BRT model stats.
source("1_code/r_scripts/utils.R") 

## 1.3. Load data ----
load("0_data/manual/formatted_for_models/data_full.rData")

data<-data_full%>%
  mutate(season_2=as.factor(season_2)) %>%
  mutate(season_4=as.factor(season_4)) %>%
  dplyr::select(Tmax_diff, Tmin_diff, Tavg_diff, CHILI, HLI, 
                TWI, elevation, tpi_50, tpi_100, tpi_300, 
                tpi_500, tpi_1000, eastness, northness, slope, cti, 
                `elev-stdev`, vrm, roughness, tri, tpi, Lat, 
                season_4) %>%
  dplyr::rename(elev_stdev=`elev-stdev`)%>%
  dplyr::select(-c(Tavg_diff, Tmin_diff))

## 1.4. Load tuned parameters ----
# load("2_pipeline/store/tuned_param.rData")

## 1.5. Randomize data ----
set.seed(123)

random_index <- sample(1:nrow(data), nrow(data))
random_data <- data[random_index, ]


# 2. Tune model parameters ----
set.seed(123) # Ensure reproducibility

## 2.1 Create hyperparameter grid ----
hyper_grid <- expand.grid(
  shrinkage = c(.001, .01, .1),
  interaction.depth = c(2, 3),
  n.minobsinnode = c(10, 15, 20, 30),
  bag.fraction = c(.5, .75, .85), 
  optimal_trees = 0,  # Placeholder for results
  min_RMSE = 0        # Placeholder for results
)

# Check total number of combinations
nrow(hyper_grid)

## 2.3 Model tuning based on the hyperparameter grid ----
for(i in 1:nrow(hyper_grid)) {
  
  # Ensure reproducibility
  set.seed(123)
  
  # Train model
  gbm.tune <- gbm(
    formula = Tmax_diff ~ .,
    distribution = "gaussian",
    data = random_data,
    n.trees = 5000,
    interaction.depth = hyper_grid$interaction.depth[i],
    shrinkage = hyper_grid$shrinkage[i],
    n.minobsinnode = hyper_grid$n.minobsinnode[i],
    bag.fraction = hyper_grid$bag.fraction[i],
    train.fraction = .75,
    n.cores = NULL, # Use all cores by default
    verbose = FALSE
  )
  
  # Update hyper_grid with model performance metrics
  hyper_grid$optimal_trees[i] <- which.min(gbm.tune$valid.error)
  hyper_grid$min_RMSE[i] <- sqrt(min(gbm.tune$valid.error))
}

## 3. Save tuned parameters ----
# Arrange by minimum RMSE and save
tuned_param_max <- hyper_grid %>%
  dplyr::arrange(min_RMSE) 
save(tuned_param_max, file="2_pipeline/store/tuned_param_max.rData")




# 2. Boosted Regression Tree ----

## 2.1. Apply `dismo::gbm.step` to tuned parameters ----
max_brt_1 <- gbm.step(data = random_data, 
                  gbm.x = 2:ncol(random_data), 
                  gbm.y = 1, 
                  family = "gaussian", 
                  tree.complexity = 3,  
                  n.minobsinnode = 15,
                  learning.rate = 0.1, 
                  bag.fraction = 0.85, 
                  silent = FALSE)
save(max_brt_1, file = "3_output/models/terrain/max_brt_1.rData")

## 2.2. Get model stats ----
max_brt_1_stats <- calculate_brt_stats(model = max_brt_1)
save(max_brt_1_stats, file = "3_output/model_results/max_brt_1_stats.rData")

# 3. Simplified Boosted Regression Tree ----
## 3.1. Drop variables that don't improve model performance ----


max_brt_1_simp <- gbm.simplify(max_brt_1)
save(max_brt_1_simp, file = "2_pipeline/store/models/max_brt_1_simp.rData")

## 3.2. Remove non-numeric characters from the row names ----
rownames(max_brt_1_simp$deviance.summary) <- 
  gsub("[^0-9]", "", rownames(max_brt_1_simp$deviance.summary))

## 3.3. Get the optimal number of drops ----
optimal_no_drops <- as.numeric(rownames(
  max_brt_1_simp$deviance.summary %>% slice_min(mean)))

## 3.4. Remove dropped variables from the dataframe ----
random_data <- random_data %>%
  dplyr::select(Tmax_diff, max_brt_1_simp$pred.list[[optimal_no_drops]])

## 3.5 BRT Second Iteration ----
max_brt_2 <- gbm.step(data = random_data, 
                  gbm.x = 2:ncol(random_data), 
                  gbm.y = 1, 
                  family = "gaussian", 
                  tree.complexity = 3,  
                  n.minobsinnode = 15,
                  learning.rate = 0.1, 
                  bag.fraction = 0.85, 
                  silent = FALSE)

save(max_brt_2, file = "2_pipeline/store/models/max_brt_2.rData")

## 3.6 Get model stats ----
summary(max_brt_2)
max_brt_2_stats <- calculate_brt_stats(model = max_brt_2)
save(max_brt_2_stats, file = "3_output/model_results/max_brt_2_stats.rData")





# 4. Bootstrap model ----
# Perform bootstrap iterations through the simplified 
# model. It is computationally intensive and may take a long time to 
# run. Adjust the number of iterations based on computational 
# resources and needs.

## 4.1. Define the bootstrap function ----
# Function to perform bootstrap iterations for a boosted regression 
# tree. It returns an object containing a dataframe of model 
# statistics and a list of the models.
#
# Parameters:
#   data: The data to be used for bootstrapping.
#   n_iterations: The number of bootstrap iterations to perform.
#
# Returns:
#   A list containing:
#     - models: A list of the bootstrapped models.
#     - stats_df: A dataframe with statistics for each model.

bootstrap_brt <- function(data, n_iterations) {
  # Initialize an empty dataframe for stats
  all_stats_df <- data.frame(model = character(), 
                             deviance.mean = numeric(),
                             correlation.mean = numeric(), 
                             discrimination.mean = numeric(),
                             deviance.null = numeric(),
                             deviance.explained = numeric(), 
                             # predict_AUC = numeric(), 
                             stringsAsFactors = FALSE)
  covariate_columns <- as.data.frame(replicate(ncol(random_data)-1, 
                                               numeric(), 
                                               simplify = FALSE))
  names(covariate_columns) <- paste0("cov_", 
                                     1:ncol(covariate_columns))
  
  # Initialize a list to store models
  models_list <- list()
  
  for (i in 1:n_iterations) {
    # Sampling with replacement for bootstrap
    samp <- sample(nrow(data), round(0.75 * nrow(data)), 
                   replace = TRUE)
    train_data <- data[samp, ]
    test_data <- data[-samp, ]
    
    # Fit the model
    model <- gbm.step(data = train_data, 
                      gbm.x = 2:ncol(train_data), 
                      gbm.y = 1, 
                      family = "gaussian", 
                      tree.complexity = 3,  
                      n.minobsinnode = 15,
                      learning.rate = 0.1, 
                      bag.fraction = 0.85, 
                      silent = FALSE,
                      plot.main = FALSE)
    
    # Predict on test data
    test_predictions <- predict(model, newdata = test_data[, -1], 
                                n.trees = model$gbm.call$best.trees, 
                                type = "response")
  
    
    # Calculate evaluation metrics for test data
    test_mse <- mse(test_data[, 1], test_predictions)
    test_mae <- mae(test_data[, 1], test_predictions)
    test_r2 <- cor(test_data[, 1], test_predictions)^2
    
    
    # Calculate stats for the trained model
    model_stats <- calculate_brt_stats(model = model)
    
    # Add model name and AUC to model_stats
    model_name <- paste("model", i, sep = "_")
    model_stats$model <- model_name
    model_stats$test_mae <- test_mae
    model_stats$test_mse <- test_mse
    model_stats$test_r2 <- test_r2

    # Append to the accumulating dataframe
    all_stats_df <- rbind(all_stats_df, model_stats)
    
    # Store the model in the list
    models_list[[model_name]] <- model
  }
  
  return(list(models = models_list, stats_df = all_stats_df))
}

# Example usage:
# bootstrap_models <- bootstrap_brt(data, n_iterations)

## 4.2. Run the bootstraps ----
# Set the number of iterations
n_iterations <- 100    

# run the bootstrap function
bootstrap_models <- bootstrap_brt(random_data, n_iterations)

## 4.3. Save models ----
save(bootstrap_models_max, 
     file = "3_output/model_results/bootstrap_models_max.rData")
