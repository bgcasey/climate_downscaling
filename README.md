# Overview

# iButton Data

``` r
library(tidyr)
library(plyr)
library(dplyr)
library(kableExtra)
library(lubridate)
library(imputeTS)
```

## Import and clean

### RIVR

**Load data**

``` r
RIVR<-read.csv(file="0_data/external/iButton/RIVR/iButtons_RIVR_combined_April7_2022_no_extremes.csv")
```

**Examine data frame**

Count the number of unique iButtons

\[1\] 88

View data

|   X | Site | Point | Project | iBt_type | Site_StationKey |  Value | Date_Time           | N_of_heat_shields_at_station | old_wrong\_ | Top_ibutton_id | Bottom_ibutton_id | Extra_top_ibutton_id | Extra_bottom_ibutton_id | Zone | Easting | Northing | Date_deplo     | Time_deplo | Comments |      Lat |      Long | Status   | Date_Time_dpl       | Date_Time_rtv       | Month | Year | Day | Month_Year | New_Site_Key    | week | extreme |
|----:|-----:|------:|:--------|:---------|:----------------|-------:|:--------------------|-----------------------------:|:------------|:---------------|:------------------|:---------------------|:------------------------|-----:|--------:|---------:|:---------------|:-----------|:---------|---------:|----------:|:---------|:--------------------|:--------------------|------:|-----:|----:|:-----------|:----------------|-----:|:--------|
|   1 |    1 |     1 | RIVR    | BOT      | RIVR-001-01     | 25.090 | 2018-05-28 21:01:01 |                            2 |             | 9A-2F324B41    | 67-2F33FA41       |                      | 74-2F11C641             |   12 |  519088 |  5437719 | 5/28/2018 0:00 | 16:13      | NA       | 49.09203 | -110.7385 | Deployed | 2018-05-28 16:13:00 | 2020-08-03 10:53:00 |     5 | 2018 |  28 | 5-2018     | RIVR-001-01-BOT |   22 | NA      |
|   2 |    1 |     1 | RIVR    | BOT      | RIVR-001-01     | 19.587 | 2018-05-28 23:31:01 |                            2 |             | 9A-2F324B41    | 67-2F33FA41       |                      | 74-2F11C641             |   12 |  519088 |  5437719 | 5/28/2018 0:00 | 16:13      | NA       | 49.09203 | -110.7385 | Deployed | 2018-05-28 16:13:00 | 2020-08-03 10:53:00 |     5 | 2018 |  28 | 5-2018     | RIVR-001-01-BOT |   22 | NA      |
|   3 |    1 |     1 | RIVR    | BOT      | RIVR-001-01     | 17.585 | 2018-05-29 02:01:01 |                            2 |             | 9A-2F324B41    | 67-2F33FA41       |                      | 74-2F11C641             |   12 |  519088 |  5437719 | 5/28/2018 0:00 | 16:13      | NA       | 49.09203 | -110.7385 | Deployed | 2018-05-28 16:13:00 | 2020-08-03 10:53:00 |     5 | 2018 |  29 | 5-2018     | RIVR-001-01-BOT |   22 | NA      |
|   4 |    1 |     1 | RIVR    | BOT      | RIVR-001-01     | 17.085 | 2018-05-29 04:31:01 |                            2 |             | 9A-2F324B41    | 67-2F33FA41       |                      | 74-2F11C641             |   12 |  519088 |  5437719 | 5/28/2018 0:00 | 16:13      | NA       | 49.09203 | -110.7385 | Deployed | 2018-05-28 16:13:00 | 2020-08-03 10:53:00 |     5 | 2018 |  29 | 5-2018     | RIVR-001-01-BOT |   22 | NA      |
|   5 |    1 |     1 | RIVR    | BOT      | RIVR-001-01     | 14.080 | 2018-05-29 07:01:01 |                            2 |             | 9A-2F324B41    | 67-2F33FA41       |                      | 74-2F11C641             |   12 |  519088 |  5437719 | 5/28/2018 0:00 | 16:13      | NA       | 49.09203 | -110.7385 | Deployed | 2018-05-28 16:13:00 | 2020-08-03 10:53:00 |     5 | 2018 |  29 | 5-2018     | RIVR-001-01-BOT |   22 | NA      |
|   6 |    1 |     1 | RIVR    | BOT      | RIVR-001-01     | 16.083 | 2018-05-29 09:31:01 |                            2 |             | 9A-2F324B41    | 67-2F33FA41       |                      | 74-2F11C641             |   12 |  519088 |  5437719 | 5/28/2018 0:00 | 16:13      | NA       | 49.09203 | -110.7385 | Deployed | 2018-05-28 16:13:00 | 2020-08-03 10:53:00 |     5 | 2018 |  29 | 5-2018     | RIVR-001-01-BOT |   22 | NA      |

