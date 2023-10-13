
library(data.table)
library(tidyverse)
library(googlesheets4)


# The script should:
#   1. scan and read raw csvs
# 2. combine, clean and format raw csvs
# Get lat long and accuracy from the EpiCollect deployment and retrival form
# should have the following columbs:
#   [1] "serial_number" "serial_full"   "mission_id"    "lat"           "long"         
# [6] "accuracy"      "retr_date"     "Date_Time_dpl" "Temperature"   "Date_Time"    
# [11] "Month"         "Day"           "Year"    
# 3. create new folders for metadata and processed files
# 4. add data from the processed files to other tables defined in the protocols document



# ----------------------- Setup -----------------------------
# enter projects to be processed separated by "|"
# projects <- "BUCL2022|BUGhost2022|BUMTN2022"
projects <- "CFSYukon2022"

# projects <- "BUCL2022"

# Enter path to microclimate directory
CFS_microclimate<-"~/Library/CloudStorage/GoogleDrive-bgcasey@ualberta.ca/Shared drives/CFS_microclimate/"
# projects <- "BUGhost2022"



# ----------------Bring in project metadata------------------
# Get deployment and project meta data ("Missions update here")
gs4_deauth()
# epicollect_dpl_retr <- read_sheet("https://docs.google.com/spreadsheets/d/17XlD9aDWxbF-hT_lgHHTUPqp7LcqJtmg-D2WjVK31D4/edit#gid=707838738") %>%
#   distinct()%>%  
#   mutate(serial=as.character(serial))

epicollect_dpl_retr <- read_csv("~/Google Drive/Shared drives/CFS_microclimate/deployment_retrieval/CFSdeployment_retrieval/Epicollect deployment and retrieval 2022.csv")

# Get retrieval data ("Epicollect deployment and retrieval 2022")
# missions_update <- read_sheet("https://docs.google.com/spreadsheets/d/1k0tpoW2oyqA254Ld69-6nNeHiX_WjwS2vg5TMDDQWVY/edit#gid=266715229")
missions_update <- read_csv("~/Google Drive/Shared drives/CFS_microclimate/deployment_retrieval/CFSdeployment_retrieval/Missions update here.csv")



# Get retrieval data ("Epicollect deployment and retrieval 2023")
epi_2023<-read_csv("0_data/test_ibutton_file_structure/epicollect/cleaned_csv/epicollect_deployment_retrivals_20230902.csv")%>%
  select(ec5_uuid, mission_id, shield_type, temp_sens_ht, latitude, longitude, accuracy, retrieval_date, deployment_date)

# combine metadata we are interested in into a single dataframe
mission_meta<-missions_update%>%
  left_join(epicollect_dpl_retr)%>%
  select(ec5_uuid, mission_id, shield_type, temp_sens_ht, lat, long, accuracy, `retrieval_date_(dd/mm/yyyy)`, `deployment_date_(dd/mm/yyyy)`, comments)%>%
  rename(c(latitude=lat, longitude=long, retrieval_date=`retrieval_date_(dd/mm/yyyy)`, deployment_date=`deployment_date_(dd/mm/yyyy)`))%>%
  distinct()%>%
  left_join(epi_2023, join_by(mission_id))%>%
  #fill missing values
  mutate(
    ec5_uuid=(coalesce(ec5_uuid.x, ec5_uuid.y)),
    shield_type=(coalesce(shield_type.x, shield_type.y)),
    temp_sens_ht=(coalesce(temp_sens_ht.x, temp_sens_ht.y)),
    latitude=(coalesce(latitude.x, latitude.y)),
    longitude=(coalesce(latitude.x, latitude.y)),
    accuracy=(coalesce(accuracy.x, accuracy.y)),
    retrieval_date=(coalesce(retrieval_date.x, retrieval_date.y)),
    deployment_date=(coalesce(deployment_date.x, deployment_date.y)))%>%
  dplyr::select(ec5_uuid, mission_id, shield_type, temp_sens_ht, latitude, longitude, accuracy, retrieval_date, deployment_date)
  


# epi_2023_2<-epi_2023%>%
#   anti_join(missions_update, join_by(mission_id))
# 
# mission_meta<-mission_meta%>%
#   rbind(epi_2023_2)






# ### add missing Ghost mission IDs ----
# epi_2023_3<-read_csv("0_data/test_ibutton_file_structure/epicollect/cleaned_csv/epicollect_deployment_retrivals_20230902.csv")%>%
# select(mission_id, site_id, project_id, deployment_date, sensorID)%>%distinct()



