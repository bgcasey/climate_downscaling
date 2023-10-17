# ---
# title: "Process raw data: BU"
# author: "Brendan Casey"
# created: "2023-09-15"
# description: "Process raw iButton csv's"
# ---


# Setup ----

## Load packages----
library(data.table)
library(tidyverse)
library(googlesheets4)
library(sf)

## Import data----

### Climate projects----
# enter projects to be processed separated by "|"
projects <- "BUCL2022|BUGhost2022|BUMTN2022|BUGen2022"

# Enter path to microclimate directory
CFS_microclimate<-"~/Library/CloudStorage/GoogleDrive-bgcasey@ualberta.ca/Shared drives/CFS_microclimate/"


### Project metadata----
epicollect_dpl_retr <- read_csv("~/Google Drive/Shared drives/CFS_microclimate/deployment_retrieval/CFSdeployment_retrieval/Epicollect deployment and retrieval 2022.csv")

# Get retrieval data ("Epicollect deployment and retrieval 2022")
# missions_update <- read_sheet("https://docs.google.com/spreadsheets/d/1k0tpoW2oyqA254Ld69-6nNeHiX_WjwS2vg5TMDDQWVY/edit#gid=266715229")
missions_update <- read_csv("~/Google Drive/Shared drives/CFS_microclimate/deployment_retrieval/CFSdeployment_retrieval/Missions update here.csv")


# Get retrieval data ("Epicollect deployment and retrieval 2023")
epi_2023<-read_csv("0_data/test_ibutton_file_structure/epicollect/cleaned_csv/epicollect_deployment_retrivals_20230902.csv")%>%
  select(ec5_uuid, mission_id, site_id, shield_type, temp_sens_ht, latitude, longitude, accuracy, retrieval_date, deployment_date)

# combine metadata we are interested in into a single dataframe
mission_meta<-missions_update%>%
  left_join(epicollect_dpl_retr)%>%
  select(ec5_uuid, mission_id, site_id, shield_type, temp_sens_ht, lat, long, accuracy, `retrieval_date_(dd/mm/yyyy)`, `deployment_date_(dd/mm/yyyy)`, comments)%>%
  rename(c(latitude=lat, longitude=long, retrieval_date=`retrieval_date_(dd/mm/yyyy)`, deployment_date=`deployment_date_(dd/mm/yyyy)`))%>%
  distinct()%>%
  left_join(epi_2023, join_by(mission_id))%>%
  #fill missing values
  mutate(
    ec5_uuid=(coalesce(ec5_uuid.x, ec5_uuid.y)),
    site_id=(coalesce(site_id.x, site_id.y)),
    shield_type=(coalesce(shield_type.x, shield_type.y)),
    temp_sens_ht=(coalesce(temp_sens_ht.x, temp_sens_ht.y)),
    latitude=(coalesce(latitude.x, latitude.y)),
    longitude=(coalesce(longitude.x, longitude.y)),
    accuracy=(coalesce(accuracy.x, accuracy.y)),
    retrieval_date=(coalesce(retrieval_date.x, retrieval_date.y)),
    deployment_date=(coalesce(deployment_date.x, deployment_date.y)))%>%
  dplyr::select(ec5_uuid, mission_id, site_id, shield_type, temp_sens_ht, latitude, longitude, accuracy, retrieval_date, deployment_date)

##////////////////////////////////////////////////////////////////

# List project directories----
# Create a list of folders named raw in directories that match the user specified projects

dirs <- intersect(
  grep("raw",list.dirs(path=paste0(CFS_microclimate, "Projects/"),recursive=TRUE),value=TRUE),
  grep(projects,list.dirs(path=paste0(CFS_microclimate, "Projects/"),recursive=TRUE),value=TRUE)
)

##////////////////////////////////////////////////////////////////

# Process raw csv files in each directory ----