#### Edit data columns

##### Format date-time string

Convert date-time string into a `POSIXct` class. This class associates
the date time string with an associated time zone. Codes for time zones
can be found
[here](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones).
Else the `as.POSIXct` function defaults to your computer’s timezone.

``` r
RIVR$Date_Time<-as.POSIXct(RIVR$Date_Time, tz="America/Edmonton")
```

#### Remove unusable data

##### Remove months with incomplete data

Removing first month of data if it has only 20 days or less.

``` r
RIVR_1<- RIVR%>% split(f=.$New_Site_Key) %>% lapply(FUN=function(x){
  if (x %>% filter(month(Date_Time)==month(min(Date_Time))& year(Date_Time)==min(year(Date_Time))) %>%
      summarize(max(Day)-min(Day)) %>% c () < 20 ){
    y<-x %>% filter(month(Date_Time)>month(min(Date_Time))| year(Date_Time)> min(year(Date_Time)))    
    
    return(y)
  }else{
    return(x)
  }
}) 
```

Removing last month of data if it has only 20 days or less.

``` r
RIVR_2<-RIVR_1 %>% lapply(FUN=function(x){
  if (x %>% filter(month(Date_Time)==month(max(Date_Time))& year(Date_Time)==max(year(Date_Time))) %>% 
      summarize(max(Day)-min(Day)) %>% c () < 20 ){
    y<-x %>% filter(month(Date_Time)<month(max(Date_Time))| year(Date_Time)< max(year(Date_Time)))    
    
    #y<-x[!(month(x$Date_Time)==month(min(x$Date_Time) & year(x$Date_Time)==min(year(x$Date_Time)))),]
    return(y)
  }else{
    return(x)
  }
  
}) %>% do.call(rbind,.) #working

RIVR_cleaned<-RIVR_2
save(RIVR_cleaned, file="2_pipeline/tmp/RIVR_cleaned.rData")
```

#### Remove pre-deployement data

#### Identify and remove data from grounded iButtons

#### Get daily temperature summaries

Create new calculated columns with the mean, max, and min daily
temperatures.

``` r
RIVR_3<-RIVR_2 %>% 
  dplyr::group_by(Site_StationKey,Day,Month,Year,iBt_type)%>%  dplyr::mutate(Temperature=Value) %>%
  dplyr::summarize(Tmax_Day=max(Temperature),Tmin_Day=min(Temperature),Tavg_Day=mean(Temperature))%>% 
  dplyr::group_by(Site_StationKey,iBt_type,Month,Year) %>% dplyr::filter(!iBt_type=="EXTRA-TOP")

RIVR_dailys<-RIVR_3

save(RIVR_dailys, file="2_pipeline/store/RIVR_dailys.rData")
```

| Site_StationKey | Day | Month | Year | iBt_type | Tmax_Day | Tmin_Day |   Tavg_Day |
|:----------------|----:|------:|-----:|:---------|---------:|---------:|-----------:|
| RIVR-001-01     |   1 |     1 | 2019 | BOT      |    1.546 |  -15.538 | -5.9883000 |
| RIVR-001-01     |   1 |     1 | 2019 | EXTRA    |    1.588 |  -15.576 | -6.0299000 |
| RIVR-001-01     |   1 |     1 | 2020 | BOT      |    5.058 |    0.543 |  2.7503000 |
| RIVR-001-01     |   1 |     1 | 2020 | EXTRA    |    5.112 |    0.581 |  2.7964000 |
| RIVR-001-01     |   1 |     2 | 2019 | BOT      |    9.571 |   -8.498 | -0.2981111 |
| RIVR-001-01     |   1 |     2 | 2019 | EXTRA    |    9.636 |   -8.498 | -0.1551111 |

### HILL

**Load data**

``` r
hills<-read.csv(file="0_data/external/iButton/Hills/Hills_iButton_Data_Combined_Corrected_for_Deployment_no_extremes_Apr_27.csv")
```

