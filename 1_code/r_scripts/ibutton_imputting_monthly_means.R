#August 29th 2022
#Original Script by Cesar, modified by Kimberly Morrison to suit model imput
#Script imputs missing data and finds monthly mean
#Also does some data cleaning

#probably you can delete some of these packages, as Cesar's original script was much longer
####~~~Packages~~~~####
library("ggplot2")
library('lubridate')
library('cowplot')
library('sjPlot')
library('lme4')
library('AICcmodavg')
library(data.table)
library(devtools)
library("performance")
library("insight")
library(sp)
library(plyr)
library(dplyr)
library("rlist")
require(gridExtra)
require(RColorBrewer)
library("colorRamps")
library(mgcv);
library(nlme)
library(sjlabelled)
library(sjmisc)
library("beepr")
library("reshape2")
library(plyr)
library(dplyr)
library("ggpubr")
library(rgeos)
library("glmmTMB")
library(purrr)
library("ggeffects")
library(sf)
library("nlme")
library(tidyr)
library("stars")
library("MuMIn")
library("mice")
library("imputeTS")

#load if needed
#library(raster)
###RIVR DATA - DIFFERENT IQR (3XIQR)####
###COrrected for deployment already
###~~~~~~~~~~~~~~~~~~~~###
path_to_data<-"W:/EDM/CCVegMod4/Downscaling/ibutton/"

#remove outliers
# remove median plus minus 3x interquartile range max and min temperature

#imput start date/end date manually to know when it is deployed/taken down so don't have car readings and office readings
#if min and max are very close together likely indoors but doesn't account for being in car

#right now this script has 2 ibutton datasets (hills and river).  

#file needs to have the headings: New_Site_Key Date_Time
rivr_data_raw<-read.csv('W:/EDM/CCVegMod4/Downscaling/ibutton/iButtons_RIVR_combined_April7_2022_no_extremes.csv')
rivr_data_raw$Date_Time<-as.POSIXct(rivr_data_raw$Date_Time)



#removing first month of data if it has only 20 days
df_rivr_step1<- rivr_data_raw %>% split(f=.$New_Site_Key) %>% lapply(FUN=function(x){
  if (x %>% filter(month(Date_Time)==month(min(Date_Time))& year(Date_Time)==min(year(Date_Time))) %>%
      summarize(max(Day)-min(Day)) %>% c () < 20 ){
    y<-x %>% filter(month(Date_Time)>month(min(Date_Time))| year(Date_Time)> min(year(Date_Time)))    
    
    return(y)
  }else{
    return(x)
  }
  
}) 
#removing last month of data if it has less than 20 days of data

df_rivr_step2<-df_rivr_step1 %>% lapply(FUN=function(x){
  if (x %>% filter(month(Date_Time)==month(max(Date_Time))& year(Date_Time)==max(year(Date_Time))) %>% 
      summarize(max(Day)-min(Day)) %>% c () < 20 ){
    y<-x %>% filter(month(Date_Time)<month(max(Date_Time))| year(Date_Time)< max(year(Date_Time)))    
    
    #y<-x[!(month(x$Date_Time)==month(min(x$Date_Time) & year(x$Date_Time)==min(year(x$Date_Time)))),]
    return(y)
  }else{
    return(x)
  }
  
}) %>% do.call(rbind,.) #working

####~~~~ Merging RIVR AND HILLS DATA - BEFORE INPUTTING ~~~~####

####RIVR Dataset####
temp_df_rivr_input_step1<-df_rivr_step2 %>% 
  dplyr::group_by(Site_StationKey,Day,Month,Year,iBt_type)%>%  dplyr::mutate(Temperature=Value) %>%
  dplyr::summarize(Tmax_Day=max(Temperature),Tmin_Day=min(Temperature),Tavg_Day=mean(Temperature))%>% 
  dplyr::group_by(Site_StationKey,iBt_type,Month,Year) %>% dplyr::filter(!iBt_type=="EXTRA-TOP")


####HILLS Dataset####
###Creating new columns;
###Removing first/last month if has less than 21 days
data_hills_step1<-read.csv(paste0("W:/EDM/CCVegMod4/Downscaling/ibutton/Hills_iButton Data Combined Corrected for Deployment_no_extremes_Apr_27.csv")) 
data_hills_step2<-data_hills_step1 %>%
  mutate(Value=Temperature,Month=month(Date.Time),Day=day(Date.Time),Year=year(Date.Time),
                Date_Time=Date.Time) %>%  
  ###Split per site_stationkey and remove first and last month if they have less than 20 days
  split(f=.$Site_StationKey) %>% lapply(FUN=function(x){
    if (x %>% filter(month(Date_Time)==month(min(Date_Time))& year(Date_Time)==min(year(Date_Time))) %>%
        summarize(max(Day)-min(Day)) %>% c () < 20 ){
      y<-x %>% filter(month(Date_Time)>month(min(Date_Time))| year(Date_Time)> min(year(Date_Time)))    
      
      return(y)
    }else{
      return(x)
    }
    
  }) %>% lapply(FUN=function(x){
    if (x %>% filter(month(Date_Time)==month(max(Date_Time))& year(Date_Time)==max(year(Date_Time))) %>% 
        summarize(max(Day)-min(Day)) %>% c () < 20 ){
      y<-x %>% filter(month(Date_Time)<month(max(Date_Time))| year(Date_Time)< max(year(Date_Time)))    
      
      #y<-x[!(month(x$Date_Time)==month(min(x$Date_Time) & year(x$Date_Time)==min(year(x$Date_Time)))),]
      return(y)
    }else{
      return(x)
    }
    
  }) %>% do.call(rbind,.) %>% ####bind everything
  dplyr::group_by(Site_StationKey,Day,Month,Year) %>% #group by days, month and year
  dplyr::summarize(Tmax_Day=max(Temperature),Tmin_Day=min(Temperature),Tavg_Day=mean(Temperature))%>% 
  dplyr::group_by(Site_StationKey,Month,Year) 


