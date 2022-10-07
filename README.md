-   <a href="#overview" id="toc-overview">Overview</a>
-   <a href="#ibutton-data" id="toc-ibutton-data">iButton Data</a>
    -   <a href="#clean" id="toc-clean">Clean</a>
        -   <a href="#rivr" id="toc-rivr">RIVR</a>
        -   <a href="#hill" id="toc-hill">HILL</a>
    -   <a href="#combine" id="toc-combine">Combine</a>
        -   <a href="#setup" id="toc-setup">Setup</a>
        -   <a href="#combine-ibutton-data" id="toc-combine-ibutton-data">Combine
            iButton data</a>
        -   <a href="#create-spatial-data-frame-of-ibutton-locations"
            id="toc-create-spatial-data-frame-of-ibutton-locations">Create spatial
            data frame of iButton locations</a>
    -   <a href="#create-spatial-object" id="toc-create-spatial-object">Create
        spatial object</a>
-   <a href="#covariates" id="toc-covariates">Covariates</a>
    -   <a href="#ibutton-deployment" id="toc-ibutton-deployment">iButton
        deployment</a>
    -   <a href="#spatial" id="toc-spatial">Spatial</a>
-   <a href="#modelling" id="toc-modelling">Modelling</a>
    -   <a href="#data-exploration-and-visualization"
        id="toc-data-exploration-and-visualization">Data exploration and
        visualization</a>
    -   <a href="#model-selection" id="toc-model-selection">Model selection</a>
    -   <a href="#offset-raster" id="toc-offset-raster">Offset raster</a>
    -   <a href="#validate" id="toc-validate">Validate</a>
-   <a href="#references" id="toc-references">References</a>

# Overview

# iButton Data

## Clean

``` r
library(sf)
library(tmap)
library(basemaps)
library(dplyr)
library(kableExtra)
library(lubridate)
```

### RIVR

#### Import iButton data

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

#### Remove predeployement data

#### Identify and remove data from grounded iButtons

``` r
####RIVR Dataset####
temp_df_rivr_input_step1<-df_rivr_step2 %>% 
  dplyr::group_by(Site_StationKey,Day,Month,Year,iBt_type)%>%  dplyr::mutate(Temperature=Value) %>%
  dplyr::summarize(Tmax_Day=max(Temperature),Tmin_Day=min(Temperature),Tavg_Day=mean(Temperature))%>% 
  dplyr::group_by(Site_StationKey,iBt_type,Month,Year) %>% dplyr::filter(!iBt_type=="EXTRA-TOP")
```

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
```

#### Remove predeployement data

#### Identify and remove data from grounded iButtons

#### Get daily temperature summaries

``` r
# %>% ####bind everything
#   dplyr::group_by(Site_StationKey,Day,Month,Year) %>% #group by days, month and year
#   dplyr::summarize(Tmax_Day=max(Temperature),Tmin_Day=min(Temperature),Tavg_Day=mean(Temperature))%>% 
#   dplyr::group_by(Site_StationKey,Month,Year) 
```

## Combine

### Setup

##### Load libraries

``` r
library(sf)
library(tmap)
library(basemaps)
library(dplyr)
library(kableExtra)
```

##### Import iButton data

``` r
hills<-read.csv(file="0_data/external/iButton/Hills/Hills_iButton_Data_Combined_Corrected_for_Deployment_no_extremes_Apr_27.csv")