**Examine data frame**

Count the number of unique iButtons

\[1\] 152

View data

|   X | Site_StationKey | Date       | Time     | Temperature | Date.Time           |
|----:|:----------------|:-----------|:---------|------------:|:--------------------|
|   1 | HL-1-01-1       | 2014-06-25 | 11:00:01 |      19.107 | 2014-06-25 11:00:01 |
|   2 | HL-1-01-1       | 2014-06-25 | 13:30:01 |      14.600 | 2014-06-25 13:30:01 |
|   3 | HL-1-01-1       | 2014-06-25 | 16:00:01 |      17.605 | 2014-06-25 16:00:01 |
|   4 | HL-1-01-1       | 2014-06-25 | 18:30:01 |      18.607 | 2014-06-25 18:30:01 |
|   5 | HL-1-01-1       | 2014-06-25 | 21:00:01 |      17.105 | 2014-06-25 21:00:01 |
|   6 | HL-1-01-1       | 2014-06-25 | 23:30:01 |      13.096 | 2014-06-25 23:30:01 |

#### Edit data columns

##### Format date-time string

Convert date-time string into a `POSIXct` class. This class associates
the date time string with an associated time zone. Codes for time zones
can be found
[here](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones).
Else the `as.POSIXct` function defaults to your computer’s timezone.

``` r
hills$Date.Time<-as.POSIXct(hills$Date.Time, tz="America/Edmonton")
```

#### Remove unusable data

##### Remove months with incomplete data

Remove first and last months if they have less than 21 days of data.

``` r
hills_1<-hills %>%
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
    
  }) %>% do.call(rbind,.) 


hills_cleaned<-hills_1
save(hills_cleaned, file="2_pipeline/tmp/hills_cleaned.rData")
```

#### Remove predeployement data

#### Identify and remove data from grounded iButtons

#### Get daily temperature summaries

Create new calculated columns with the mean, max, and min daily
temperatures.

``` r
hills_2<-hills_1 %>% 
 dplyr::group_by(Site_StationKey,Day,Month,Year) %>% #group by days, month and year
  dplyr::summarize(Tmax_Day=max(Temperature),Tmin_Day=min(Temperature),Tavg_Day=mean(Temperature))%>% 
  dplyr::group_by(Site_StationKey,Month,Year) 

hills_dailys<-hills_2

save(hills_dailys, file="2_pipeline/store/hills_dailys.rData")
```

| Site_StationKey | Day | Month | Year | Tmax_Day | Tmin_Day |   Tavg_Day |
|:----------------|----:|------:|-----:|---------:|---------:|-----------:|
| HL-1-01-1       |   1 |     1 | 2015 |  -13.032 |  -20.593 | -17.315900 |
| HL-1-01-1       |   1 |     2 | 2015 |  -17.063 |  -22.106 | -19.180900 |
| HL-1-01-1       |   1 |     3 | 2015 |   -2.464 |  -11.017 |  -6.991222 |
| HL-1-01-1       |   1 |     4 | 2015 |    0.049 |   -7.494 |  -4.576400 |
| HL-1-01-1       |   1 |     5 | 2015 |   10.590 |    1.054 |   5.923200 |
| HL-1-01-1       |   1 |     6 | 2015 |    9.085 |   -0.956 |   3.730556 |

## Combine datasets

### **Bind dataframes**

``` r
ibuttons<-bind_rows("RIVR"=RIVR_dailys,"HILLS"=hills_dailys,.id="Project")

save(ibuttons, file="2_pipeline/tmp/ibuttons.rData")
```

## Impute missing data

### Create a dummy iButton data frame

The data frame will have rows for every day during the time period the
iButtons were deployed. Daily temperature columns will be filled with NA
values.

Create a calendar for the time iButtons were deployed.

``` r
months <- 1:12

# create a data frame with the number of days per month
days <- days_in_month(months) %>% as.data.frame() %>% `colnames<-`("Days") %>%
  mutate(Month=row.names(.))


# create a list of months 
calendar<-apply(days,MARGIN = 1,FUN=function(x){
 seq(1:x)
  } 
 ) %>%
  lapply(.,FUN = unlist)


#create a calendar data frame with all of the days of the year for all stations. The dataframe will have columns for day, month,  and year and spans the time of the ibuttons
calendar_step1<-calendar %>% `names<-`(days$Month) %>% unlist() %>% as.data.frame() %>%
  `colnames<-`("Day") %>% mutate(Month_name=substr(rownames(.),1,3)) %>%
  left_join(data.frame(Month_name=month.abb,Month=months)) %>%
  expand_grid(.,Year=c(min(ibuttons$Year):max(ibuttons$Year)))
```

