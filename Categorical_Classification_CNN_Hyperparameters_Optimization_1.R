# ------------------------------------------------------------------------------
# CNN CATEGORICAL MODEL IMPLEMENTATION - HYPERPARAMETERS OPTIMIZATION (1)
# ------------------------------------------------------------------------------
# Data
# https://www.kaggle.com/c/cifar-10/overview
# browseURL(url = "https://www.kaggle.com/c/cifar-10/overview")

# ------------------------------------------------------------------------------
# Model:
model_name <- "CNN_Hyperparameters_Optimization"
model_type <- "Categorical"

# ------------------------------------------------------------------------------
# Intro:
# 1. Set currect working directory:
setwd("D:/GitHub/DeepNeuralNetworksImageClassificationR")
# 2. Create 'model_name' folder in cwd:
if (dir.exists(paste(getwd(), model_name, sep = "/")) == FALSE){dir.create(path = paste(getwd(), model_name, sep = "/"))}
# 3. Create 'model_type' subfolder in 'model_name' main folder:
if (dir.exists(paste(getwd(), model_name, model_type, sep = "/")) == FALSE){dir.create(path = paste(getwd(), model_name, model_type, sep = "/"))}

# ------------------------------------------------------------------------------
# Environment:
reticulate::use_condaenv("GPU_ML_2", required = TRUE)
library(tensorflow)
library(keras)
library(tidyverse)
library(deepviz)
source("D:/GitHub/DeepNeuralNetworksImageClassificationR/Useful_Functions.R")

# Directories:
train_dir <- "D:/GitHub/Datasets/Cifar10/train"
validation_dir <- "D:/GitHub/Datasets/Cifar10/validation"
test_dir <- "D:/GitHub/Datasets/Cifar10/test"
models_store_dir <- paste(getwd(), model_name, model_type, sep = "/")
models_repo_store_dir <- "D:/GitHub/DeepNeuralNetworksRepoR_Models_Store"

train_files <- Count_Files(path = train_dir); train_files
validation_files <- Count_Files(path = validation_dir); validation_files
test_files <- Count_Files(path = test_dir); test_files

# ------------------------------------------------------------------------------
# Clear session:
keras::k_clear_session()

# ------------------------------------------------------------------------------
# Optimize model's hyperparameters:
Hyperparametrization_Optimization_Results <- Hyperparametrization_Optimization(hyperparameters_list = list(filters_1 = c(64),
                                                                                                                 filters_2 = c(64, 128),
                                                                                                                 filters_3 = c(128, 256),
                                                                                                                 filters_4 = c(128, 256),
                                                                                                                 dense_units_1 = c(256),
                                                                                                                 dense_units_2 = c(256)),
                                                                               script_directory = "Categorical_Classification_CNN_Hyperparameters_Optimization_2.R")

Hyperparametrization_Optimization_Results %>%
  dplyr::arrange(dplyr::desc(val_acc)) %>%
  dplyr::slice(1) %>%
  dplyr::glimpse() 

Hyperparametrization_Optimization_Results %>%
  dplyr::arrange(dplyr::desc(val_acc)) %>%
  dplyr::slice(1) %>%
  dplyr::select(Id) %>%
  dplyr::pull() %>%
  paste("logs", ., sep = "_") -> key; key

# ------------------------------------------------------------------------------
# Remove not optimal models:
setwd(models_store_dir)
saved_models <- sort(list.files(pattern = ".hdf5"))
saved_models <- saved_models[!grepl(key, saved_models)]
if (length(saved_models) > 1){
  for (j in 1:(length(saved_models))){
    cat("Remove .hdf5 file:", saved_models[j], "\n")
    unlink(saved_models[j], recursive = TRUE, force = TRUE)}}

# ------------------------------------------------------------------------------
# Remove not optimal models; logger callbacks:
saved_loggers <- sort(list.files(pattern = ".csv"))
saved_loggers <- saved_loggers[!grepl(paste(key, model_name, sep = "_"), saved_loggers)]
if (length(saved_loggers) > 1){
  for (j in 1:(length(saved_loggers))){
    cat("Remove .csv file:", saved_loggers[j], "\n")
    unlink(saved_loggers[j], recursive = TRUE, force = TRUE)}}

# ------------------------------------------------------------------------------
# Remove logs folders:
logs_folder <- paste(getwd(), list.dirs(), sep = "/")
if (length(logs_folder) > 1){
  for (j in 2:(length(logs_folder))){
    cat("Remove folder:", logs_folder[j], "\n")
    unlink(logs_folder[j], recursive = TRUE, force = TRUE)}}

# ------------------------------------------------------------------------------
# Save optimal model in local models repository: 
optimal_model <- paste(getwd(), list.files(pattern = ".hdf5"), sep = "/")
optimal_model_repo_dir <- paste(models_repo_store_dir, paste(model_type, model_name, "Model.hdf5", sep = "_"), sep = "/")
file.copy(from = optimal_model,
                to = optimal_model_repo_dir, 
                overwrite = TRUE); cat("Optimal model directory:", optimal_model_repo_dir, "\n")
