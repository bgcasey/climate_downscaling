# ---
# title: "ibutton_to_soiltemp"
# author: "Brendan Casey"
# created: "2023-10-13"
# description: "Put ibutton data into Soiltemp format"
# ---

#Setup ----

##Load packages----
library(tidyverse)
library(readxl)

##Import data----

### Soiltemp data----
soiltemp_metadata<- read_excel("~/Google_Drive/Shared drives/CFS_microclimate/SoilTemp/SoilTemp2.0_data-submission_template_long_unique_sensor.xlsx", sheet="Metadata")
soiltemp_metadata <- soiltemp_metadata[-c(1:9), ]
soiltemp_metadata <- soiltemp_metadata%>%
  mutate(Latitude=as.numeric(Latitude))%>%
  mutate(Longitude=as.numeric(Longitude))%>%
  mutate(EPSG=as.numeric(EPSG))%>%
  mutate(GPS_accuracy=as.numeric(GPS_accuracy))%>%
  mutate(Start_date_year=as.numeric(Start_date_year))%>%
  mutate(End_date_year=as.numeric(End_date_year))%>%
  mutate(Temporal_resolution=as.numeric(Temporal_resolution))


soiltemp_raw<- read_excel("~/Google_Drive/Shared drives/CFS_microclimate/SoilTemp/SoilTemp2.0_data-submission_template_long_unique_sensor.xlsx", sheet="Raw time series")
soiltemp_people<- read_excel("~/Google_Drive/Shared drives/CFS_microclimate/SoilTemp/SoilTemp2.0_data-submission_template_long_unique_sensor.xlsx", sheet="People")


### BU ibutton data----
BUMTN2022_cleaned <- read_csv("~/Google_Drive/Shared drives/CFS_microclimate/Projects/BUMTN2022/cleaned/BUMTN2022_cleaned_20231016.csv")
BUGhost2022_cleaned <- read_csv("~/Google_Drive/Shared drives/CFS_microclimate/Projects/BUGhost2022/cleaned/BUGhost2022_cleaned_20231016.csv")
BUCL2022_cleaned <- read_csv("~/Google_Drive/Shared drives/CFS_microclimate/Projects/BUCL2022/cleaned/BUCL2022_cleaned_20231016.csv")
BUGen2022_cleaned <- read_csv("~/Google_Drive/Shared drives/CFS_microclimate/Projects/BUGen2022/cleaned/BUGen2022_cleaned_20231016.csv")

### Project metadata----
epicollect_dpl_retr <- read_csv("~/Google Drive/Shared drives/CFS_microclimate/deployment_retrieval/CFSdeployment_retrieval/Epicollect deployment and retrieval 2022.csv")
missions_update <- read_csv("~/Google Drive/Shared drives/CFS_microclimate/deployment_retrieval/CFSdeployment_retrieval/Missions update here.csv")
epi_2023<-read_csv("0_data/test_ibutton_file_structure/epicollect/cleaned_csv/epicollect_deployment_retrivals_20230902.csv")%>%
  select(ec5_uuid, mission_id, site_id, shield_type, temp_sens_ht, latitude, longitude, accuracy, retrieval_date, deployment_date)

##////////////////////////////////////////////////////////////////


# Combine metadata----
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
    longitude=(coalesce(latitude.x, latitude.y)),
    accuracy=(coalesce(accuracy.x, accuracy.y)),
    retrieval_date=(coalesce(retrieval_date.x, retrieval_date.y)),
    deployment_date=(coalesce(deployment_date.x, deployment_date.y)))%>%
  dplyr::select(ec5_uuid, mission_id, site_id, shield_type, temp_sens_ht, latitude, longitude, accuracy, retrieval_date, deployment_date)

##////////////////////////////////////////////////////////////////

# Combine BU data----
# Combine BU data into single data frame
BU<-rbind(BUCL2022_cleaned, BUGhost2022_cleaned, BUMTN2022_cleaned, BUGen2022_cleaned)


##////////////////////////////////////////////////////////////////
# Format for soiltemp_metadata----

# Add missing metadata
BU_2<-left_join(BU, mission_meta)


BU_metadata<-BU_2%>%
  dplyr::group_by(mission_id) %>%
  arrange(mission_id, date_time) %>%
  mutate(Temporal_resolution = as.numeric(difftime(date_time, lag(date_time), units = "mins"))) %>%
  mutate(Temporal_resolution = ifelse(Temporal_resolution == 0, NA, Temporal_resolution))%>%
  mutate(Temporal_resolution = as.numeric(names(sort(table(Temporal_resolution), decreasing = TRUE)[1])),
            count = max(table(Temporal_resolution)))%>%
  ungroup() %>%
  select(-c(temperature, date_time, month, day, year))%>%
  distinct()%>%
  filter(!is.na(latitude))%>%
  mutate(meta_id=as.character(row_number()))%>%
  mutate(Country_code="CA")%>%
  mutate(Experimental_manipulation="No")%>%
  mutate(Experiment_insitu="No")%>%
  mutate(Experiment_climate="No")%>%
  mutate(Experiment_citizens="No")%>%
  mutate(EPSG=4326)%>%
  mutate(Logger_brand= "iButton")%>%
  mutate(Sensor_code = "Temperature")%>%
  mutate(Sensor_shielding = "Yes")%>%
  mutate(Sensor_shielding_type = "Yes")%>%
  mutate(Logger_serial_number=serial_number)%>%
  mutate(Experiment_insitu="Yes")%>%
  mutate(Microclimate_measurement= "Temperature")%>%
  mutate(Unit= "°C ")%>%
  mutate(Sensor_height="150")%>%
  mutate(Timezone="Local")%>%
  mutate(Time_difference="-6")%>%
  mutate(Licence="CC-BY")%>%
  mutate(Species_composition="No")%>%
  mutate(Species_trait="No")%>%
  mutate(deployment_date=as.POSIXct(deployment_date, format = "%d/%m/%Y"))%>%
  mutate(retrieval_date=as.POSIXct(retrieval_date, format = "%d/%m/%Y"))%>%
  mutate(Start_date_year=year(deployment_date))%>%
  mutate(Start_date_month=month(deployment_date))%>%
  mutate(Start_date_day=day(deployment_date))%>%
  mutate(End_date_year=year(retrieval_date))%>%
  mutate(End_date_month=month(retrieval_date))%>%
  mutate(End_date_day=day(retrieval_date))%>%
  select(-c(shield_type, filename, serial_full, ec5_uuid, count, deployment_date, retrieval_date, temp_sens_ht))%>%
  rename(Site_id=site_id, Experiment_name=project_id, Logger_code=serial_number, Raw_data_identifier=mission_id, Latitude=latitude, Longitude=longitude, GPS_accuracy=accuracy)
  

BU_metadata <- soiltemp_metadata %>%
  bind_rows(BU_metadata, .id = "source") %>%
  select(-source)

write_csv(BU_metadata, file="2_pipeline/tmp/BU_metadata.csv")

##////////////////////////////////////////////////////////////////
#Format for soiltemp_raw----
BU_raw<-BU%>%
  mutate(`Time (24h)`=format(date_time, "%H:%M:%S"))%>%
  rename(Raw_data_identifier=mission_id, Year=year, Month=month, Day=day, Temperature=temperature)%>%
  select(Raw_data_identifier,	Year,	Month,	Day,	`Time (24h)`,	Temperature)%>%
  semi_join(BU_metadata)

write_csv(BU_raw, file="2_pipeline/tmp/BU_raw.csv")