Create the dummy data frame that includes all of the days/year of the
above calendar data frame with NA instead of temperature values.

``` r
calendar_final<-data.frame(ibuttons$Site_StationKey,ibuttons$Project) %>% unique() %>%`colnames<-` (c("Site_StationKey","Project")) %>%
  expand_grid(.,calendar_step1) %>% mutate(iBt_type=NA,Tmax_Day=NA,Tmin_Day=NA,Tavg_Day=NA) %>% split(f = .$Project)

calendar_final_f1<-calendar_final$HILLS %>% filter(Year %in% unique(ibuttons$Year[ibuttons$Project=="HILLS"])) 
calendar_final_f2<-calendar_final$RIVR %>% filter(Year %in% unique(ibuttons$Year[ibuttons$Project=="RIVR"]))
complete_final_f3<-bind_rows(calendar_final_f1,calendar_final_f2) %>% select(!c(Month_name,iBt_type,Project))
```

### Remove months with too many missing days

We need to trim down the missing days for months in which up to 10 days
of data are missing.

``` r
# create a data frame of days with missing data
missing_days<-anti_join(complete_final_f3 %>% ungroup,
          ibuttons %>% ungroup() %>% select(!c(iBt_type,Project)),
          by=c("Site_StationKey","Day","Month","Year"))



# count the number of missing days and remove iButton months that are missing over 10 days of data
missing_of_importance<-missing_days %>% group_by(Site_StationKey,Month,Year) %>%
  summarize(count=n()) %>% filter(count<11) %>% mutate(keep="TRUE")

missing_days_final<-left_join(missing_days,missing_of_importance,by=c("Site_StationKey","Month","Year")) %>%
  filter(keep=="TRUE") %>% select(-c(count,keep))

#### Final iButton data frame with missing days {-}

complete_data_w_missing<-ibuttons %>% ungroup() %>% select(!c(iBt_type,Project)) %>%
  bind_rows(missing_days_final)

# create a column with the season
complete_data_w_missing_summer<- complete_data_w_missing %>% filter(Month %in% c(6,7,8))
complete_data_w_missing_winter<- complete_data_w_missing %>% filter(Month %in% c(12,1,2))
complete_data_w_missing_fall<- complete_data_w_missing %>% filter(Month %in% c(9,10,11))
complete_data_w_missing_spring<- complete_data_w_missing %>% filter(Month %in% c(3,4,5))

ib_cal<-bind_rows("Summer"=complete_data_w_missing_summer,
          "Winter"=complete_data_w_missing_winter,"Fall"=complete_data_w_missing_fall,"Spring"=complete_data_w_missing_spring, .id="Season")
```

### Impute missing values

Impute NA values using a spline function based on time series
imputation. The imputation is based on month per year per iButton site.

``` r
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

#save
ibuttons_complete_daily<-complete_data
save(ibuttons_complete_daily, file="0_data/manual/iButton_data/ibuttons_complete_daily.rData")

write.csv(ibuttons_complete_daily, file="0_data/manual/iButton_data/ibuttons_complete_daily.csv")
```

## Monthly summaries

``` r
ibuttons_complete_monthly<-ibuttons_complete_daily %>%
        group_by(Site_StationKey,Month,Year)%>%
        select(-Day)%>%
        summarise_all(list(mean))%>%
        arrange(Site_StationKey, Year, Month)
  
save(ibuttons_complete_monthly, file="0_data/manual/iButton_data/ibuttons_complete_monthly.rData")

write.csv(ibuttons_complete_monthly, file="0_data/manual/iButton_data/ibuttons_complete_monthly.csv")
```

| Site_StationKey | Month | Year |   Tmax_Day |   Tmin_Day |    Tavg_Day |
|:----------------|------:|-----:|-----------:|-----------:|------------:|
| HL-1-01-1       |     7 | 2014 |  22.092774 |  12.966516 |  17.2760068 |
| HL-1-01-1       |     8 | 2014 |  20.090000 |  10.507000 |  15.1851448 |
| HL-1-01-1       |     9 | 2014 |  10.988233 |   4.215733 |   7.3967259 |
| HL-1-01-1       |    10 | 2014 |   2.769000 |  -0.989871 |   0.7119638 |
| HL-1-01-1       |    11 | 2014 | -10.954000 | -15.437567 | -13.2250244 |
| HL-1-01-1       |    12 | 2014 |  -9.672258 | -15.098323 | -12.5882631 |