unlink(optimal_model, recursive = TRUE, force = TRUE)

# ------------------------------------------------------------------------------
# Clear session and import the best trained model:
keras::k_clear_session()
optimal_model_repo_dir <- paste(models_repo_store_dir, paste(model_type, model_name, "Model.hdf5", sep = "_"), sep = "/")
model <- keras::load_model_hdf5(filepath = optimal_model_repo_dir, compile = TRUE)

# ------------------------------------------------------------------------------
# Visualize model:
model %>% deepviz::plot_model()
model %>% summary()

# ------------------------------------------------------------------------------
# Model evaluation and predictions using generators:
train_datagen <- keras::image_data_generator(rescale = 1/255)
train_generator <- keras::flow_images_from_directory(directory = train_dir,
                                                     generator = train_datagen, 
                                                     target_size = c(image_size, image_size),
                                                     batch_size = batch_size,
                                                     class_mode = class_mode,
                                                     classes = levels(validation_files$category),
                                                     shuffle = FALSE)

validation_datagen <- keras::image_data_generator(rescale = 1/255)
validation_generator <- keras::flow_images_from_directory(directory = validation_dir,
                                                          generator = validation_datagen,
                                                          target_size = c(image_size, image_size),
                                                          batch_size = batch_size,
                                                          class_mode = class_mode,
                                                          classes = levels(validation_files$category),
                                                          shuffle = FALSE)

test_datagen <- keras::image_data_generator(rescale = 1/255)
test_generator <- keras::flow_images_from_directory(directory = test_dir,
                                                    generator = test_datagen,
                                                    target_size = c(image_size, image_size),
                                                    batch_size = batch_size,
                                                    class_mode = class_mode,
                                                    shuffle = FALSE)

train_evaluation <- keras::evaluate_generator(model, train_generator, steps = ceiling(train_generator$n/train_generator$batch_size)); train_evaluation
validation_evaluation <- keras::evaluate_generator(model, validation_generator, steps = ceiling(validation_generator$n/validation_generator$batch_size)); validation_evaluation
test_evaluation <- keras::evaluate_generator(model, test_generator, steps = ceiling(test_generator$n/test_generator$batch_size)); test_evaluation 

train_probabilities <- keras::predict_generator(model, train_generator, steps = ceiling(train_generator$n/train_generator$batch_size), verbose = 1)
validation_probabilities <- keras::predict_generator(model, validation_generator, steps = ceiling(validation_generator$n/validation_generator$batch_size), verbose = 1)
test_probabilities <- keras::predict_generator(model, test_generator, steps = ceiling(test_generator$n/test_generator$batch_size), verbose = 1)

setwd(models_store_dir)
readr::write_csv2(tibble::as_tibble(train_probabilities) %>%
                    dplyr::mutate(filepath = train_generator$filepaths,
                                  actual_class = train_generator$classes + 1,
                                  model = model_name),
                  paste(stringr::str_replace_all(Sys.time(), ":", "-"), model_name, "train_categorical_probabilities.csv", sep = "_"))
readr::write_csv2(tibble::as_tibble(validation_probabilities) %>%
                    dplyr::mutate(filepath = validation_generator$filepaths,
                                  actual_class = validation_generator$classes + 1,
                                  model = model_name),
                  paste(stringr::str_replace_all(Sys.time(), ":", "-"), model_name, "validation_categorical_probabilities.csv", sep = "_"))
readr::write_csv2(tibble::as_tibble(test_probabilities) %>%
                    dplyr::mutate(filepath = test_generator$filepaths,
                                  actual_class = test_generator$classes + 1,
                                  model = model_name), 
                  paste(stringr::str_replace_all(Sys.time(), ":", "-"), model_name, "test_categorical_probabilities.csv", sep = "_"))

# ------------------------------------------------------------------------------
# Model verification:
labels <- sort(as.character(train_files$category)); labels
save_option <- TRUE

Categorical_train_results <- Categorical_Classifier_Verification(actual = train_generator$classes + 1,
                                                                 probabilities = train_probabilities,
                                                                 labels = labels,
                                                                 type_info = paste(model_name, "train", sep = "_"),
                                                                 save = save_option,
                                                                 open = FALSE)

Categorical_validation_results <- Categorical_Classifier_Verification(actual = validation_generator$classes + 1,
                                                                      probabilities = validation_probabilities,
                                                                      labels = labels,
                                                                      type_info = paste(model_name, "validation", sep = "_"),
                                                                      save = save_option,
                                                                      open = FALSE)

Categorical_test_results <- Categorical_Classifier_Verification(actual = test_generator$classes + 1,
                                                                probabilities = test_probabilities,
                                                                labels = labels,
                                                                type_info = paste(model_name, "test", sep = "_"),
                                                                save = save_option,
                                                                open = FALSE)