####bind both datasets

rivr_hl_input<-bind_rows("RIVR"=temp_df_rivr_input_step1,"HILLS"=data_hills_step2,.id="Project")


months <- 1:12

days <- days_in_month(months) %>% as.data.frame() %>% `colnames<-`("Days") %>%
  mutate(Month=row.names(.))

calendar<-apply(days,MARGIN = 1,FUN=function(x){
 seq(1:x)
  } 
 ) %>%
  lapply(.,FUN = unlist)

#create a calendar with all days of the year for all stations
calendar_step1<-calendar %>% `names<-`(days$Month) %>% unlist() %>% as.data.frame() %>%
  `colnames<-`("Day") %>% mutate(Month_name=substr(rownames(.),1,3)) %>%
  left_join(data.frame(Month_name=month.abb,Month=months)) %>%
  expand_grid(.,Year=c(min(rivr_hl_input$Year):max(rivr_hl_input$Year)))

calendar_final<-data.frame(rivr_hl_input$Site_StationKey,rivr_hl_input$Project) %>% unique() %>%`colnames<-` (c("Site_StationKey","Project")) %>%
  expand_grid(.,calendar_step1) %>% mutate(iBt_type=NA,Tmax_Day=NA,Tmin_Day=NA,Tavg_Day=NA) %>% split(f = .$Project)
  
calendar_final_f1<-calendar_final$HILLS %>% filter(Year %in% unique(rivr_hl_input$Year[rivr_hl_input$Project=="HILLS"])) 
calendar_final_f2<-calendar_final$RIVR %>% filter(Year %in% unique(rivr_hl_input$Year[rivr_hl_input$Project=="RIVR"]))

complete_final_f3<-bind_rows(calendar_final_f1,calendar_final_f2) %>% select(!c(Month_name,iBt_type,Project))

###Need to trim down the missing days for months in which up to 10 days of data are missing
missing_days<-anti_join(complete_final_f3 %>% ungroup,
          rivr_hl_input %>% ungroup() %>% select(!c(iBt_type,Project)),
          by=c("Site_StationKey","Day","Month","Year"))


missing_of_importance<-missing_days %>% group_by(Site_StationKey,Month,Year) %>%
  summarize(count=n()) %>% filter(count<11) %>% mutate(keep="TRUE")

missing_days_final<-left_join(missing_days,missing_of_importance,by=c("Site_StationKey","Month","Year")) %>%
  filter(keep=="TRUE") %>% select(-c(count,keep))

complete_data_w_missing<-rivr_hl_input %>% ungroup() %>% select(!c(iBt_type,Project)) %>%
  bind_rows(missing_days_final)

complete_data_w_missing_summer<- complete_data_w_missing %>% filter(Month %in% c(6,7,8))
complete_data_w_missing_winter<- complete_data_w_missing %>% filter(Month %in% c(12,1,2))
complete_data_w_missing_fall<- complete_data_w_missing %>% filter(Month %in% c(9,10,11))
complete_data_w_missing_spring<- complete_data_w_missing %>% filter(Month %in% c(3,4,5))

##Saving CSV
bind_rows("Summer"=complete_data_w_missing_summer,
          "Winter"=complete_data_w_missing_winter,"Fall"=complete_data_w_missing_fall,"Spring"=complete_data_w_missing_spring, .id="Season") %>%
  write.csv(paste0(path_to_data,"/topography_data_to_input_all_year_no_extremes.csv"))


####Reload data to make it easier####
full_data_to_input<-read.csv(paste0(path_to_data,"/topography_data_to_input_all_year_no_extremes.csv")) %>% split(f=.$Season)

complete_data_w_missing_summer<-full_data_to_input$Summer
complete_data_w_missing_winter<-full_data_to_input$Winter
complete_data_w_missing_summer<-full_data_to_input$Fall
complete_data_w_missing_winter<-full_data_to_input$Spring

###Inputting####
###Using spline function based on time series inputation
### Input per month per year per site (per group)

inputted_summer<-ddply(complete_data_w_missing_summer,.(Site_StationKey,Month,Year),.fun = 
        function(x){
          na_interpolation(x,option="spline")
        })


inputted_winter<-ddply(complete_data_w_missing_winter,.(Site_StationKey,Month,Year),.fun = 
                         function(x){
                           na_interpolation(x,option="spline")
                         })
inputted_fall<-ddply(complete_data_w_missing_fall,.(Site_StationKey,Month,Year),.fun = 
                         function(x){
                           na_interpolation(x,option="spline")
                         })


inputted_spring<-ddply(complete_data_w_missing_spring,.(Site_StationKey,Month,Year),.fun = 
                         function(x){
                           na_interpolation(x,option="spline")
                         })


complete_data<-bind_rows(inputted_summer,inputted_winter,inputted_fall,inputted_spring)

write.csv(complete_data,paste0(path_to_data,"/topography_data_inputted_all_year_ts.csv"))


#Summarize by month
complete_data_monthly<-aggregate(complete_data,by=list(complete_data$Site_StationKey,complete_data$Month,complete_data$Year),FUN=mean)
head(complete_data_monthly)
complete_data_monthly<-select(complete_data_monthly,c("Group.1","Month","Year","Tmax_Day","Tmin_Day","Tavg_Day"))
colnames(complete_data_monthly)<-c("Site_StationKey","Month","Year","Tmax_Day","Tmin_Day","Tavg_Day")
head(complete_data_monthly)
write.csv(complete_data_monthly,paste0(path_to_data,"/topography_data_inputted_all_year_monthly.csv"))