## Create spatial objects

``` r
library(sf)
library(tmap)
library(basemaps)
library(dplyr)
library(kableExtra)
```

### RIVR

**Load data**

``` r
RIVR<-read.csv(file="0_data/external/iButton/RIVR/iButtons_RIVR_combined_April7_2022_no_extremes.csv")
```

#### Create spatial data frame of iButton locations

Extract XY coordinates and save as shapefile.

``` r
RIVR_xy<-RIVR%>%
  dplyr::select(c(Project, Site_StationKey, Date_deplo, Lat, Long))%>%
  dplyr::distinct()

RIVR_xy<-st_as_sf(RIVR_xy, coords=c("Long","Lat"), crs=4326)

# save as spatial data frame
save(RIVR_xy, file="0_data/manual/spatial/RIVR_xy.rData")

# save as shapefile
st_write(RIVR_xy, "0_data/manual/spatial/RIVR_xy.shp")
```

### HILL

**Load data**

``` r
hills<-read.csv(file="0_data/external/iButton/Hills/Hills_iButton_Data_Combined_Corrected_for_Deployment_no_extremes_Apr_27.csv")
```

#### Create spatial data frame of iButton locations

Extract XY coordinates and save as shapefile.

``` r
hills_xy<-hills%>%
  dplyr::select(c(Project, Site_StationKey, Date_deplo, Lat, Long))%>%
  dplyr::distinct()

hills_xy<-st_as_sf(hills_xy, coords=c("Long","Lat"), crs=4326)

# save as spatial data frame
save(hills_xy, file="0_data/manual/spatial/hills_xy.rData")

# save as shapefile
st_write(hills_xy, "0_data/manual/spatial/hills_xy.shp")
```

### Map study area

#### Identify study area

``` r
#create a bounding box around study area
bb<-st_bbox(RIVR_xy)

#Get aspect ratio of bounding box
bb<-st_as_sfc(bb)
bb<-st_as_sf(bb)
bb_buf<-st_buffer(bb, 10000)
bb_buf<-st_bbox(bb_buf)
bb_buf<-st_as_sfc(bb_buf)
bb_buf<-st_as_sf(bb_buf)

study_area<-bb_buf

# save as spatial data frame
save(study_area, file="0_data/manual/spatial/study_area.rData")

# save as shapefile
st_write(study_area, "0_data/manual/spatial/study_area.shp")
```

``` r
# Plot

# get basemap
base<-basemap_raster(study_area, map_service = "esri", map_type = "delorme_world_base_map")

# get aspect ratio of the study area
asp <- (study_area$ymax - study_area$ymin)/(study_area$xmax - study_area$xmin)

# m<-tm_shape(alberta)+tm_borders()+tm_fill(col = "#fddadd")+
#   #tm_polygons(col=NA, border.col="black")+
#   tm_layout(frame=FALSE)+
#   tm_legend(outside=TRUE, frame=FALSE)+
m<-tm_shape(base)+
  tm_rgb()+
  tm_shape(RIVR_xy)+
    tm_symbols(col = "#D00D00", border.lwd = 0, size = .3, alpha=.3, title.shape="iButton locations", legend.format = list(text.align="right", text.to.columns = TRUE))
  #tm_legend(position=c("left", "top"), frame=TRUE)
m

tmap_save(m, "3_output/maps/RIVR_xy.png")
```

## <img src="3_output/maps/RIVR_xy.png" alt="iButton locations." width="50%" />

# Covariates

## iButton deployment

Extracting deployment related covariates i.e. distance between deployed
iButtons and the ground, shielding, and damage sustained prior to
retrieval.

## Spatial

Spatial covariates were extracted using Google Earth Engine’s online
code editor at
[code.earthengine.google.com](http://code.earthengine.google.com/).

------------------------------------------------------------------------

# Modelling

## Data exploration and visualization

## Model selection

## Offset raster

## Validate

# References

<div id="refs">

</div>

<!--chapter:end:index.Rmd-->