for (dir in dirs) {
  
  # Get a list of files in the directory lists
  file_list <- list.files(dir, pattern='*\\.csv', ignore.case=TRUE, full.names = TRUE, recursive = TRUE)
  
  combined_data_1 <- data.frame()
  # Loop through each file
  for (i in 1:length(file_list)) {
    # Read the data file skipping the first 19 rows
    file_data <- fread(file_list[i],skip = "Date", sep = ",")
    ##extract the first 18 rows
    headers_data <- fread(file_list[i], nrows= 18, sep = ",", header = FALSE, fill = TRUE, blank.lines.skip = TRUE)
    headers_data <- headers_data[,1]
    ##add the file name to combined data
    file_data$serial_full <- substr(headers_data[2], 37,52)
    ##bring in each file name
    file_data$filename <- file_list[i]
    # Append the data to the combined data frame
    combined_data_1 <- bind_rows(combined_data_1, file_data)
  }
  
  combined_data_2 <- combined_data_1 %>%
    select(-c(Unit)) %>% 
    mutate(serial_number= str_sub(serial_full, 9, 14)) %>%
    #add project_id field based on the parent directory name
    mutate(project_id=basename(dirname(dir)))%>%
    # add mission id column
    mutate(mission_id=paste(project_id, serial_number, sep="_"))%>%
    mutate(date_time = dmy_hms(`Date/Time`)) %>% 
    select(-c(`Date/Time`)) %>% 
    mutate(month=month(date_time))%>%
    mutate(day=day(date_time))%>%
    mutate(year=year(date_time)) %>% 
    rename(temperature= Value)
  
  combined_data_3 <- combined_data_2 %>%
    left_join(mission_meta)
  
  # save as a csv within the correct project parent directory
  save_dir<-substr(dir, 1, nchar(dir) - 3)
  save_dir<- paste0(save_dir, "cleaned/") 
  
  df_name<-paste0(basename(dirname(dir)), "_cleaned")
  assign(df_name, combined_data_3, envir = .GlobalEnv)
  
  write_csv(combined_data_3, file=paste0(save_dir, combined_data_3$project_id[1], "_cleaned_", format(Sys.Date(), "%Y%m%d"), ".csv"))

  # Generate daily temperature summaries
  temp_daily<-combined_data_3%>%
    mutate(Value=temperature, Site_StationKey=mission_id)%>%
    mutate(Date=date(date_time))%>%
    mutate(deployment_date=strptime(deployment_date, format = "%d/%m/%Y"))%>%
    mutate(retrieval_date = strptime(retrieval_date, format = "%d/%m/%Y"))%>%
    dplyr::group_by(site_id, Site_StationKey,deployment_date,retrieval_date, Date) %>% #group by days, month and year
    dplyr::summarize(Tmax_Day=max(temperature),Tmin_Day=min(temperature),Tavg_Day=mean(temperature))%>%
    mutate(Year=year(Date))%>%
    mutate(Month=month(Date))%>%
    mutate(Day=day(Date))%>%
    dplyr::group_by(Site_StationKey,Date) 
  
  df_name<-paste0(basename(dirname(dir)), "_daily")
  assign(df_name, temp_daily, envir = .GlobalEnv)
  
  write_csv(temp_daily, file=paste0(save_dir, combined_data_3$project_id[1], "_daily_", format(Sys.Date(), "%Y%m%d"), ".csv"))
  
  temp_xy<-combined_data_3%>%
    select(project_id, mission_id, latitude, longitude, year)%>%
    group_by(project_id, mission_id, latitude, longitude)%>%
    dplyr::summarize(min_year=min(year), max_year=max(year))%>%
    dplyr::rename(c(Project=project_id, Site_StationKey=mission_id, Lat=latitude, Long=longitude))%>%
    dplyr::distinct()%>%
    na.omit()%>%
    st_as_sf(coords=c("Long","Lat"), crs=4326, remove=FALSE)
  
    df_name<-paste0(basename(dirname(dir)), "_xy")
    assign(df_name, temp_xy, envir = .GlobalEnv)
  
    st_write(temp_xy, paste0(save_dir, temp_xy$Project[1], "_xy_", format(Sys.Date(), "%Y%m%d"), ".shp"))
    saveRDS(temp_xy, file=paste0(save_dir, temp_xy$Project[1], "_xy_", format(Sys.Date(), "%Y%m%d"), ".rds"))
    
    
    
    }

##////////////////////////////////////////////////////////////////

# View missing deployment/retrieval info ----
missing<-rbind(BUCL2022_cleaned, BUGhost2022_cleaned, BUMTN2022_cleaned, BUGen2022_cleaned)%>%
  select(mission_id, latitude, longitude, accuracy, retrieval_date, deployment_date)%>%
  distinct()

save(missing, file="2_pipeline/tmp/missing_BU.rData")
write_csv(missing, file="2_pipeline/tmp/missing_BU_metadata.csv")




xy<-combined_data_3%>%
  select(project_id, mission_id, latitude, longitude, year)%>%
  group_by(project_id, mission_id, latitude, longitude)%>%
  dplyr::summarize(min_year=min(year), max_year=max(year))%>%
  dplyr::rename(c(Project=project_id, Site_StationKey=mission_id, Lat=latitude, Long=longitude))%>%
  dplyr::distinct()%>%
  na.omit()%>%
  st_as_sf(coords=c("Long","Lat"), crs=4326, remove=FALSE)