# mission_meta_2 <- mission_meta %>%
#   left_join(epi_2023_3, by = join_by(mission_id,
#                                       deployment_date))%>%
#   mutate(mission_id_2= ifelse(grepl(site_id, "Ghst") & is.na(project_id) & substr(deployment_date, 1, 4) == "2022", "mission_id", mission_id))%>%
#   mutate(mission_id_3=ifelse(!is.na(mission_id_2), as.character(mission_id_2), mission_id))%>%
#   # select(-c(mission_id, mission_id_2, site_id, project_id, sensorID))%>%
#   select(-c(mission_id, mission_id_2))%>%
#   rename(mission_id=mission_id_3)
  
# ----------------Get a list of directories------------------
# Create a list of folders named raw in directories that match the user specified projects
dirs <- intersect(
  grep("raw",list.dirs(path=paste0(CFS_microclimate, "Projects/"),recursive=TRUE),value=TRUE),
  grep(projects,list.dirs(path=paste0(CFS_microclimate, "Projects/"),recursive=TRUE),value=TRUE)
)

## --------- Process raw csv files in each directory ---------

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
}


# View missing deployment/retrieval info ----
BUMTN2022_cleaned <- read_csv("0_data/test_ibutton_file_structure/Projects/BUMTN2022/cleaned/BUMTN2022_cleaned_20230821.csv")
BUGhost2022_cleaned <- read_csv("0_data/test_ibutton_file_structure/Projects/BUGhost2022/cleaned/BUGhost2022_cleaned_20230821.csv")
BUCL2022_cleaned <- read_csv("0_data/test_ibutton_file_structure/Projects/BUCL2022/cleaned/BUCL2022_cleaned_20230821.csv")

missing<-rbind(BUCL2022_cleaned, BUGhost2022_cleaned, BUMTN2022_cleaned)%>%
  select(mission_id, latitude, longitude, accuracy, retrieval_date, deployment_date)%>%
  distinct()

save(missing, file="2_pipeline/tmp/missing.rData")
write_csv(missing, file="2_pipeline/tmp/missing_metadata.csv")

test<-left_join(missing, deployment_retrievals, join_by(mission_id))


# combined_data_3a <- combined_data_2 %>%
#   left_join(epicollect_dpl_retr, by = join_by(serial_full, project_id, mission_id))%>%
#   # mutate(serial=as.character(serial))%>%  
#   left_join(missions_update, by = join_by(mission_id, serial_full, serial, project_id))%>%
#   rename(c(deployment_date=`deployment_date_(dd/mm/yyyy)`, retrieval_date=`retrieval_date_(dd/mm/yyyy)`))%>%
#   dplyr::select(c(project_id, mission_id, serial, lat, long, accuracy, temp_sens_ht, shield_type, deployment_date, retrieval_date, date_time, month, day, year, temperature))%>%
#   left_join(epi_2023, by="mission_id")
# 
# 
# xy<-combined_data_3a%>%filter(is.na(lat))
# 
# 
# #See what we have location info for
# proj_loc<-epicollect_dpl_retr%>%filter(!is.na(lat))%>%
#   select(mission_id, lat, long)%>%
#   distinct()%>%
#   filter(grepl("^BUCL2022", mission_id)|grepl("^BUGhost2022", mission_id)|grepl("^BUMTN2022", mission_id))%>%
#   arrange(mission_id)
# 
# proj_loc_BUGHOST<-BUGhost2022_cleaned%>%
#   # filter(!is.na(latitude))%>%
#   select(mission_id, latitude, longitude)%>%
#   distinct()%>%
#   filter(grepl("^BUCL2022", mission_id)|grepl("^BUGhost2022", mission_id)|grepl("^BUMTN2022", mission_id))%>%
#   arrange(mission_id)
# 
# proj_loc_BUGMTN<-BUMTN2022_cleaned%>%
#   # filter(!is.na(latitude))%>%
#   select(mission_id, latitude, longitude)%>%
#   distinct()%>%
#   filter(grepl("^BUCL2022", mission_id)|grepl("^BUGhost2022", mission_id)|grepl("^BUMTN2022", mission_id))%>%
#   arrange(mission_id)
# 
# proj_loc_BUCL<-BUCL2022_cleaned%>%
#   # filter(!is.na(latitude))%>%
#   select(mission_id, latitude, longitude)%>%
#   distinct()%>%
#   filter(grepl("^BUCL2022", mission_id)|grepl("^BUGhost2022", mission_id)|grepl("^BUMTN2022", mission_id))%>%
#   arrange(mission_id)
