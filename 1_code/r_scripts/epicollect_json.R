# Working with jsons ---------------

## Import Libraries -------
library(rjson)
library(tidyverse)
library(readr)

## Import single json file --------
file_location <- "0_data/test_ibutton_file_structure/epicollect/ibuttondeploymentcfs-v2-json/form-1__ibutton-deployment.json"
json_data <- rjson::fromJSON(file = file_location)

file_location <- "0_data/test_ibutton_file_structure/epicollect/ibuttondeploymentcfs-v2-json/branch-1__enter-1-branch-for-each-temperature-sensor-at-this-site.json"
json_data2 <- rjson::fromJSON(file = file_location)



## Multiple JSON files to CSV -----------

### site json -----------

#### List .json files in a directory ... ----
dir <- "0_data/test_ibutton_file_structure/epicollect/ibuttondeploymentcfs-v2-json/"
files <- list.files(dir, pattern = "*site.json", recursive = TRUE)
filepaths <- file.path(dir, files)

####  Initialize output data frame -----------
df_site <- data.frame()

#### Iterate over all JSON files -----------
for (filepath in filepaths) {
  # Import files
  json_data <- rjson::fromJSON(file = filepath)
  # Construct new row for output data frame
  new_row <- data.frame(
    ec5_branch_owner_uuid= as.character(sapply(json_data$data, function(x) x[["ec5_branch_owner_uuid"]])),
    ec5_branch_uuid= as.character(sapply(json_data$data, function(x) x[["ec5_branch_uuid"]])),
    title= sapply(json_data$data, function(x) x$title),
    sensorID= as.character(sapply(json_data$data, function(x) x[["14_Temperature_senso"]])),
    sensorID_2= as.character(sapply(json_data$data, function(x) x[["15_Temperature_senso"]])),
    shielding= sapply(json_data$data, function(x) x[["21_What_shielding_is"]]),
    temp_sens_ht= sapply(json_data$data, function(x) x[["17_At_what_height_is"]])
  )
  # Add new row to output data frame
  df_site <- rbind(df_site, new_row)
}

#### Clean dataframe ----
df_site_2<-df_site%>%
    mutate(sensorID = ifelse(sensorID == "list()", sensorID_2, sensorID)) %>%
    select(-sensorID_2)%>%
    mutate(sensorID_3 = str_extract(title, "\\S+"))%>%
    mutate(sensorID = ifelse(sensorID == "", sensorID_3, sensorID))%>%
    select(-sensorID_3, -title)

### deployment JSON ----
dir <- "0_data/test_ibutton_file_structure/epicollect/ibuttondeploymentcfs-v2-json/"
files <- list.files(dir, pattern = "*deployment.json", recursive = TRUE)
filepaths <- file.path(dir, files)

####  Initialise output data frame -----------
df_deployment <- data.frame()

#### Iterate over all JSON files -----------
for (filepath in filepaths) {
  # Import files
  json_data <- rjson::fromJSON(file = filepath)
  # Construct new row for output data frame
  new_row <- data.frame(
    ec5_uuid= sapply(json_data$data, function(x) x[["ec5_uuid"]]),
    # title= sapply(json_data$data, function(x) x[["title"]]),
    project= sapply(json_data$data, function(x) x[["2_Project_Name_dropd"]]),
    site_id= sapply(json_data$data, function(x) x[["3_Site_ID_optional_p"]]),
    deployment_or_retrieval= sapply(json_data$data, function(x) x[["10_Are_you_deploying"]]),
    date= sapply(json_data$data, function(x) x[["5_Date"]]),
    time= sapply(json_data$data, function(x) x[["6_Time"]]),
    longitude= sapply(json_data$data, function(x) x[["7_GPS_coordinates_Lo"]][["longitude"]]),
    latitude= sapply(json_data$data, function(x) x[["7_GPS_coordinates_Lo"]][["latitude"]]),
    accuracy= sapply(json_data$data, function(x) x[["7_GPS_coordinates_Lo"]][["accuracy"]])
  )
  # Add new row to output data frame
  df_deployment <- rbind(df_deployment, new_row)
}


