library(data.table)
library(tidyverse)

Yukon2022<-"/Users/brendancasey/Library/CloudStorage/GoogleDrive-bgcasey@ualberta.ca/Shared drives/CFS_microclimate/Projects//CFSYukon2022_a/raw/FE0000006E1D1D41_080723.csv"


combined_data_1 <- data.frame()
# Loop through each file
for (i in 1:length(file_list)) {
  # Read the data file skipping the first 19 rows
  file_data <- fread(file_list,skip = "Date", sep = ",")
  ##extract the first 18 rows
  headers_data <- fread(file_list, nrows= 18, sep = ",", header = FALSE, fill = TRUE, blank.lines.skip = TRUE)
  headers_data <- headers_data[,1]
  ##add the file name to combined data
  file_data$serial_full <- substr(headers_data[2], 37,52)
  ##bring in each file name
  file_data$filename <- file_list
  # Append the data to the combined data frame
  combined_data_1 <- bind_rows(combined_data_1, file_data)
}

combined_data_2 <- combined_data_1 %>%
  dplyr::select(-c(Unit)) %>% 
  mutate(serial_number= str_sub(serial_full, 9, 14)) %>%
  # add project_id field
  mutate(project_id="Yukon2022")%>%
  # add mission id column
  mutate(mission_id=paste(project_id, serial_number, sep="_"))%>%
  mutate(date_time = strptime(`Date/Time`, format = "%m/%d/%Y %I:%M:%S %p"))%>%
  mutate(date_time = ymd_hms(`date_time`)) %>% 
  select(-c(`Date/Time`)) %>%
  mutate(month=month(date_time))%>%
  mutate(day=day(date_time))%>%
  mutate(year=year(date_time)) %>% 
  rename(temperature= Value)

combined_data_3 <- combined_data_2 %>%
  left_join(mission_meta)

# save as a csv within the correct project parent directory
save_dir<- paste0(save_dir, "cleaned/") 

df_name<-paste0(basename(dirname(dir)), "_cleaned")
assign(df_name, combined_data_3, envir = .GlobalEnv)

write_csv(combined_data_3, file=paste0(save_dir, combined_data_3$project_id[1], "_cleaned_", format(Sys.Date(), "%Y%m%d"), ".csv"))


file_data <- fread("/Users/brendancasey/Library/CloudStorage/GoogleDrive-bgcasey@ualberta.ca/Shared drives/CFS_microclimate/Projects//CFSYukon2022_a/raw/FE0000006E1D1D41_080723.csv",skip = "Date", sep = ",")