# ------------------------------------------------------------------------------
# Predict indicated image:
labels <- sort(as.character(train_files$category)); labels
set <- "train"
category <- "automobile"  
id <- 1

Predict_Image(image_path = paste("D:/GitHub/Datasets/Cifar10", set, category, list.files(paste("D:/GitHub/Datasets/Cifar10", set, category, sep = "/")), sep = "/")[id],
              model = model,
              classes = labels,
              plot_image = TRUE)

# ------------------------------------------------------------------------------
# Save true and false predictions:
save_summary_files <- TRUE
save_correct_images <- FALSE
save_incorrect_images <- FALSE

# Train:
Train_Correct_Incorrect_Categorical_Classifications <- Organize_Correct_Incorrect_Categorical_Classifications(dataset_dir = train_dir,
                                                                                                              actual_classes = train_generator$classes + 1,
                                                                                                              predicted = train_probabilities,
                                                                                                              type_info = model_name,
                                                                                                              cwd = models_store_dir,
                                                                                                              save_summary_files = save_summary_files,
                                                                                                              save_correct_images = save_correct_images,
                                                                                                              save_incorrect_images = save_incorrect_images)

# Validation:
Validation_Correct_Incorrect_Categorical_Classifications <- Organize_Correct_Incorrect_Categorical_Classifications(dataset_dir = validation_dir,
                                                                                                                   actual_classes = validation_generator$classes + 1,
                                                                                                                   predicted = validation_probabilities,
                                                                                                                   type_info = model_name,
                                                                                                                   cwd = models_store_dir,
                                                                                                                   save_summary_files = save_summary_files,
                                                                                                                   save_correct_images = save_correct_images,
                                                                                                                   save_incorrect_images = save_incorrect_images)

# Test:
Test_Correct_Incorrect_Categorical_Classifications <- Organize_Correct_Incorrect_Categorical_Classifications(dataset_dir = test_dir,
                                                                                                             actual_classes = test_generator$classes + 1,
                                                                                                             predicted = test_probabilities,
                                                                                                             type_info = model_name,
                                                                                                             cwd = models_store_dir,
                                                                                                             save_summary_files = save_summary_files,
                                                                                                             save_correct_images = save_correct_images,
                                                                                                             save_incorrect_images = save_incorrect_images)

# ------------------------------------------------------------------------------
# Visualize predictions distribution:
save_plot <- TRUE
labels <- sort(as.character(train_files$category)); labels

train_predicted_2 <- train_probabilities[matrix(data = c(1:nrow(train_probabilities), train_generator$classes + 1), byrow = FALSE, ncol = 2)]
Display_Target_Class_Predictions_Distribution(actual = train_generator$classes,
                                              predicted = train_predicted_2,
                                              labels = labels,
                                              bins = 10,
                                              type_info = paste(model_name, "train", sep = "_"),
                                              save_plot = save_plot)

validation_predicted_2 <- validation_probabilities[matrix(data = c(1:nrow(validation_probabilities), validation_generator$classes + 1), byrow = FALSE, ncol = 2)]
Display_Target_Class_Predictions_Distribution(actual = validation_generator$classes,
                                              predicted = validation_predicted_2,
                                              labels = labels,
                                              bins = 10,
                                              type_info = paste(model_name, "validation", sep = "_"),
                                              save_plot = save_plot)

test_predicted_2 <- test_probabilities[matrix(data = c(1:nrow(test_probabilities), test_generator$classes + 1), byrow = FALSE, ncol = 2)]
Display_Target_Class_Predictions_Distribution(actual = test_generator$classes,
                                              predicted = test_predicted_2,
                                              labels = labels,
                                              bins = 10,
                                              type_info = paste(model_name, "test", sep = "_"),
                                              save_plot = save_plot)

# ------------------------------------------------------------------------------
# Plot predictions distribution in division to all classes:
save_plot <- TRUE

Display_All_Classes_Predictions_Distribution(actual = train_generator$classes + 1,
                                             predicted = train_probabilities,
                                             labels = labels,
                                             bins = 4,
                                             type_info = paste(model_name, "train", sep = "_"),
                                             save_plot = save_plot,
                                             plot_size = 30)

Display_All_Classes_Predictions_Distribution(actual = validation_generator$classes + 1,
                                             predicted = validation_probabilities,
                                             labels = labels,
                                             bins = 4,
                                             type_info = paste(model_name, "validation", sep = "_"),
                                             save_plot = save_plot,
                                             plot_size = 30)

Display_All_Classes_Predictions_Distribution(actual = test_generator$classes + 1,
                                             predicted = test_probabilities,
                                             labels = labels,
                                             bins = 4,
                                             type_info = paste(model_name, "test", sep = "_"),
                                             save_plot = save_plot,
                                             plot_size = 30)

# ------------------------------------------------------------------------------
# https://github.com/ForesightAdamNowacki