### Join dataframes -----
deployment_retrievals<-left_join(df_deployment, df_site_2, by=c("ec5_uuid"= "ec5_branch_owner_uuid"))%>%
  group_by(ec5_uuid)%>%
  pivot_wider(names_from = deployment_or_retrieval, values_from = date)%>%
  rename(c(deployment_date=Deploying, retrieval_date=Retrieving, shield_type=shielding, project_id=project))%>%
  mutate(mission_id=paste(project_id, sensorID, sep="_"))%>%
  select("ec5_uuid", "project_id", "site_id", "sensorID", "mission_id", "deployment_date", "retrieval_date", "time", "longitude", "latitude", "accuracy", "ec5_branch_uuid", "shield_type", "temp_sens_ht")

write_csv(deployment_retrievals, file = paste("0_data/test_ibutton_file_structure/epicollect/cleaned_csv/epicollect_deployment_retrivals_", format(Sys.Date(), "%Y%m%d"), ".csv", sep = ""))


## Missing data ----

### Missing by mission_id ----

# deployment_retrievals <- read_csv("0_data/test_ibutton_file_structure/epicollect/cleaned_csv/epicollect_deployment_retrivals_20230806.csv")


missing_values_summary_1 <- deployment_retrievals %>%
  #replace empty strings with NA
  mutate_all(~na_if(., ''))%>%
  filter(!is.na(project_id)&!is.na(sensorID))%>%
  group_by(mission_id) %>%
  summarize(across(everything(), ~sum(is.na(.))))%>%
  select(-c("ec5_uuid", "project_id", "site_id", "sensorID"))
print(missing_values_summary_1)

# Create an empty dataframe to store the final result
missing_values_summary_2 <- data.frame()

# Loop through each row of the missing_values_summary dataframe
for (i in 1:nrow(missing_values_summary_1)) {
  mission_id <- missing_values_summary_1$mission_id[i]
  missing_columns <- names(missing_values_summary_1)[-1][missing_values_summary_1[i, -1] > 0]
  
  # Create a new row with mission_id and missing columns
  new_row <- data.frame(mission_id = mission_id, 
                        setNames(data.frame(t(missing_columns)), paste0("missing_", seq_along(missing_columns))))
  
  # Append the new row to the new_df
  missing_values_summary_2 <- bind_rows(missing_values_summary_2, new_row)
}

print(missing_values_summary_2)

### Missing projects ----

missing_projects <- deployment_retrievals %>%
  #replace empty strings with NA
  mutate_all(~na_if(., ''))%>%
  group_by(ec5_uuid) %>%
  summarize(across(everything(), ~sum(is.na(.))))%>%
  select(-c("site_id", "mission_id","deployment_date", "retrieval_date", "time", "longitude", "latitude", "accuracy", "ec5_branch_uuid", "shield_type", "temp_sens_ht"))%>%
  filter(project_id==1|sensorID==1)%>%
  rename(c(missing_project_id=project_id, missing_sensorID=sensorID))
print(missing_projects_1)


## Fix entry errors as needed ----

### Bring in 2022 deployment entries from Tharindu ----
library(readxl)
DeploymentFixed <- read_excel("0_data/external/remissingepicollectformsibuttons/DeploymentFixed.xlsx")
DeplymentFixed_1<-DeploymentFixed%>%
  select(ec5_uuid, contains("deploy"))

df<-deployment_retrievals%>%semi_join(DeplymentFixed_1)

Retrieval_Entries <- read_excel("0_data/external/remissingepicollectformsibuttons/Retrieval Entries_ibutton entries_Comments section_Retrieval form 2022_NEW.xlsx")


deployment_retrievals_1<-deployment_retrievals%>%
  select(ec5_uuid, contains("deploy"))

df1<-deployment_retrievals%>%semi_join(deployment_retrievals_1)

df2<-deployment_retrievals%>%inner_join(deployment_retrievals_1, join_by(ec5_uuid))