RIVR<-read.csv(file="0_data/external/iButton/RIVR/iButtons_RIVR_combined_April7_2022_no_extremes.csv")
```

### Combine iButton data

#### Examine iButton data frames

``` r
# count unique deployments
nrow(distinct(as.data.frame((hills$Site_StationKey))))
```

    ## [1] 152

``` r
nrow(distinct(as.data.frame((RIVR$Site_StationKey))))
```

    ## [1] 88

|   X | Site_StationKey | Date       | Time     | Temperature | Date.Time           |
|----:|:----------------|:-----------|:---------|------------:|:--------------------|
|   1 | HL-1-01-1       | 2014-06-25 | 11:00:01 |      19.107 | 2014-06-25 11:00:01 |
|   2 | HL-1-01-1       | 2014-06-25 | 13:30:01 |      14.600 | 2014-06-25 13:30:01 |
|   3 | HL-1-01-1       | 2014-06-25 | 16:00:01 |      17.605 | 2014-06-25 16:00:01 |
|   4 | HL-1-01-1       | 2014-06-25 | 18:30:01 |      18.607 | 2014-06-25 18:30:01 |
|   5 | HL-1-01-1       | 2014-06-25 | 21:00:01 |      17.105 | 2014-06-25 21:00:01 |
|   6 | HL-1-01-1       | 2014-06-25 | 23:30:01 |      13.096 | 2014-06-25 23:30:01 |

|   X | Site | Point | Project | iBt_type | Site_StationKey |  Value | Date_Time           | N_of_heat_shields_at_station | old_wrong\_ | Top_ibutton_id | Bottom_ibutton_id | Extra_top_ibutton_id | Extra_bottom_ibutton_id | Zone | Easting | Northing | Date_deplo     | Time_deplo | Comments |      Lat |      Long | Status   | Date_Time_dpl       | Date_Time_rtv       | Month | Year | Day | Month_Year | New_Site_Key    | week | extreme |
|----:|-----:|------:|:--------|:---------|:----------------|-------:|:--------------------|-----------------------------:|:------------|:---------------|:------------------|:---------------------|:------------------------|-----:|--------:|---------:|:---------------|:-----------|:---------|---------:|----------:|:---------|:--------------------|:--------------------|------:|-----:|----:|:-----------|:----------------|-----:|:--------|
|   1 |    1 |     1 | RIVR    | BOT      | RIVR-001-01     | 25.090 | 2018-05-28 21:01:01 |                            2 |             | 9A-2F324B41    | 67-2F33FA41       |                      | 74-2F11C641             |   12 |  519088 |  5437719 | 5/28/2018 0:00 | 16:13      | NA       | 49.09203 | -110.7385 | Deployed | 2018-05-28 16:13:00 | 2020-08-03 10:53:00 |     5 | 2018 |  28 | 5-2018     | RIVR-001-01-BOT |   22 | NA      |
|   2 |    1 |     1 | RIVR    | BOT      | RIVR-001-01     | 19.587 | 2018-05-28 23:31:01 |                            2 |             | 9A-2F324B41    | 67-2F33FA41       |                      | 74-2F11C641             |   12 |  519088 |  5437719 | 5/28/2018 0:00 | 16:13      | NA       | 49.09203 | -110.7385 | Deployed | 2018-05-28 16:13:00 | 2020-08-03 10:53:00 |     5 | 2018 |  28 | 5-2018     | RIVR-001-01-BOT |   22 | NA      |
|   3 |    1 |     1 | RIVR    | BOT      | RIVR-001-01     | 17.585 | 2018-05-29 02:01:01 |                            2 |             | 9A-2F324B41    | 67-2F33FA41       |                      | 74-2F11C641             |   12 |  519088 |  5437719 | 5/28/2018 0:00 | 16:13      | NA       | 49.09203 | -110.7385 | Deployed | 2018-05-28 16:13:00 | 2020-08-03 10:53:00 |     5 | 2018 |  29 | 5-2018     | RIVR-001-01-BOT |   22 | NA      |
|   4 |    1 |     1 | RIVR    | BOT      | RIVR-001-01     | 17.085 | 2018-05-29 04:31:01 |                            2 |             | 9A-2F324B41    | 67-2F33FA41       |                      | 74-2F11C641             |   12 |  519088 |  5437719 | 5/28/2018 0:00 | 16:13      | NA       | 49.09203 | -110.7385 | Deployed | 2018-05-28 16:13:00 | 2020-08-03 10:53:00 |     5 | 2018 |  29 | 5-2018     | RIVR-001-01-BOT |   22 | NA      |
|   5 |    1 |     1 | RIVR    | BOT      | RIVR-001-01     | 14.080 | 2018-05-29 07:01:01 |                            2 |             | 9A-2F324B41    | 67-2F33FA41       |                      | 74-2F11C641             |   12 |  519088 |  5437719 | 5/28/2018 0:00 | 16:13      | NA       | 49.09203 | -110.7385 | Deployed | 2018-05-28 16:13:00 | 2020-08-03 10:53:00 |     5 | 2018 |  29 | 5-2018     | RIVR-001-01-BOT |   22 | NA      |
|   6 |    1 |     1 | RIVR    | BOT      | RIVR-001-01     | 16.083 | 2018-05-29 09:31:01 |                            2 |             | 9A-2F324B41    | 67-2F33FA41       |                      | 74-2F11C641             |   12 |  519088 |  5437719 | 5/28/2018 0:00 | 16:13      | NA       | 49.09203 | -110.7385 | Deployed | 2018-05-28 16:13:00 | 2020-08-03 10:53:00 |     5 | 2018 |  29 | 5-2018     | RIVR-001-01-BOT |   22 | NA      |

#### Join iButton data frames

**Prepare RIVR data**

``` r
temp_df_rivr_input_step1<-RIVR %>% 
  dplyr::group_by(Site_StationKey,Day,Month,Year,iBt_type)%>%  dplyr::mutate(Temperature=Value) %>%
  dplyr::summarize(Tmax_Day=max(Temperature),Tmin_Day=min(Temperature),Tavg_Day=mean(Temperature))%>% 
  dplyr::group_by(Site_StationKey,iBt_type,Month,Year) %>% dplyr::filter(!iBt_type=="EXTRA-TOP")
```

### Create spatial data frame of iButton locations

#### Extract XY coordinates

``` r
RIVR_xy<-RIVR%>%
  dplyr::select(c(Project, Site_StationKey, Date_deplo, Lat, Long))%>%
  dplyr::distinct()

RIVR_xy<-st_as_sf(RIVR_xy, coords=c("Long","Lat"), crs=4326)

# save as spatial data frame
save(RIVR_xy, file="0_data/manual/spatial/RIVR_xy.rData")

# save as shapefile
st_write(RIVR_xy, "0_data/manual/spatial/RIVR_xy.shp")

# buffer points
RIVR_xy_buff<-st_buffer(RIVR_xy, 100)

# save as spatial data frame
save(RIVR_xy_buff, file="0_data/manual/spatial/RIVR_xy_buf.rData")

# save as shapefile
st_write(RIVR_xy_buff, "0_data/manual/spatial/RIVR_xy_buf.shp")
```

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

<img src="3_output/maps/RIVR_xy.png" alt="iButton locations." width="50%" />

## Create spatial object

------------------------------------------------------------------------

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
