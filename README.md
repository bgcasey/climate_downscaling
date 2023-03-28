- <a href="#prepare-data" id="toc-prepare-data">Prepare data</a>
- <a href="#create-spatial-objects" id="toc-create-spatial-objects">Create
  spatial objects</a>
- <a href="#quality-control" id="toc-quality-control">Quality control</a>
- <a href="#climatena-data" id="toc-climatena-data">ClimateNA data</a>
  - <a href="#setup" id="toc-setup">Setup</a>
  - <a href="#create-input-file" id="toc-create-input-file">Create input
    file</a>
  - <a href="#extract-climatena-summaries"
    id="toc-extract-climatena-summaries">Extract ClimateNA summaries</a>
  - <a href="#calculate-difference-between-ibutton-and-climatena-summaries"
    id="toc-calculate-difference-between-ibutton-and-climatena-summaries">Calculate
    difference between iButton and ClimateNA summaries</a>
- <a href="#spatial-covariates" id="toc-spatial-covariates">Spatial
  covariates</a>
  - <a href="#gee-scripts" id="toc-gee-scripts">GEE scripts</a>
  - <a href="#gee-csvs" id="toc-gee-csvs">GEE CSVs</a>
  - <a href="#gee-rasters" id="toc-gee-rasters">GEE Rasters</a>
  - <a href="#setup-data-for-gbm" id="toc-setup-data-for-gbm">Setup data for
    GBM</a>
- <a href="#modelling" id="toc-modelling">Modelling</a>
  - <a href="#boosted-regression-trees"
    id="toc-boosted-regression-trees">Boosted regression trees</a>
  - <a href="#predicted-offset-raster"
    id="toc-predicted-offset-raster">Predicted offset raster</a>
  - <a href="#combine-predictive-rasters-into-a-single-multi-band-raster"
    id="toc-combine-predictive-rasters-into-a-single-multi-band-raster">Combine
    predictive rasters into a single multi band raster</a>
  - <a href="#validate" id="toc-validate">Validate</a>
- <a href="#references" id="toc-references">References</a>

Here we present our workflow and code for refining ClimateNA temperature
predictions using temperature data loggers and remote sensing data
accessed via Google Earth Engine.

Ecological studies often rely on interpolated climate data to predict
species distributions and identify climate change refugia. However, the
scale of climate data does not always correspond to the scale of habitat
conditions influencing organisms. ClimateNA, a freely available software
package, addresses this by providing scale-free predictions of climate
variables by interpolating gridded climate data and adjusting for
elevation. While useful, ClimateNA predictions could be improved by
incorporating other variables that influence micro-climatic variation.
We developed methods to refine ClimateNA air temperature predictions
using temperature data loggers and remote sensing data accessed via
Google Earth Engine. Monthly temperature variables from 2005-2021 were
calculated using near-surface temperatures gathered from 513 monitoring
sites across Alberta, Canada. We used variables associated with terrain,
vegetation structure, and atmospheric conditions in boosted-regression
trees to predict differences between ClimateNA temperature predictions
and micro-climate conditions. We produced 30 m seasonal offset layers
for mean, maximum, and minimum temperatures covering all of Alberta and
British Columbia. Mean summer temperatures were on average -0.03°C (SD =
0.71) greater than ClimateNA predictions; maximum summer temperatures
were on average 6.81°C (SD = 1.11) less than CimateNA predictions; and
winter minimum temperatures were on average -0.81°C (SD = 0.98) greater
than CimateNA predictions. Offset adjusted ClimateNA predictions should
better reflect micro-climatic variation and improve the accuracy of
species-habitat models.

fsghf \# iButton Data

First we gathered temperature data from temperature data loggers
deployed across the province of Alberta. ([Wood et al.
2017](#ref-wood2017dtdf))

``` r
library(readxl)
iButton_sources <- read_excel("0_data/iButton_sources.xlsx")


kable(iButton_sources,
  align = c("l","l","l","r"), caption = 'Sources of temperature data loggers included in the analysis.', booktabs=TRUE)
```

<table>
<caption>
Sources of temperature data loggers included in the analysis.
</caption>
<thead>
<tr>
<th style="text-align:left;">
Project code
</th>
<th style="text-align:left;">
Number of loggers
</th>
<th style="text-align:left;">
Time frame
</th>
<th style="text-align:right;">
Region
</th>
<th style="text-align:left;">
Reference
</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:left;">
RIVR
</td>
<td style="text-align:left;">
88
</td>
<td style="text-align:left;">
2018-2020
</td>
<td style="text-align:right;">
Alberta
</td>
<td style="text-align:left;">
/Estevo et al. ([2022](#ref-estevoTopographicVegetationDrivers2022))
</td>
</tr>
<tr>
<td style="text-align:left;">
HILLS
</td>
<td style="text-align:left;">
152
</td>
<td style="text-align:left;">
2014-2016
</td>
<td style="text-align:right;">
Alberta
</td>
<td style="text-align:left;">
NA
</td>
</tr>
<tr>
<td style="text-align:left;">
WOOD
</td>
<td style="text-align:left;">
232
</td>
<td style="text-align:left;">
2005-2010
</td>
<td style="text-align:right;">
Alberta
</td>
<td style="text-align:left;">
Wood et al. ([2017](#ref-wood2017dtdf))
</td>
</tr>
</tbody>
</table>

``` r
  # column_spec(column = 3, width = "50em") %>% 
  # kable_styling(font_size = 6, position = "center", full_width = T)
```

## Prepare data

Use `1_code/r_notebooks/ibutton_data_prepare.Rmd`.

``` r
library(tidyr)
library(plyr)
library(dplyr)
library(kableExtra)
library(lubridate)
library(imputeTS)
library(readr)
```

### Import and clean

#### RIVR

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

##### Edit data columns

###### Format date-time string

Convert date-time string into a `POSIXct` class. This class associates
the date time string with an associated time zone. Codes for time zones
can be found
[here](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones).
Else the `as.POSIXct` function defaults to your computer’s timezone.

``` r
RIVR$Date_Time<-as.POSIXct(RIVR$Date_Time, tz="America/Edmonton")
```

##### Remove pre-deployement data

``` r
RIVR_2<- RIVR%>%
  filter(Date_Time>Date_Time_dpl)%>%
  filter(Date_Time<Date_Time_rtv)
```

##### Get daily temperature summaries

Create new calculated columns with the mean, max, and min daily
temperatures and diurnal range.

``` r
RIVR_dailys<-RIVR_2 %>% 
  mutate(Date=date(Date_Time))%>%
  dplyr::group_by(Site_StationKey,Day,Month,Year,Date, iBt_type)%>%  dplyr::mutate(Temperature=Value) %>%
  dplyr::summarize(Tmax_Day=max(Temperature),Tmin_Day=min(Temperature),Tavg_Day=mean(Temperature))%>%
  dplyr::group_by(Site_StationKey,iBt_type,Month,Year) %>% dplyr::filter(!iBt_type=="EXTRA-TOP")%>%
  arrange(Site_StationKey, Date)

save(RIVR_dailys, file="2_pipeline/store/RIVR_dailys.rData")
```

| Site_StationKey | Day | Month | Year | Date       | iBt_type | Tmax_Day | Tmin_Day | Tavg_Day |
|:----------------|----:|------:|-----:|:-----------|:---------|---------:|---------:|---------:|
| RIVR-001-01     |  28 |     5 | 2018 | 2018-05-28 | BOT      |   25.090 |   19.587 | 22.33850 |
| RIVR-001-01     |  28 |     5 | 2018 | 2018-05-28 | EXTRA    |   25.174 |   19.669 | 22.42150 |
| RIVR-001-01     |  29 |     5 | 2018 | 2018-05-29 | BOT      |   25.590 |   14.080 | 19.41956 |
| RIVR-001-01     |  29 |     5 | 2018 | 2018-05-29 | EXTRA    |   25.174 |   14.154 | 19.22189 |
| RIVR-001-01     |  30 |     5 | 2018 | 2018-05-30 | BOT      |   24.590 |   12.577 | 17.28330 |
| RIVR-001-01     |  30 |     5 | 2018 | 2018-05-30 | EXTRA    |   23.673 |   12.649 | 16.86010 |

#### HILL

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

##### Edit data columns

###### Format date-time string

Convert date-time string into a `POSIXct` class. This class associates
the date time string with an associated time zone. Codes for time zones
can be found
[here](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones).
Else the `as.POSIXct` function defaults to your computer’s timezone.

``` r
hills$Date.Time<-as.POSIXct(hills$Date.Time, tz="America/Edmonton")
```

``` r
hills_1<-hills %>%
  mutate(Value=Temperature,Month=month(Date.Time),Day=day(Date.Time),Year=year(Date.Time),
                Date_Time=Date.Time) 
```

##### Get daily temperature summaries

Create new calculated columns with the mean, max, and min daily
temperatures.

``` r
hills_dailys<-hills %>%
   mutate(Value=Temperature,Month=month(Date.Time),Day=day(Date.Time),Year=year(Date.Time),
                Date_Time=Date.Time) %>%
  mutate(Date=date(Date_Time))%>%
  dplyr::group_by(Site_StationKey,Date) %>% #group by days, month and year
  dplyr::summarize(Tmax_Day=max(Temperature),Tmin_Day=min(Temperature),Tavg_Day=mean(Temperature))%>%
  mutate(Year=year(Date))%>%
  mutate(Month=month(Date))%>%
  mutate(Day=day(Date))%>%
  dplyr::group_by(Site_StationKey,Date) 

save(hills_dailys, file="2_pipeline/store/hills_dailys.rData")
```

| Site_StationKey | Date       | Tmax_Day | Tmin_Day | Tavg_Day | Year | Month | Day |
|:----------------|:-----------|---------:|---------:|---------:|-----:|------:|----:|
| HL-1-01-1       | 2014-06-25 |   19.107 |   13.096 | 16.68667 | 2014 |     6 |  25 |
| HL-1-01-1       | 2014-06-26 |   23.611 |   11.091 | 17.71489 | 2014 |     6 |  26 |
| HL-1-01-1       | 2014-06-27 |   25.111 |   12.094 | 18.10430 | 2014 |     6 |  27 |
| HL-1-01-1       | 2014-06-28 |   25.111 |   13.096 | 18.27122 | 2014 |     6 |  28 |
| HL-1-01-1       | 2014-06-29 |   23.611 |   13.096 | 18.45520 | 2014 |     6 |  29 |
| HL-1-01-1       | 2014-06-30 |   21.610 |   13.096 | 17.00360 | 2014 |     6 |  30 |

#### Wood

Data from Wood, Wendy H; Marshall, Shawn J; Fargey, Shannon E;
Whitehead, Terri L (2017): Daily temperature data from the Foothills
Climate Array Mesonet, Canadian Rocky Mountains, 2005-2010. PANGAEA,
<https://doi.org/10.1594/PANGAEA.880611>.

``` r
wood_dailys<-read.delim(file="0_data/external/iButton/WoodEtAl/Wood_etal_2017.tab",  header=T, sep="\t", skip = 23)%>%
  rename(c(Site_StationKey=Station..FCAID., Date_Time=Date.Time, Tmin_Day=TnTnTn.day.min...C., Tmax_Day=TxTxTx.day.max...C., Tavg_Day=TTT.daily.m...C.))%>%
  select(Site_StationKey, Date_Time, Tmin_Day, Tmax_Day, Tavg_Day)%>%
  mutate(Date=date(Date_Time))%>%
  mutate(Year=year(Date))%>%
  mutate(Month=month(Date))%>%
  mutate(Day=day(Date))%>%
  select(-Date_Time)

save(wood_dailys, file="2_pipeline/store/wood_dailys.rData")
```

#### Alex

##### Clean data

``` r
# read in the individidual 2020-2021 csvs
filenames=list.files(path="0_data/external/iButton/alex/individual/2020_2021", full.names=TRUE)

library(data.table)
myMergedData <- rbindlist(sapply(filenames, fread,simplify = FALSE), idcol = 'filename')
colnames(myMergedData)[2] <- "date_time"

# check the number of site_ids per file
n_site_id<-myMergedData %>%
  group_by(filename) %>%
  mutate(n_id= n_distinct(site_id))%>%
  select(filename, n_id)%>%
  distinct()%>%
  filter(n_id== 1)

# there is a problem with a coupe of the files:
# filename                                  # of site_id's
# 4D0000006E19FA41_101321_Sept20_12PM.csv     2
# F60000006E206641_101421_Sept23_10AM.csv     497
# FC0000006E203941_101321_Sept23_10AM.csv     164

# I'll exclude these for now. 
myMergedData_2<-myMergedData %>%
    group_by(filename) %>%
    mutate(n_id= n_distinct(site_id))%>%
    ungroup()%>%
    filter(n_id == 1)%>%
    select(-n_id)%>%
    select(-filename)

# fix date and time fields 
alex_2020_2021a<-myMergedData_2%>%
  mutate(date_time=gsub("\\.","",myMergedData_2$date_time))%>%
  mutate(site_id=sub("\\(.*","",myMergedData_2$site_id))%>% # remove entore string after (
  mutate(site_id=gsub(" ", "", site_id, fixed = TRUE))%>% # remove white space
  mutate(site_id=gsub("(?<=\\d)(?=\\D)|(?<=\\D)(?=\\d)", "_", site_id, perl = TRUE)) %>% # add _ between digits and letters
  drop_na(c(date_time, date_time_deployed))%>%
  mutate(date_time_2=dmy_hm(date_time))%>%
  # mutate(date_time_3=replace_na(list(date_time_2), 0))%>%
  mutate(date_time_3 = ifelse(is.na(date_time_2), dmy_hms(date_time), date_time_2))%>%
  mutate(date_time_corrected= as_datetime(date_time_3))%>%
  # mutate(date_time_all=coalesce(date_time_2, date_time_3))%>%
  select(-c(date_time_2, date_time_3))%>%
  mutate(month=month(date_time_corrected))%>%
  mutate(day=day(date_time_corrected))%>%
  mutate(year=year(date_time_corrected))%>%
  mutate(date_time_deployed_1=dmy_hm(date_time_deployed))%>%
  mutate(date_time_deployed_2 = ifelse(is.na(date_time_deployed_1), dmy_hms(date_time_deployed), date_time_deployed_1))%>%
  mutate(date_time_deployed_corrected= as_datetime(date_time_deployed_2))%>%
  select(-c(date_time_deployed_2, date_time_deployed_1))%>%
  # mutate(date_time_deployed_1=dmy_hms(date_time_deployed))%>%
  arrange(temp_id, date_time_deployed_corrected)%>%
  filter(date_time_deployed_corrected<date_time_corrected)%>%
  distinct()%>%
  select(-c(date_time_deployed, date_time, temp_id, serial_number, location))%>%
  rename(c(Temperature=Value, Year=year, Day=day, Month=month, Date_Time=date_time_corrected,  Date_Time_dpl=date_time_deployed_corrected, Site_StationKey=site_id ))%>%
  mutate(Date=date(Date_Time))%>%
  mutate(Project="alex")%>%
  filter(placement=="tree (@ dbh)")
 

alex_cleaned<-alex_2020_2021a
save(alex_cleaned, file="2_pipeline/tmp/alex_cleaned.rData")
```

##### Get daily temperature summaries

Create new calculated columns with the mean, max, and min daily
temperatures.

``` r
alex_dailys<-alex_cleaned %>% 
  dplyr::group_by(Site_StationKey,Day,Month,Year,Date)%>%
  dplyr::summarize(Tmax_Day=max(Temperature),Tmin_Day=min(Temperature),Tavg_Day=mean(Temperature))%>% 
  dplyr::group_by(Site_StationKey,Month,Year) %>% 
  arrange(Site_StationKey, Date)

save(alex_dailys, file="2_pipeline/store/alex_dailys.rData")
```

### Combine datasets

#### **Bind dataframes**

``` r
load("2_pipeline/store/alex_dailys.rData")
load("2_pipeline/store/hills_dailys.rData")
load("2_pipeline/store/RIVR_dailys.rData")
load("2_pipeline/store/wood_dailys.rData")

ibuttons<-bind_rows("RIVR"=RIVR_dailys,"HILLS"=hills_dailys, "alex"=alex_dailys, "wood"=wood_dailys, .id="Project")

save(ibuttons, file="2_pipeline/tmp/ibuttons.rData")
```

## Create spatial objects

Use `1_code/r_notebooks/ibutton_data_xy.Rmd`.

``` r
library(sf)
library(tmap)
library(basemaps)
library(dplyr)
library(kableExtra)
library(readxl)
library(lubridate)
library(purrr)
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
  group_by(Site_StationKey)%>%
  mutate(min_year=min(Year))%>%
  mutate(max_year=max(Year))%>%
  dplyr::select(c(Project, Site_StationKey, Lat, Long, min_year, max_year))%>%
  dplyr::distinct()

RIVR_xy<-st_as_sf(RIVR_xy, coords=c("Long","Lat"), crs=4326, remove=FALSE)

# save as spatial data frame
save(RIVR_xy, file="0_data/manual/iButton_data/spatial/RIVR_xy.rData")

# save as shapefile
st_write(RIVR_xy, "0_data/manual/iButton_data/spatial/RIVR_xy.shp")
```

### HILL

**Load data**

``` r
hills<-read.csv(file="0_data/external/iButton/Hills/Hills_iButton_Data_Combined_Corrected_for_Deployment_no_extremes_Apr_27.csv")

hills_loc<-read_xlsx("0_data/external/iButton/Hills/SiteLocations/Hl_coordinates.xlsx")

load("2_pipeline/store/hills_dailys.rData")
```

#### Create spatial data frame of iButton locations

Extract XY coordinates and save as shapefile.

``` r
# create a station key column and convert to spatial object
hills_xy<-hills_loc%>%
      mutate(Site_StationKey=paste(hills_loc$ProjectID, hills_loc$Cluster, hills_loc$SITE, hills_loc$STATION, sep="-"))%>%
      inner_join(hills_dailys)%>%
      dplyr::rename(Project=ProjectID, Date_deplo=DEPLOY_DATE)%>%
      group_by(Site_StationKey)%>%
      mutate(min_year=min(Year))%>%
      mutate(max_year=max(Year))%>%
      mutate(Project="HILLS")%>%
      dplyr::select(c(Project, Site_StationKey, min_year, max_year, EASTING, NORTHING))%>%
      distinct()%>%
      st_as_sf(coords=c("EASTING","NORTHING"), crs=26911)%>% #NAD83 / UTM zone 11N
      st_transform(crs=st_crs(RIVR_xy))%>%
      mutate(Long = unlist(map(geometry,1)),
           Lat = unlist(map(geometry,2)))%>%
      select(c(Project, Site_StationKey, Lat, Long, min_year, max_year, geometry))

# save as spatial data frame
save(hills_xy, file="0_data/manual/iButton_data/spatial/hills_xy.rData")

# save as shapefile
st_write(hills_xy, "0_data/manual/iButton_data/spatial/hills_xy.shp", delete_dsn = TRUE)
```

### Wood

**Load data**

``` r
wood<-read.delim(file="0_data/external/iButton/WoodEtAl/Wood_etal_2017.tab",  header=T, sep="\t", skip = 23)
```

#### Create spatial data frame of iButton locations

Extract XY coordinates and save as shapefile.

``` r
wood_xy<-wood%>%
  mutate(Site_StationKey=Station..FCAID.)%>%
  mutate(Project="wood")%>%
  group_by(Site_StationKey)%>%
  mutate(min_year=min(year(Date.Time)))%>%
  mutate(max_year=max(year(Date.Time)))%>%
  dplyr::select(c(Project, Site_StationKey, Latitude, Longitude, min_year, max_year))%>%
  rename(c(Lat=Latitude, Long=Longitude))%>%
  dplyr::distinct()

wood_xy<-st_as_sf(wood_xy, coords=c("Long","Lat"), crs=4326, remove=FALSE)

# save as spatial data frame
save(wood_xy, file="0_data/manual/iButton_data/spatial/wood_xy.rData")

# save as shapefile
st_write(wood_xy, "0_data/manual/iButton_data/spatial/wood_xy.shp")
```

### Alex

**Load data**

``` r
load("2_pipeline/store/alex_dailys.rData")

# bring in xy data
alex_loc<-read_csv(file="0_data/external/iButton/alex/2019_and_2020_2021_plot_locations_and_elevations.csv")
```

#### Create spatial data frame of iButton locations

Extract XY coordinates and save as shapefile.

``` r
alex_xy<-alex_loc%>%
  mutate(Site_StationKey=paste(site, plot, sep="_"))%>%
  inner_join(alex_dailys)%>%
  group_by(Site_StationKey)%>%
  mutate(min_year=min(Year))%>%
  mutate(max_year=max(Year))%>%
  mutate(Project="alex")%>%
  dplyr::select(c(Project, Site_StationKey, lat, long, min_year, max_year))%>%
  rename(c(Lat=lat, Long=long))%>%
  dplyr::distinct()

alex_xy<-st_as_sf(alex_xy, coords=c("Long","Lat"), crs=4326, remove=FALSE)


alex_xy<-alex_loc%>%
  mutate(Site_StationKey=paste(site, plot, sep="_"))%>%
  inner_join(alex_dailys)%>%
  dplyr::select(Site_StationKey)%>%
  distinct()

%>%
  group_by(Site_StationKey)%>%
  dplyr::select(c(Site_StationKey, lat, long))%>%
  distinct()

10a
11a


%>%
  mutate(min_year=min(Year))%>%
  mutate(max_year=max(Year))%>%
  mutate(Project="alex")%>%
  dplyr::select(c(Project, Site_StationKey, lat, long, min_year, max_year))%>%
  rename(c(Lat=lat, Long=long))%>%
  dplyr::distinct()




# save as spatial data frame
save(alex_xy, file="0_data/manual/iButton_data/spatial/alex_xy.rData")

# save as shapefile
st_write(alex_xy, "0_data/manual/iButton_data/spatial/alex_xy.shp")
```

### All projects

``` r
ss_xy<-rbind(RIVR_xy, wood_xy, hills_xy, alex_xy)

# save as spatial data frame
save(ss_xy, file="0_data/manual/iButton_data/spatial/ss_xy.rData")

# save as shapefile
st_write(ss_xy, "0_data/manual/iButton_data/spatial/ss_xy.shp", delete_dsn = TRUE)
```

### Map study area

#### Identify study area

``` r
#create a bounding box around study area
bb<-st_bbox(ss_xy)

#Get aspect ratio of bounding box
bb<-st_as_sfc(bb)
bb<-st_as_sf(bb)
bb_buf<-st_buffer(bb, 10000)
bb_buf<-st_bbox(bb_buf)
bb_buf<-st_as_sfc(bb_buf)
bb_buf<-st_as_sf(bb_buf)

study_area<-bb_buf

# save as spatial data frame
save(study_area, file="0_data/manual/iButton_data/spatial/study_area.rData")

# save as shapefile
st_write(study_area, "0_data/manual/iButton_data/spatial/study_area.shp", delete_dsn = TRUE)
```

``` r
# Plot

# get basemap
# base<-basemap_raster(study_area, map_service = "esri", map_type = "delorme_world_base_map")
# base<-basemap_raster(study_area, map_service = "osm", map_type = "topographic")
# base<-basemap_raster(study_area, map_service = "osm_stamen", map_type = "terrain_bg")
# base<-basemap_raster(study_area, map_service = "esri", map_type = "world_shaded_relief")
base<-basemap_raster(study_area, map_service = "esri", map_type = "world_physical_map")

#alberta boundary
alberta<-st_read("0_data/external/Alberta/Alberta.shp")%>%st_transform(crs=st_crs(RIVR_xy))



# get aspect ratio of the study area (for inset map)
#asp <- (study_area$ymax - study_area$ymin)/(study_area$xmax - study_area$xmin)

mypal= c('#1b9e77','#d95f02','#7570b3','#e7298a')
# m<-tm_shape(alberta)+tm_borders()+tm_fill(col = "#fddadd")+
#   #tm_polygons(col=NA, border.col="black")+
#   tm_layout(frame=FALSE)+
#   tm_legend(outside=TRUE, frame=FALSE)+
m<-tm_shape(base)+
  tm_rgb()+
  tm_shape(ss_xy)+
    tm_symbols(col = "Project", palette = mypal, border.lwd = 0, size = .2, alpha=.8, legend.format = list(text.align="right"),
               legend.hist = TRUE)+
  tm_layout(title.size = 0.6,legend.outside = TRUE)+
tm_graticules(lines=FALSE)
  #tm_legend(position=c("left", "top"), frame=TRUE)


insetmap<-tm_shape(alberta)+tm_fill(col="lightgrey")+tm_borders(lwd=.9, col="black")+
  tmap_options(check.and.fix = TRUE)+
  tm_shape(study_area)+tm_borders(lw=2, col="red") +
  tm_layout(inner.margins = c(0.04,0.04,0.04,0.04), outer.margins=c(0,0,0,0), bg.color="transparent", frame = FALSE)
    #tm_symbols(shape = 20, alpha = .5, border.col="dimgray", size = .1, col = "black")
  #tm_legend(position=c("left", "top"), frame=TRUE)

#Get aspect ratio of bounding box
study_area_2<-st_bbox(study_area)
asp <- (study_area_2$ymax - study_area_2$ymin)/(study_area_2$xmax - study_area_2$xmin)

library(grid)
w <- .3
h <- asp * w
vp <- viewport(0.76, 0.23, width = w, height=h)
#vp <- viewport(0.9, 0.22, width = w, height=h, just=c("right", "top"))

m

tmap_save(m, "3_output/maps/ss_xy.png",  dpi=300, insets_tm=insetmap, insets_vp=vp,
          height=150, width=150, units="mm")
```

<div class="figure">

<img src="3_output/maps/ss_xy.png" alt="iButton locations." width="50%" />
<p class="caption">
iButton locations.
</p>

</div>

## Quality control

Use `1_code/r_notebooks/3_ibutton_qualityControl.Rmd`.

``` r
library(tidyr)
library(plyr)
library(dplyr)
library(kableExtra)
library(lubridate)
library(imputeTS)
library(readr)
library(stringr)
library(ggplot2)
```

``` r
# load ibutton daily summaries
load("2_pipeline/tmp/ibuttons.rData")
```

### Remove months with incomplete data

Removing first month of data if it has only 20 days or less.

``` r
ibuttons_1<- ibuttons%>% ungroup()%>%split(f=.$Site_StationKey) %>% lapply(FUN=function(x){
  if (x %>% filter(month(Date)==month(min(Date))& year(Date)==min(year(Date))) %>%
      summarize(max(Day)-min(Day)) %>% c () < 20 ){
    y<-x %>% filter(month(Date)>month(min(Date))| year(Date)> min(year(Date)))    
    
    return(y)
  }else{
    return(x)
  }
}) 
```

Removing last month of data if it has only 20 days or less.

``` r
ibuttons_2<-ibuttons_1 %>% lapply(FUN=function(x){
  if (x %>% filter(month(Date)==month(max(Date))& year(Date)==max(year(Date))) %>% 
      summarize(max(Day)-min(Day)) %>% c () < 20 ){
    y<-x %>% filter(month(Date)<month(max(Date))| year(Date)< max(year(Date)))    
    #y<-x[!(month(x$Date)==month(min(x$Date) & year(x$Date)==min(year(x$Date)))),]
    return(y)
  }else{
    return(x)
  }
  
}) %>% do.call(rbind,.) #working
```

### Calculate the difference bewteen ERA5 and iButton temps

Import ERA 5 daily summaries calculated in google earth engine.

``` r
ERA5_d<-read_csv("0_data/manual/gee_tables/ibutton_timeSeries_ERA5_daily.csv")

# convert kelvin to celsius

ERA5_d2<-ERA5_d%>%
  mutate(ERA5_temp_mean= mean_2m_air_temperature-273.15)%>%
  mutate(ERA5_temp_max= maximum_2m_air_temperature-273.15)%>%
  mutate(ERA5_temp_min= minimum_2m_air_temperature-273.15)%>%
  dplyr::rename(c(Year=year, Month=month, Day=day, Site_StationKey=St_SttK))%>%
  select(Site_StationKey, Year, Month, Day, ERA5_temp_max, ERA5_temp_min, ERA5_temp_mean)
```

Calculate difference between ibutton and ERA5 temperatures

``` r
ibuttons_ERA5<-ibuttons_2%>%
  left_join(ERA5_d2, by = c("Site_StationKey", "Day", "Month", "Year"))%>%
  mutate(Tmax_dif=ERA5_temp_max-Tmax_Day)%>%
  mutate(Tavg_dif=ERA5_temp_mean-Tavg_Day)%>%
  mutate(Tmin_dif=ERA5_temp_min-Tmin_Day)%>%
  filter(is.na(iBt_type)|iBt_type!="EXTRA")%>%
  # add season columns
  mutate(season_4 = case_when(
      Month %in%  9:11 ~ "Fall",
      Month %in%  c(12, 1, 2)  ~ "Winter",
      Month %in%  3:5  ~ "Spring",
      TRUE ~ "Summer"))%>%
  mutate( season_2 = case_when(
      Month %in%  c(10:12, 1, 2,3) ~ "Winter",
      TRUE ~ "Summer"))
```

### Remove outliers

``` r
#remove outliers 

ibuttons_ERA5_2<-ibuttons_ERA5%>%
# remove extreme values
    filter(Tmax_Day< 50)%>%
# remove outliers based on sd
    group_by(Site_StationKey, season_2) %>%
    filter(between(Tmax_Day, mean(Tmax_Day)-(3*sd(Tmax_Day)), mean(Tmax_Day)+(3*sd(Tmax_Day))))%>%
    filter(between(Tmin_Day, mean(Tmin_Day)-(3*sd(Tmin_Day)), mean(Tmin_Day)+(3*sd(Tmin_Day))))%>%
    filter(between(Tavg_Day, mean(Tavg_Day)-(3*sd(Tavg_Day)), mean(Tavg_Day)+(3*sd(Tavg_Day))))%>%
    ungroup()%>%
    filter(is.na(Tmax_dif)|between(Tmax_dif, mean(Tmax_dif,  na.rm=TRUE)-(3*sd(Tmax_dif, na.rm=TRUE)), mean(Tmax_dif,  na.rm=TRUE)+(3*sd(Tmax_dif, na.rm=TRUE))))%>%
filter(is.na(Tmin_dif)|between(Tmin_dif, mean(Tmin_dif,  na.rm=TRUE)-(3*sd(Tmin_dif, na.rm=TRUE)), mean(Tmin_dif,  na.rm=TRUE)+(3*sd(Tmin_dif, na.rm=TRUE))))%>%
filter(is.na(Tavg_dif)|between(Tavg_dif, mean(Tavg_dif,  na.rm=TRUE)-(3*sd(Tavg_dif, na.rm=TRUE)), mean(Tavg_dif,  na.rm=TRUE)+(3*sd(Tavg_dif, na.rm=TRUE))))


## remove outliers based on interquartile range
# 
# d1<-d %>%
#     group_by(Site_StationKey, season_2) %>%
#     filter(between(Tmax_Day, quantile(Tmax_Day, .25, )-(3*IQR(Tmax_Day)), quantile(Tmax_Day, .75, )+(3*IQR(Tmax_Day))))%>%
#     filter(between(Tmin_Day, quantile(Tmin_Day, .25, )-(3*IQR(Tmin_Day)), quantile(Tmin_Day, .75, )+(3*IQR(Tmin_Day))))%>%
#     filter(between(Tavg_Day, quantile(Tavg_Day, .25, )-(3*IQR(Tavg_Day)), quantile(Tavg_Day, .75, )+(3*IQR(Tavg_Day))))%>%
#     ungroup()%>%
#     filter(is.na(Tmax_dif)|between(Tmax_dif, quantile(Tmax_dif, .25, na.rm=TRUE)-(3*IQR(Tmax_dif, na.rm=TRUE)), quantile(Tmax_dif, .75, na.rm=TRUE)+(3*IQR(Tmax_dif, na.rm=TRUE))))%>%
# filter(is.na(Tmin_dif)|between(Tmin_dif, quantile(Tmin_dif, .25, na.rm=TRUE)-(3*IQR(Tmin_dif, na.rm=TRUE)), quantile(Tmin_dif, .75, na.rm=TRUE)+(3*IQR(Tmin_dif, na.rm=TRUE))))%>%
# filter(is.na(Tavg_dif)|between(Tavg_dif, quantile(Tavg_dif, .25, na.rm=TRUE)-(3*IQR(Tavg_dif, na.rm=TRUE)), quantile(Tavg_dif, .75, na.rm=TRUE)+(3*IQR(Tavg_dif, na.rm=TRUE))))

  
save(ibuttons_ERA5_2, file="2_pipeline/tmp/ibuttons_ERA5_2.rData")
```

### Impute missing data

#### Create a dummy iButton data frame

The data frame will have rows for every day during the time period the
iButtons were deployed. Daily temperature columns will be filled with NA
values.

Create a calendar for the time iButtons were deployed.

``` r
ibuttons_ERA5_3<-ibuttons_ERA5_2%>%
  mutate(project_year=str_c(Project, "_", Year))%>%
  mutate(project_year_month=str_c(Project, "_", Year, "_", Month))%>%
  select("Project","Site_StationKey", "Day", "Month","Year", "project_year", "project_year_month", "Date", "iBt_type",  "Tmax_Day","Tmin_Day",  "Tavg_Day")

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
calendar_1<-calendar %>% `names<-`(days$Month) %>% unlist() %>% as.data.frame() %>%
  `colnames<-`("Day") %>% mutate(Month_name=substr(rownames(.),1,3)) %>%
  left_join(data.frame(Month_name=month.abb,Month=months)) %>%
  expand_grid(.,Year=c(min(ibuttons_ERA5_3$Year):max(ibuttons_ERA5_3$Year)))%>%
  mutate(Date = dmy(paste(Day, Month, Year, sep = "/")))
```

Create the dummy data frame that includes all of the days/year of the
above calendar data frame with NA instead of temperature values.

``` r
calendar_2<-ibuttons_ERA5_3%>%
  ungroup%>%
  select(Site_StationKey, Project)%>%
  unique() %>%
 `colnames<-` (c("Site_StationKey","Project")) %>%
  expand_grid(.,calendar_1)%>% mutate(iBt_type=NA,Tmax_Day=NA,Tmin_Day=NA,Tavg_Day=NA)%>%
  mutate(project_year_month=str_c(Project, "_", Year, "_", Month))%>%
  filter(project_year_month%in% unique(ibuttons_ERA5_3$project_year_month))%>%
  select(-c(iBt_type))%>%
  arrange(Site_StationKey, Year, Month, project_year_month, Project)
```

Add days with missing data to ibutton dataframe

``` r
# add days with missing data to ibutton dataframe
complete_data_w_missing<-calendar_2 %>% ungroup() %>% 
  select(-c(Tmax_Day, Tmin_Day, Tavg_Day)) %>%
  left_join(ibuttons_ERA5_3)%>%
  distinct()
```

#### Impute missing values

Impute NA values using a spline function based on time series
imputation. The imputation is based on month per year per iButton site.

``` r
ibuttons_complete_daily<-complete_data_w_missing %>%
  arrange(Site_StationKey, Date)%>%
  select(-Month_name)%>%
  # group_by(Site_StationKey,Year, Month) %>%
  group_by(Site_StationKey) %>%
  # group_modify(~ na.trim(.)) %>%  remove the NA's at the beginning and end of each group.
  mutate(Tmax_Day_int = na_interpolation(Tmax_Day, option="linear", maxgap = 10))%>%
  mutate(Tmin_Day_int = na_interpolation(Tmin_Day, option="linear", maxgap = 10))%>%
  mutate(Tavg_Day_int = na_interpolation(Tavg_Day, option="linear", maxgap = 10))%>%
  mutate(imputed= ifelse(is.na(Tmax_Day), "yes", "no"))%>%
  select(-c(Tmax_Day, Tmin_Day, Tavg_Day))%>%
  rename(Tmax_Day =Tmax_Day_int, Tmin_Day =Tmin_Day_int, Tavg_Day =Tavg_Day_int,)

  
#save
save(ibuttons_complete_daily, file="0_data/manual/iButton_data/ibuttons_complete_daily.rData")

write.csv(ibuttons_complete_daily, file="0_data/manual/iButton_data/ibuttons_complete_daily.csv")
```

### Compare imputed values with ERA5 dailys

``` r
ibuttons_ERA5_4<-ibuttons_complete_daily%>%
  left_join(ERA5_d2, by = c("Site_StationKey", "Day", "Month", "Year"))%>%
  mutate(Tmax_dif=ERA5_temp_max-Tmax_Day)%>%
  mutate(Tavg_dif=ERA5_temp_mean-Tavg_Day)%>%
  mutate(Tmin_dif=ERA5_temp_min-Tmin_Day)%>%
  mutate(T_diurnal=Tmax_Day-Tmin_Day)%>%
  mutate(Date = make_date(Year, Month, Day))%>%
  mutate(season_4 = case_when(
      Month %in%  9:11 ~ "Fall",
      Month %in%  c(12, 1, 2)  ~ "Winter",
      Month %in%  3:5  ~ "Spring",
      TRUE ~ "Summer"))%>%
  mutate( season_2 = case_when(
      Month %in%  c(10:12, 1, 2,3) ~ "Winter",
      TRUE ~ "Summer"))
```

### Monthly summaries

#### Snow burial

We defined snow burial as ibuttons with a diural range of \<3 degrees
for 25 consequetive days or more. ([Wood et al.
2017](#ref-wood2017dtdf))

``` r
#define how may consecutive days are needed to define as snow
snow_thresh<-25

# Flag snow burials
ibuttons_ERA5_5<-ibuttons_ERA5_4%>%
  filter(T_diurnal<3)%>% #filter to diurnal range <3
  # mutate(lag_date=Date - days(1))%>%
  group_by(Site_StationKey)%>%
  arrange(Site_StationKey, Date)%>%
  # mutate(consecutive_day_flag = if_else(Date == (Date - days(1), 1, 0))%>%
  mutate(lag_date=lag(Date))%>%
  mutate(consecutive_day_flag = if_else(Date == (lag(Date) + days(1)), 1, 0))%>% # flag consecutive days
  mutate(consecutive_day_flag =replace_na(consecutive_day_flag, 0))%>%# flag consecutive days
  mutate(snow_burial=rep(rle(consecutive_day_flag)$length>=snow_thresh,rle(consecutive_day_flag)$length))%>% #flag dates that are a part of  sequence
  right_join(ibuttons_ERA5_4)%>% # join back with the original data frame
  mutate(snow_burial=replace_na(snow_burial, "FALSE"))%>%
  select(-c(consecutive_day_flag, lag_date))%>%
  arrange(Site_StationKey, Date)%>%
# Replace flaged snow burials with NA  
  mutate(Tmax_Day= ifelse(snow_burial=="TRUE", NA, Tmax_Day))%>%
  mutate(Tmax_Day= ifelse(snow_burial=="TRUE", NA, Tmin_Day))%>%
  mutate(Tmax_Day= ifelse(snow_burial=="TRUE", NA, Tavg_Day))
```

#### Remove months with more than 10 missing days

``` r
ibuttons_ERA5_6<-ibuttons_ERA5_5%>% 
  group_by(Project, Site_StationKey,Month,Year) %>%
  dplyr::summarize(count_na = sum(is.na(Tmax_Day)))%>%
  right_join(ibuttons_ERA5_5 ,by=c("Project", "Site_StationKey","Month","Year"))%>%
  filter(count_na<10)


save(ibuttons_ERA5_6, file="2_pipeline/tmp/ibuttons_ERA5_6.rData")
```

#### Calculate monthly summaries

``` r
load("2_pipeline/tmp/ibuttons_ERA5_6.rData")


ibuttons_complete_monthly<-ibuttons_ERA5_6%>%
        group_by(Project, Site_StationKey,Month,Year)%>%
        summarise(across(c(Tmax_Day, Tmin_Day, Tavg_Day), mean, na.rm=T))%>%
        rename(c(Tmax_Month=Tmax_Day, Tmin_Month=Tmin_Day, Tavg_Month=Tavg_Day))%>%
        arrange(Site_StationKey, Year, Month)

save(ibuttons_complete_monthly, file="0_data/manual/iButton_data/ibuttons_complete_monthly.rData")

write.csv(ibuttons_complete_monthly, file="0_data/manual/iButton_data/ibuttons_complete_monthly.csv")
```

| Project | Site_StationKey | Month | Year | Tmax_Month | Tmin_Month | Tavg_Month |
|:--------|:----------------|------:|-----:|-----------:|-----------:|-----------:|
| alex    | 10_B            |     8 | 2020 | 15.1375202 |   7.590323 | 15.1375202 |
| alex    | 10_B            |     9 | 2020 |  9.2781417 |   0.669900 |  9.2781417 |
| alex    | 10_B            |    10 | 2020 | -0.9454788 |  -7.544984 | -0.9454788 |
| alex    | 10_B            |    11 | 2020 | -5.8728336 | -12.753017 | -5.8728336 |
| alex    | 10_B            |    12 | 2020 | -6.4046382 | -11.100516 | -6.4046382 |
| alex    | 10_B            |     1 | 2021 | -4.8055731 |  -7.046516 | -4.8055731 |

### Difference between monthly summaries

``` r
ERA5_m<-read_csv("0_data/manual/gee_tables/ibutton_timeSeries_ERA5_monthly.csv")

 # convert kelvin to celsius

ERA5_m2<-ERA5_m%>%
  mutate(ERA5_temp_mean= mean_2m_air_temperature-273.15)%>%
  mutate(ERA5_temp_max= maximum_2m_air_temperature-273.15)%>%
  mutate(ERA5_temp_min= minimum_2m_air_temperature-273.15)%>%
  rename(c(Year=year, Month=month, Site_StationKey=St_SttK))%>%
  select(Site_StationKey, Year, Month, ERA5_temp_max, ERA5_temp_min, ERA5_temp_mean)


ibutton_timeSeries_ERA5_monthly_2<-ibuttons_complete_monthly%>%
  left_join(ERA5_m2, by = c("Site_StationKey", "Month", "Year"))%>%
  mutate(Tmax_dif_m=ERA5_temp_max-Tmax_Month)%>%
  mutate(Tavg_dif_m=ERA5_temp_mean-Tavg_Month)%>%
  mutate(Tmin_dif_m=ERA5_temp_min-Tmin_Month)%>%
  # filter(is.na(iBt_type)|iBt_type!="EXTRA")%>%
  # add season columns
  mutate(season_4 = case_when(
      Month %in%  9:11 ~ "Fall",
      Month %in%  c(12, 1, 2)  ~ "Winter",
      Month %in%  3:5  ~ "Spring",
      TRUE ~ "Summer"))%>%
  mutate( season_2 = case_when(
      Month %in%  c(10:12, 1, 2,3) ~ "Winter",
      TRUE ~ "Summer"))

hist(ibutton_timeSeries_ERA5_monthly_2$Tavg_dif_m)
hist(ibutton_timeSeries_ERA5_monthly_2$Tmin_Month)
hist(ibutton_timeSeries_ERA5_monthly_2$ERA5_temp_min)
```

------------------------------------------------------------------------

# ClimateNA data

Use `1_code/r_notebooks/get_climateNA.Rmd`

## Setup

**Install `ClimateNAr`**

Get the latest ClimateBC/NA r package by registering at a
<https://register.climatena.ca/>. Follow the instructions to install the
`ClimateNAr` package.

``` r
library(ClimateNAr)
library(dplyr)
library(sf)
library(tidyr)
library(stringr)
```

Download the ClimateNA desktop application and r package here:
<https://register.climatena.ca/>

Instructions on how use the ClimateNA application can be found here:
<https://pressbooks.bccampus.ca/fode010notebook/chapter/topic-3-2-the-use-of-climatena-ap-to-generate-point-and-spatial-climate-data/>

The climateNA desktop application was designed for PC, but can be used
on Mac by using Wine. To get climateNA working on my machine I used a
Wineskin (<https://github.com/Gcenx/WineskinServer>) to create an
application wrapper. The wrapper used the WS10Wine64Bit5.20 wine engine.
I also installed `vb6run` with winetricks to get the application
working. The the wine wrapper should contain the entire `climateNA_v730`
folder directory, not just the `ClimateNA_v7.30.exe` file.

While climateNA can be run via commandline using R, I was not able to
get this working on my Mac. I included code for integrating climateNA
into the R workflow on PC’s (\[Extract CLimateNA monthly summaries with
R \]). However, the R code is untested.

## Create input file

ClimateNAr requires a properly formatted .csv input file that includes
the following headers: ID1, ID2, lat, long, el

1.  Bring in iButton data\*\*

``` r
# load("0_data/manual/iButton_data/ibuttons_complete_monthly.rData")
load("0_data/manual/iButton_data/spatial/ss_xy.rData")

# add month and year columns to the ibutton spatial dataframe
# ibutton<-ss_xy%>%
#       left_join(ibuttons_complete_monthly)%>%
#       select(Project, Site_StationKey, Month, Year)
```

2.  Bring in the elevation data extracted via Google Earth Engine.

``` r
elev<-read.csv("0_data/manual/gee_tables/ibutton_terrain.csv")
elev$Project[elev$Project== "WOOD"] <- "wood"
elev$Project[elev$Project== "HL"] <- "HILLS"
```

3.  Join elevation data to the iButton spatial data frame.

``` r
load("0_data/manual/iButton_data/spatial/ss_xy.rData")

climateNA_input<- ss_xy%>%
    left_join(elev, by=c('Project'='Project', 'Site_StationKey'='St_SttK'))%>%
    as.data.frame()%>%
    select(Project, Site_StationKey, Lat, Long, elevation)%>%
    rename(c(ID1=Project, ID2=Site_StationKey, lat=Lat, long=Long, el=elevation))%>%
    drop_na()

write.csv(climateNA_input, file="0_data/manual/climateNA/input/climateNA_input.csv", row.names = FALSE)  
```

## Extract ClimateNA summaries

I used the ClimateNA GUI to extract monthly climate summaries. There is
a weird bug on my mac ClimateNA application where I need to open and
save the input .csv in excel before ClimateNA can read it.

In the desktop application I selected a `Historical Time Series` of
`Monthly primary variables (60)`

Climate data is exported back into the rProject as a .csv file in
`0_data/manual/climateNA/output/`

### Read in the ClimateNA summaries

``` r
cna<-read.csv(file="0_data/manual/climateNA/output/climateNA_input_2005-2021MP.csv")
  
cNA_month_summaries<-cna%>%
  rename(c(Project=ID1, Site_StationKey=ID2))%>%
  dplyr::select(c(Year:Tave12))%>%
  gather(key="Month_a", value="Tmax_cNA", "Tmax01":"Tmax12")%>%
  mutate(Month_a=(gsub("[^0-9.-]", "", Month_a))) %>%
  gather(key="Month_b", value="Tmin_cNA", "Tmin01":"Tmin12")%>%
  mutate(Month_b=(gsub("[^0-9.-]", "", Month_b))) %>%
  gather(key="Month_c", value="Tavg_cNA", "Tave01":"Tave12")%>%
  mutate(Month_c=(gsub("[^0-9.-]", "", Month_c))) %>%
  filter(Month_a==Month_b & Month_b==Month_c)%>%
  dplyr::select(Project, Site_StationKey, Year, Month_a, Tmax_cNA, Tmin_cNA, Tavg_cNA)%>%
  rename(Month=Month_a)%>%
  mutate(Month=as.numeric(str_remove(Month, "^0+")))%>%
  arrange(Site_StationKey, Year, Month)

save(cNA_month_summaries, file="0_data/manual/climateNA/processed/cNA_month_summaries.rData")
write.csv(cNA_month_summaries, file="0_data/manual/climateNA/processed/cNA_month_summaries.csv")
```

``` r
load("0_data/manual/climateNA/processed/cNA_month_summaries.rData")
knitr::kable(head(cNA_month_summaries), "pipe") 
```

| Project | Site_StationKey | Year | Month | Tmax_cNA | Tmin_cNA | Tavg_cNA |
|:--------|:----------------|-----:|------:|---------:|---------:|---------:|
| alex    | 10_B            | 2005 |     1 |    -12.0 |    -23.1 |    -17.5 |
| alex    | 10_B            | 2005 |     2 |     -2.6 |    -16.7 |     -9.7 |
| alex    | 10_B            | 2005 |     3 |      2.7 |     -9.1 |     -3.2 |
| alex    | 10_B            | 2005 |     4 |     11.3 |     -2.5 |      4.4 |
| alex    | 10_B            | 2005 |     5 |     17.0 |      1.8 |      9.4 |
| alex    | 10_B            | 2005 |     6 |     18.9 |      6.4 |     12.6 |

### Extract ClimateNA monthly summaries directly with R

I have not been able to get this working on my Mac, but it should work
on PC’s (untested).

``` r
library(ClimateNAr)
#Inputs
#ClimateNA executable
c<-"ClimateNA_v7.30.exe"
#input directory
#e.g."/C:\\Users\\kimorris\\ClimateNA_v730\\ibutton\\"
#data<-'/C:\\Users\\kimorris\\ClimateNA_v730\\ibutton\'
#Automated
maxYear<-max(tmax2$year)
minYear<-min(tmax2$year)
for (y in seq(minYear,maxYear)){
  #loop through for each year
  setwd(climNA_dir);getwd() # it must be the home directory of ClimateNA
  exe <- c
  #inputFile = paste0(data,"temp_input.csv") #find way to change exported file location earlier into format needed here?
  #outputFile = paste0(data,"temp_input_Year_",y,"MP.csv")
  inputFile = paste0("/C:\\Users\\kimorris\\ClimateNA_v730\\ibutton\temp_input.csv") #find way to change exported file location earlier into format needed here?
  outputFile = paste0("/C:\\Users\\kimorris\\ClimateNA_v730\\ibutton\temp_input.csv","temp_input_Year_",y,"MP.csv")
  yearPeriod = paste0('/Year_',y,'.ann')
  system2(exe,args= c('/Y', yearPeriod, inputFile, outputFile)) 
  #dat <- read.csv('C:/Users/kimorris/ClimateNA_v730/ibutton/temp_output.csv'); head(dat) 
}

maxYear<-max(tmax2$year)
minYear<-min(tmax2$year)
ib_clim<-NULL
for (y in seq(minYear,maxYear)){
  file<-paste0(working_dir,"temp_input_Year_",y,"MP.csv")
  print(file)
  t<-read.csv(file)
  print(head(t))
  tt<-subset(t,select=c("ID1","ID2","Latitude","Longitude","Elevation", "Tmax01","Tmax02","Tmax03","Tmax04","Tmax05","Tmax06","Tmax07","Tmax08","Tmax09","Tmax10","Tmax11","Tmax12"))
  print(head(tt))
  t_long <- melt(setDT(tt), id.vars = c("ID1","ID2","Latitude","Longitude","Elevation"), variable.name = "month")
  print(head(t_long))
  #select only needed columns
  t_long2<-subset(t_long,select=c("ID1","month","value"))
  #parse month from Tmax01 etc
  t_long2$month<-str_sub(t_long2$month, start= -2)
  #name value column ClimNATmax
  colnames(t_long2)<-c("group","month","climNA_tmax")
  #remove leading 0's on month
  t_long2$month<-sub("^0+", "",t_long2$month)
  #head(t_long2)
  #table(t_long2$month)
  #merge with tmax2
  t_tmax<-subset(tmax2,year==y)
  #table(t_tmax$month)
  t_tmax2<-merge(t_tmax,t_long2,by=c("group","month"))
  #head(t_tmax2)
  #table(t_tmax2$month)
  #nrow(t_tmax2)
  #nrow(t_tmax)
  ##merge years as it loops through them
  ib_clim<-rbind(ib_clim,t_tmax2)
}
```

## Calculate difference between iButton and ClimateNA summaries

``` r
# ClimateNA monthly summaries
load("0_data/manual/climateNA/processed/cNA_month_summaries.rData")

# ibBtton monthly summaries
load("0_data/manual/iButton_data/ibuttons_complete_monthly.rData")

iButton_cNA_diff<-ibuttons_complete_monthly%>%
  left_join(cNA_month_summaries, by=c("Project", "Site_StationKey", "Year", "Month"))%>%
  mutate(Tmax_diff=round(Tmax_cNA-Tmax_Month, 2))%>%
  mutate(Tmin_diff=round(Tmin_cNA-Tmin_Month, 2))%>%
  mutate(Tavg_diff=round(Tavg_cNA-Tavg_Month, 2))%>%
  na.omit

# Plot 
iButton_cNA_diff%>%
  ggplot(aes(x=Tavg_cNA, y=Tavg_Month)) +
  geom_point(alpha=.5)

iButton_cNA_diff%>%toronto
  ggplot(aes(x=Tavg_diff)) +
  geom_histogram(aes(y=..density..), colour="black", fill="white", binwidth = .5)+
   geom_density(alpha=.2, fill="#FF6666") 

# over time
iButton_cNA_diff %>%
    mutate(date = lubridate::ymd(paste(Year, Month, 1)))%>%
  filter(Tavg_diff>-5)%>%
  ggplot(aes(date, Tmax_Month, group=Site_StationKey)) +
  geom_line(alpha=0.2) +
  scale_x_date(date_labels = "%b %Y", date_breaks = "1 month")+
  theme_bw()+
  theme(axis.text.x = element_text(angle = 90, vjust=0.5), 
        panel.grid.minor = element_blank())

# Save 
# iButton_cNA_diff<-iButton_cNA_diff%>%
#   dplyr::select("Project","Site_StationKey","Month","Year", "Tmax_diff", "Tmin_diff", "Tavg_diff" )

save(iButton_cNA_diff, file="0_data/manual/iButton_data/iButton_cNA_diff.rData")
```

------------------------------------------------------------------------

# Spatial covariates

Spatial covariates were extracted using Google Earth Engine’s online
code editor at
[code.earthengine.google.com](http://code.earthengine.google.com/).

Download the Google Earth Engine script by using
`git clone https://earthengine.googlesource.com/users/bgcasey/climate_downscaling`
into your working directory.

Use `1_code/r_notebooks/5_covariates_gee_spatial.Rmd`.

``` r
library(dplyr)
library(readr)
```

## GEE scripts

Bring GEE scripts into the current rProject by cloning the GEE git and
copying over the .js files.

``` bash
# set directory to clone GEE git into (should be empty)
cd 1_code/GEE

# delete all .js files in directory
rm *.js

# clone gee scripts
git clone https://earthengine.googlesource.com/users/bgcasey/climate_downscaling


# add the .js file extention to files
find climate_downscaling -type f -not -name "*.*" -exec mv "{}" "{}".js \;

# move .js files up a directory
mv -v climate_downscaling/*.js .

# move functions folder up a directory
mv -v climate_downscaling/functions/ .

# delete .git folder
rm -r climate_downscaling/
```

## GEE CSVs

``` r
gee_cov_all<-read_csv("0_data/manual/gee_tables/ibutton_all_indices.csv")
gee_cov_all$Project[gee_cov_all$Project== "WOOD"] <- "wood"
gee_cov_all$Project[gee_cov_all$Project== "HL"] <- "HILLS"
gee_cov_all<-rename(gee_cov_all, c("Site_StationKey" = "St_SttK", "Month"="month", "Year"= "year", "tree_coverfraction"="tree-coverfraction"))

### add latitude
load("0_data/manual/iButton_data/spatial/ss_xy.rData")

library(sf)

gee_cov_all<-dplyr::left_join(gee_cov_all, ss_xy, by = c("Project", "Site_StationKey"))%>%
  dplyr::select(-c(Long, min_year, max_year, geometry))

save(gee_cov_all, file="0_data/manual/gee_tables/gee_cov_all.rData")
```

### Join with response variable

``` r
load("0_data/manual/iButton_data/iButton_cNA_diff.rData")

data_full<-left_join(iButton_cNA_diff, gee_cov_all, by=c("Project", "Site_StationKey", "Month", "Year"))%>%
  dplyr::select(-date)%>%
  as.data.frame()
```

### Add season column

``` r
data_full<-data_full%>%
 mutate(season_4 = case_when(
      Month %in%  9:11 ~ "Fall",
      Month %in%  c(12, 1, 2)  ~ "Winter",
      Month %in%  3:5  ~ "Spring",
      TRUE ~ "Summer"))%>%
  mutate(season_2 = case_when(
      Month %in%  c(10:12, 1, 2,3) ~ "Winter",
      TRUE ~ "Summer"))

save(data_full, file="0_data/manual/formatted_for_models/data_full.rData")

write.csv(data_full, file="0_data/manual/formatted_for_models/data_full.csv", row.names = FALSE)  
```

## GEE Rasters

``` r
library(raster)
library(terra)
library(dplyr)
library(foreach)
library(stringr)
library(sf)
```

**Import and process GEE rasters**

The following code chunk:

1.  Imports raster tiles generated using Google Earth Engine.
2.  Stitches them together into a single continuous raster using the
    `raster::mosaic` function.
3.  Crops the continuous raster to the study area.
4.  Saves the raster as a .tif file.

``` r
# Load study area
study_area<-st_read("../Data/Canada/alberta_bc")

# dataPath <- "/Volumes/GoogleDrive/My Drive/PhD/thesis/chapter_1/empirical/0_data/external/CL_LiDAR/grid_metrics_surfaces/"
path_name<-"0_data/external/GEE_rasters/to_process/"

bl<-list.dirs(path=path_name, full.names = F, recursive = F)

#set temp directory to an external drive to free up harddrive space
rasterOptions(tmpdir=file.path("../r_tmp")) 

foreach (j = 1:length(bl)) %do%
{
  t1 = proc.time()
  print(paste("---- Begin",bl[j], Sys.time()))
  #list .tif files in the folder
  fl <- list.files(path=paste0(path_name, bl[j]), pattern = '*.tif$', recursive = T, full.names = T)
  print(paste("----",bl[j]," file scan complete", Sys.time()))
  # If multibabnd rasters, read each file into R as a raster brick. Use raster function if   single band rasters
  fl <- lapply(fl, brick)
  print(paste("----",bl[j]," lapply raster::brick  complete", Sys.time()))
  # set mosaic parameters
  fl$fun <- mean
  fl$tolerance <-.5
  x <- do.call(raster::mosaic, fl)
  # rename the raster bands. For multiband rasters, the band names are lost during mosaicing
  names(x)<-names(fl[[]]) # name mosaic bands
  names(x)<-gsub("_mean", "",names(x))
  print(paste("----",bl[j]," mosaic complete!", Sys.time()))
  x<-raster::crop(x, study_area) # crop raster to study area
  print(paste("----",bl[j]," crop complete", Sys.time()))
  x<-terra::rast(x) # preserve band names when savinbg by converting the stack to a rast object from the terra package.
  writeRaster(x, filename=paste0("0_data/manual/raster_mosaics/",bl[j], ".tif"),  overwrite=T)
  print(paste("----",bl[j]," saved as TIFF", Sys.time()))
  print("process time")
  print(proc.time() - t1)
  removeTmpFiles(0) #The raster package can store a lot of files. This removes any temp raster files generated   during the loop
}



#######################################


# foreach (j = 1:length(bl)) %do%
# {
#   t1 = proc.time()
#   print(paste("---- Begin",bl[j], Sys.time()))
#   #list .tif files in the folder
  fl <- list.files(path=paste0(path_name, bl[2]), pattern = '*.tif$', recursive = T, full.names = T)
  print(paste("----",bl[j]," file scan complete", Sys.time()))
  # If multibabnd rasters, read each file into R as a raster brick. Use raster function if   single band rasters
  fl <- lapply(fl, brick)
  print(paste("----",bl[j]," lapply raster::brick  complete", Sys.time()))
  # set mosaic parameters
  fl$fun <- mean
  fl$tolerance <-.5
  x <- do.call(raster::mosaic, fl)
  # rename the raster bands. For multiband rasters, the band names are lost during mosaicing
  names(x)<-names(fl[[]]) # name mosaic bands
  names(x)<-gsub("_mean", "",names(x))
  print(paste("----",bl[j]," mosaic complete!", Sys.time()))
  x<-raster::crop(x, study_area) # crop raster to study area
  print(paste("----",bl[j]," crop complete", Sys.time())) 
  x<-terra::rast(x) # preserve band names when savinbg by converting the stack to a rast object from the terra package.
  writeRaster(x, filename=paste0("0_data/manual/raster_mosaics/",bl[j], ".tif"),  overwrite=T)
  print(paste("----",bl[j]," saved as TIFF", Sys.time()))
  print("process time")
  print(proc.time() - t1)
  removeTmpFiles(0) #The raster package can store a lot of files. This removes any temp raster files generated   during the loop
}
```

## Setup data for GBM

Set up a data frame to be used by the `gbm` function. It will only have
the predictor and response variables.

``` r
load("0_data/manual/formatted_for_models/data_full.rData")

df<-data_full%>%
  mutate(season_2=as.factor(season_2))%>%
  mutate(season_4=as.factor(season_4))

df1<-df%>%
dplyr::select(Tmax_diff, Tmin_diff, Tavg_diff, NDVI, NDMI, LAI, TWI, elevation, slope, HLI, tpi_50, tpi_500, northness, snow, NDSI, pr, srad, vs, soil, canopy_height, canopy_standard_deviation, tree_coverfraction, cloud_fraction, discrete_classification, forest_type, CHILI, Month, season_4)
```

### Check for multicollinearity between predictors

``` r
pairs_cov <-df1[c(4:23, 26)]

#visualize with corrplot. Easier to visualize with a lot of variables
M<-cor(pairs_cov, method = "pearson", use="pairwise.complete.obs")
corrplot(M, tl.cex=0.5, method="number", type ="upper", addCoefasPercent=TRUE, order = "hclust", number.cex=.5, cl.cex=.5
)

# remove highly correlated variables
#compare correlated predictors in univariate models
m1<-lm(Tavg_diff~snow, data=df1)
m2<-lm(Tavg_diff~NDSI, data=df1)
m3<-lm(Tavg_diff~CHILI, data=df1)
m4<-lm(Tavg_diff~HLI, data=df1)
m5<-lm(Tavg_diff~tree_coverfraction, data=df1)
m6<-lm(Tavg_diff~canopy_height, data=df1)

df2<-df1%>%
  dplyr::select(-c(NDSI, tree_coverfraction, HLI ))

data_sub<-df2
save(data_sub, file="0_data/manual/formatted_for_models/data_sub.rData")
```

------------------------------------------------------------------------

# Modelling

## Boosted regression trees

Use `1_code/r_notebooks/modelling_data_exploration.Rmd`.

``` r
library(dismo)
library(gbm)
library(dplyr)
# library(caret)        # an aggregator package for performing many machine learning models
library(corrplot)
library(stringr)

load("0_data/manual/formatted_for_models/data_sub.rData")

data_sub_summer<-data_sub%>%
  filter(season_4=="Summer")
data_sub_winter<-data_sub%>%
  filter(season_4=="Winter")
data_sub_fall<-data_sub%>%
  filter(season_4=="Fall")
data_sub_spring<-data_sub%>%
  filter(season_4=="Spring")
```

### BRT

Used <https://rspatial.org/raster/sdm/9_sdm_brt.html> as a referenced

#### Mean temperature

``` r
df1<-data_sub%>%
  dplyr::select(-c(Tmax_diff, Tmin_diff))
```

##### Tune BRT parameters

Tutorials on tuning: - <https://uc-r.github.io/gbm_regression> - Kuhn,
M., & Johnson, K. (2013). Applied predictive modeling (Vol. 26, p. 13).
New York: Springer.

Create a hyper parameter grid that defines the different parameters I
want to compare.

``` r
set.seed(123)
random_index <- sample(1:nrow(df1), nrow(df1))
random_df1 <- df1[random_index, ]

# create hyperparameter grid
hyper_grid <- expand.grid(
  shrinkage = c(.001, .01, .1),
  interaction.depth = c(2, 3),
  # n.trees = seq(100, 1000, by = 100),
  n.minobsinnode = c(10, 15, 20, 30),
  bag.fraction = c(.5, .75, .85), 
  optimal_trees = 0,               # a place to dump results
  min_RMSE = 0                 # a place to dump results
)

# total number of combinationsco
nrow(hyper_grid)
```

Create a function that will build gbm models for each combination of
parameters.

``` r
# grid search 
for(i in 1:nrow(hyper_grid)) {
  
  # reproducibility
  set.seed(123)
  
  # train model
  gbm.tune <- gbm(
    formula = Tavg_diff ~ .,
    distribution = "gaussian",
    data = random_df1,
    n.trees = 5000,
    interaction.depth = hyper_grid$interaction.depth[i],
    shrinkage = hyper_grid$shrinkage[i],
    n.minobsinnode = hyper_grid$n.minobsinnode[i],
    bag.fraction = hyper_grid$bag.fraction[i],
    train.fraction = .75,
    n.cores = NULL, # will use all cores by default
    verbose = FALSE
  )
  
  # add min training error and trees to grid
  hyper_grid$optimal_trees[i] <- which.min(gbm.tune$valid.error)
  hyper_grid$min_RMSE[i] <- sqrt(min(gbm.tune$valid.error))
}

# save
tune_param_mean_1<-hyper_grid%>%
   dplyr::arrange(min_RMSE) 
save(tune_param_mean_1, file="2_pipeline/store/tune_param_mean_1.rData")
```

##### Apply dismo’s `gbm.step` to tuned parameters

``` r
set.seed(123)
#use gbm.step using tuned parameters
brt_meanTemp_tuned_1 <- gbm.step(data=df1, gbm.x = c(2:ncol(df1)), gbm.y = 1,
                        family = "gaussian", tree.complexity = 5,  n.minobsinnode = 15,
                        learning.rate = 0.1, bag.fraction = 0.85)

save(brt_meanTemp_tuned_1, file="2_pipeline/store/models/brt_meanTemp_tuned_1.rData")


# view relative importance of predictors
summary(brt_meanTemp_tuned_1)

# view plots of all variables
gbm.plot(brt_meanTemp_tuned_1, n.plots=21, write.title = FALSE)

# view optimal number of trees
gbm.perf(brt_meanTemp_tuned_1)
#[1] 557

# get model stats
# put relevant stats into a dataframe (e.g. explained deviance)
varimp.brt_meanTemp_tuned_1 <- as.data.frame(brt_meanTemp_tuned_1$contributions)
names(varimp.brt_meanTemp_tuned_1)[2] <- "brt_meanTemp_tuned_1"
cvstats.brt_meanTemp_tuned_1 <- as.data.frame(brt_meanTemp_tuned_1$cv.statistics[c(1,3)])
cvstats.brt_meanTemp_tuned_1$deviance.null <- brt_meanTemp_tuned_1$self.statistics$mean.null
cvstats.brt_meanTemp_tuned_1$deviance.explained <- (cvstats.brt_meanTemp_tuned_1$deviance.null-cvstats.brt_meanTemp_tuned_1$deviance.mean)/cvstats.brt_meanTemp_tuned_1$deviance.null
cvstats.brt_meanTemp_tuned_1$model_name<-"meanTemp_tuned_1"
```

##### Identify and eliminate unimportant variables

Drop variables that don’t improve model performance.

``` r
simp_meanTemp_tuned <- gbm.simplify(brt_meanTemp_tuned_1)
save(simp_meanTemp_tuned, file="2_pipeline/store/models/simp_meanTemp_tuned.rData")

##  remove non-numeric characters from the row names
rownames(simp_meanTemp_tuned$deviance.summary) <- gsub("[^0-9]", "", rownames(simp_meanTemp_tuned$deviance.summary))

## get the optimal number of drops
optimal_no_drops<-as.numeric(rownames(simp_meanTemp_tuned$deviance.summary%>%slice_min(mean))) 
```

##### Run model with reduced variables

``` r
# recreate hypergrid
hyper_grid <- expand.grid(
  shrinkage = c(.001, .01, .1),
  interaction.depth = c(2, 3),
  # n.trees = seq(100, 1000, by = 100),
  n.minobsinnode = c(10, 15, 20, 30),
  bag.fraction = c(.5, .75, .85), 
  optimal_trees = 0,               # a place to dump results
  min_RMSE = 0                 # a place to dump results
)

### remove droped variables from the dataframe
df2<-df1%>%
  dplyr::select(Tavg_diff,simp_meanTemp_tuned$pred.list[[optimal_no_drops]])

set.seed(123)
random_index <- sample(1:nrow(df2), nrow(df2))
random_df2 <- df2[random_index, ]

# grid search 
for(i in 1:nrow(hyper_grid)) {
  
  # reproducibility
  set.seed(123)
  
  # train model
  gbm.tune <- gbm(
    formula = Tavg_diff ~ .,
    distribution = "gaussian",
    data = random_df2,
    n.trees = 5000,
    interaction.depth = hyper_grid$interaction.depth[i],
    shrinkage = hyper_grid$shrinkage[i],
    n.minobsinnode = hyper_grid$n.minobsinnode[i],
    bag.fraction = hyper_grid$bag.fraction[i],
    train.fraction = .75,
    n.cores = NULL, # will use all cores by default
    verbose = FALSE
  )
  
  # add min training error and trees to grid
  hyper_grid$optimal_trees[i] <- which.min(gbm.tune$valid.error)
  hyper_grid$min_RMSE[i] <- sqrt(min(gbm.tune$valid.error))
}

# save
tune_param_mean_2<-hyper_grid%>%
   dplyr::arrange(min_RMSE) 
save(tune_param_mean_2, file="2_pipeline/store/tune_param_mean_2.rData")


brt_meanTemp_tuned_2 <- gbm.step(data=df2, gbm.x = c(2:ncol(df2)), gbm.y = 1,
                        family = "gaussian", tree.complexity = 3,  n.minobsinnode = 10,
                        learning.rate = 0.1, bag.fraction = 0.5, max.trees = 50000)


save(brt_meanTemp_tuned_2, file="2_pipeline/store/models/brt_meanTemp_tuned_2.rData")

summary(brt_meanTemp_tuned_2)

varimp.brt_meanTemp_tuned_2 <- as.data.frame(brt_meanTemp_tuned_2$contributions)
names(varimp.brt_meanTemp_tuned_2)[2] <- "brt_meanTemp_tuned_2"
cvstats.brt_meanTemp_tuned_2<- as.data.frame(brt_meanTemp_tuned_2$cv.statistics[c(1,3)])
cvstats.brt_meanTemp_tuned_2$deviance.null <- brt_meanTemp_tuned_2$self.statistics$mean.null
cvstats.brt_meanTemp_tuned_2$deviance.explained <- (cvstats.brt_meanTemp_tuned_2$deviance.null-cvstats.brt_meanTemp_tuned_2$deviance.mean)/cvstats.brt_meanTemp_tuned_2$deviance.null
cvstats.brt_meanTemp_tuned_2$model_name<-"meanTemp_tuned_2"
```

##### Small model with top predictors

``` r
df3<-df1%>%
  dplyr::select(Tavg_diff, tpi_50, tpi_500, canopy_height, srad, vs, northness, TWI, CHILI, pr)



set.seed(123)
random_index <- sample(1:nrow(df3), nrow(df3))
random_df3 <- df3[random_index, ]


hyper_grid <- expand.grid(
  shrinkage = c(.001, .01, .1),
  interaction.depth = c(2, 3),
  # n.trees = seq(100, 1000, by = 100),
  n.minobsinnode = c(10, 15, 20, 30),
  bag.fraction = c(.5, .75, .85), 
  optimal_trees = 0,               # a place to dump results
  min_RMSE = 0                 # a place to dump results
)

for(i in 1:nrow(hyper_grid)) {
  
  # reproducibility
  set.seed(123)
  
  # train model
  gbm.tune <- gbm(
    formula = Tavg_diff ~ .,
    distribution = "gaussian",
    data = random_df3,
    n.trees = 5000,
    interaction.depth = hyper_grid$interaction.depth[i],
    shrinkage = hyper_grid$shrinkage[i],
    n.minobsinnode = hyper_grid$n.minobsinnode[i],
    bag.fraction = hyper_grid$bag.fraction[i],
    train.fraction = .75,
    n.cores = NULL, # will use all cores by default
    verbose = FALSE
  )
  
  # add min training error and trees to grid
  hyper_grid$optimal_trees[i] <- which.min(gbm.tune$valid.error)
  hyper_grid$min_RMSE[i] <- sqrt(min(gbm.tune$valid.error))
}

# save
tune_param_mean_3<-hyper_grid%>%
   dplyr::arrange(min_RMSE) 
save(tune_param_mean_3, file="2_pipeline/store/tune_param_mean_3.rData")

brt_meanTemp_tuned_3 <- gbm.step(data=df3, gbm.x = c(2:ncol(df3)), gbm.y = 1,
                        family = "gaussian", tree.complexity = 3,  n.minobsinnode = 10,
                        learning.rate = 0.1, bag.fraction = 0.75, max.trees = 50000)


save(brt_meanTemp_tuned_3, file="2_pipeline/store/models/brt_meanTemp_tuned_3.rData")


summary(brt_meanTemp_tuned_3)

varimp.brt_meanTemp_tuned_3 <- as.data.frame(brt_meanTemp_tuned_3$contributions)
names(varimp.brt_meanTemp_tuned_3)[2] <- "brt_meanTemp_tuned_3"
cvstats.brt_meanTemp_tuned_3<- as.data.frame(brt_meanTemp_tuned_3$cv.statistics[c(1,3)])
cvstats.brt_meanTemp_tuned_3$deviance.null <- brt_meanTemp_tuned_3$self.statistics$mean.null
cvstats.brt_meanTemp_tuned_3$deviance.explained <- (cvstats.brt_meanTemp_tuned_3$deviance.null-cvstats.brt_meanTemp_tuned_3$deviance.mean)/cvstats.brt_meanTemp_tuned_3$deviance.null
cvstats.brt_meanTemp_tuned_3$model_name<-"meanTemp_tuned_3"

# reduce tree complexity
brt_meanTemp_tuned_4 <- gbm.step(data=df3, gbm.x = c(2:ncol(df3)), gbm.y = 1,
                        family = "gaussian", tree.complexity = 2,  n.meanobsinnode = 15,
                        learning.rate = 0.1, bag.fraction = 0.75, max.trees = 50000)

save(brt_meanTemp_tuned_4, file="2_pipeline/store/models/brt_meanTemp_tuned_4.rData")

summary(brt_meanTemp_tuned_4)

varimp.brt_meanTemp_tuned_4 <- as.data.frame(brt_meanTemp_tuned_4$contributions)
names(varimp.brt_meanTemp_tuned_4)[2] <- "brt_meanTemp_tuned_4"
cvstats.brt_meanTemp_tuned_4<- as.data.frame(brt_meanTemp_tuned_4$cv.statistics[c(1,3)])
cvstats.brt_meanTemp_tuned_4$deviance.null <- brt_meanTemp_tuned_4$self.statistics$mean.null
cvstats.brt_meanTemp_tuned_4$deviance.explained <- (cvstats.brt_meanTemp_tuned_4$deviance.null-cvstats.brt_meanTemp_tuned_4$deviance.mean)/cvstats.brt_meanTemp_tuned_4$deviance.null
cvstats.brt_meanTemp_tuned_4$model_name<-"meanTemp_tuned_4"

### Include season variable
df3<-data_sub%>%
  dplyr::select(Tavg_diff, tpi_50, tpi_500, canopy_height, srad, vs, northness, TWI, CHILI, pr, season_4)

brt_meanTemp_allSeasons <- gbm.step(data=df3, gbm.x = c(2:ncol(df3)), gbm.y = 1,
                        family = "gaussian", tree.complexity = 2,  n.meanobsinnode = 15,
                        learning.rate = 0.1, bag.fraction = 0.75, mean.trees = 50000)

save(brt_meanTemp_allSeasons, file="2_pipeline/store/models/brt_meanTemp_allSeasons.rData")


varimp.brt_meanTemp_allSeasons <- as.data.frame(brt_meanTemp_allSeasons$contributions)
names(varimp.brt_meanTemp_allSeasons)[2] <- "brt_meanTemp_allSeasons"
cvstats.brt_meanTemp_allSeasons<- as.data.frame(brt_meanTemp_allSeasons$cv.statistics[c(1,3)])
cvstats.brt_meanTemp_allSeasons$deviance.null <- brt_meanTemp_allSeasons$self.statistics$mean.null
cvstats.brt_meanTemp_allSeasons$deviance.explained <- (cvstats.brt_meanTemp_allSeasons$deviance.null-cvstats.brt_meanTemp_allSeasons$deviance.mean)/cvstats.brt_meanTemp_allSeasons$deviance.null
cvstats.brt_meanTemp_allSeasons$model_name<-"meanTemp_allSeasons"
```

##### Models, split by season

``` r
df_summer<-data_sub_summer%>%
  dplyr::select(Tavg_diff, tpi_50, tpi_500, canopy_height, srad, vs, northness, TWI, CHILI, pr)


brt_meanTemp_summer <- gbm.step(data=df_summer, gbm.x = c(2:ncol(df_summer)), gbm.y = 1,
                        family = "gaussian", tree.complexity = 3,  n.meanobsinnode = 10,
                        learning.rate = 0.1, bag.fraction = 0.85, max.trees = 50000)

save(brt_meanTemp_summer, file="2_pipeline/store/models/brt_meanTemp_summer.rData")

summary(brt_meanTemp_summer)

varimp.brt_meanTemp_summer <- as.data.frame(brt_meanTemp_summer$contributions)
names(varimp.brt_meanTemp_summer)[2] <- "brt_meanTemp_summer"
cvstats.brt_meanTemp_summer<- as.data.frame(brt_meanTemp_summer$cv.statistics[c(1,3)])
cvstats.brt_meanTemp_summer$deviance.null <- brt_meanTemp_summer$self.statistics$mean.null
cvstats.brt_meanTemp_summer$deviance.explained <- (cvstats.brt_meanTemp_summer$deviance.null-cvstats.brt_meanTemp_summer$deviance.mean)/cvstats.brt_meanTemp_summer$deviance.null
cvstats.brt_meanTemp_summer$model_name<-"meanTemp_summer"

#########################
df_winter<-data_sub_winter%>%
  dplyr::select(Tavg_diff, tpi_50, tpi_500, canopy_height, srad, vs, northness, TWI, CHILI, pr)


brt_meanTemp_winter <- gbm.step(data=df_winter, gbm.x = c(2:ncol(df_winter)), gbm.y = 1,
                        family = "gaussian", tree.complexity = 3,  n.meanobsinnode = 10,
                        learning.rate = 0.1, bag.fraction = 0.85, max.trees = 50000)

save(brt_meanTemp_winter, file="2_pipeline/store/models/brt_meanTemp_winter.rData")

summary(brt_meanTemp_winter)

varimp.brt_meanTemp_winter <- as.data.frame(brt_meanTemp_winter$contributions)
names(varimp.brt_meanTemp_winter)[2] <- "brt_meanTemp_winter"
cvstats.brt_meanTemp_winter<- as.data.frame(brt_meanTemp_winter$cv.statistics[c(1,3)])
cvstats.brt_meanTemp_winter$deviance.null <- brt_meanTemp_winter$self.statistics$mean.null
cvstats.brt_meanTemp_winter$deviance.explained <- (cvstats.brt_meanTemp_winter$deviance.null-cvstats.brt_meanTemp_winter$deviance.mean)/cvstats.brt_meanTemp_winter$deviance.null
cvstats.brt_meanTemp_winter$model_name<-"meanTemp_winter"

#########################
df_spring<-data_sub_spring%>%
  dplyr::select(Tavg_diff, tpi_50, tpi_500, canopy_height, srad, vs, northness, TWI, CHILI, pr)


brt_meanTemp_spring <- gbm.step(data=df_spring, gbm.x = c(2:ncol(df_spring)), gbm.y = 1,
                        family = "gaussian", tree.complexity = 3,  n.meanobsinnode = 10,
                        learning.rate = 0.1, bag.fraction = 0.85, max.trees = 50000)

save(brt_meanTemp_spring, file="2_pipeline/store/models/brt_meanTemp_spring.rData")

summary(brt_meanTemp_spring)

varimp.brt_meanTemp_spring <- as.data.frame(brt_meanTemp_spring$contributions)
names(varimp.brt_meanTemp_spring)[2] <- "brt_meanTemp_spring"
cvstats.brt_meanTemp_spring<- as.data.frame(brt_meanTemp_spring$cv.statistics[c(1,3)])
cvstats.brt_meanTemp_spring$deviance.null <- brt_meanTemp_spring$self.statistics$mean.null
cvstats.brt_meanTemp_spring$deviance.explained <- (cvstats.brt_meanTemp_spring$deviance.null-cvstats.brt_meanTemp_spring$deviance.mean)/cvstats.brt_meanTemp_spring$deviance.null
cvstats.brt_meanTemp_spring$model_name<-"meanTemp_spring"

#########################
df_fall<-data_sub_fall%>%
  dplyr::select(Tavg_diff, tpi_50, tpi_500, canopy_height, srad, vs, northness, TWI, CHILI, pr)


brt_meanTemp_fall <- gbm.step(data=df_fall, gbm.x = c(2:ncol(df_fall)), gbm.y = 1,
                        family = "gaussian", tree.complexity = 3,  n.meanobsinnode = 10,
                        learning.rate = 0.1, bag.fraction = 0.85, max.trees = 50000)

save(brt_meanTemp_fall, file="2_pipeline/store/models/brt_meanTemp_fall.rData")

summary(brt_meanTemp_fall)

varimp.brt_meanTemp_fall <- as.data.frame(brt_meanTemp_fall$contributions)
names(varimp.brt_meanTemp_fall)[2] <- "brt_meanTemp_fall"
cvstats.brt_meanTemp_fall<- as.data.frame(brt_meanTemp_fall$cv.statistics[c(1,3)])
cvstats.brt_meanTemp_fall$deviance.null <- brt_meanTemp_fall$self.statistics$mean.null
cvstats.brt_meanTemp_fall$deviance.explained <- (cvstats.brt_meanTemp_fall$deviance.null-cvstats.brt_meanTemp_fall$deviance.mean)/cvstats.brt_meanTemp_fall$deviance.null
cvstats.brt_meanTemp_fall$model_name<-"meanTemp_fall"
```

#### Max temperature

``` r
df1<-data_sub%>%
  dplyr::select(-c(Tavg_diff, Tmin_diff))
```

##### Tune BRT parameters

Tutorials on tuning: - <https://uc-r.github.io/gbm_regression> - Kuhn,
M., & Johnson, K. (2013). Applied predictive modeling (Vol. 26, p. 13).
New York: Springer.

Create a hyper parameter grid that defines the different parameters I
want to compare.

``` r
set.seed(123)
random_index <- sample(1:nrow(df1), nrow(df1))
random_df1 <- df1[random_index, ]


# create hyperparameter grid
hyper_grid <- expand.grid(
  shrinkage = c(.001, .01, .1),
  interaction.depth = c(2, 3, 5),
  # n.trees = seq(100, 1000, by = 100),
  n.minobsinnode = c(10, 15, 20, 30),
  bag.fraction = c(.5, .75, .85), 
  optimal_trees = 0,               # a place to dump results
  min_RMSE = 0                 # a place to dump results
)

# total number of combinationsco
nrow(hyper_grid)
## [1] 108
```

Create a function that will build gbm models for each combination of
parameters.

``` r
# grid search 
for(i in 1:nrow(hyper_grid)) {
  
  # reproducibility
  set.seed(123)
  
  # train model
  gbm.tune <- gbm(
    formula = Tmax_diff ~ .,
    distribution = "gaussian",
    data = random_df1,
    n.trees = 5000,
    interaction.depth = hyper_grid$interaction.depth[i],
    shrinkage = hyper_grid$shrinkage[i],
    n.minobsinnode = hyper_grid$n.minobsinnode[i],
    bag.fraction = hyper_grid$bag.fraction[i],
    train.fraction = .75,
    n.cores = NULL, # will use all cores by default
    verbose = FALSE
  )
  
  # add min training error and trees to grid
  hyper_grid$optimal_trees[i] <- which.min(gbm.tune$valid.error)
  hyper_grid$min_RMSE[i] <- sqrt(min(gbm.tune$valid.error))
}

# save
tune_param_max_1<-hyper_grid%>%
   dplyr::arrange(min_RMSE) 
save(tune_param_max_1, file="2_pipeline/store/tune_param_max_1.rData")
```

##### Apply dismo’s gbm.step to tuned parameters

``` r
set.seed(123)
#use gbm.step using tuned parameters
brt_maxTemp_tuned_1 <- gbm.step(data=df1, gbm.x = c(2:ncol(df1)), gbm.y = 1,
                        family = "gaussian", tree.complexity = 3,  n.minobsinnode = 30,
                        learning.rate = 0.1, bag.fraction = 0.85, max.trees = 50000)

save(brt_maxTemp_tuned_1, file="2_pipeline/store/models/brt_maxTemp_tuned_1.rData")


# view relative importance of predictors
summary(brt_maxTemp_tuned_1)

# view plots of all variables
gbm.plot(brt_maxTemp_tuned_1, n.plots=21, write.title = FALSE)

# view optimal number of trees
gbm.perf(brt_maxTemp_tuned_1)
#[1] 762


# get model stats
# put relevant stats into a dataframe (e.g. explained deviance)
varimp.brt_maxTemp_tuned_1 <- as.data.frame(brt_maxTemp_tuned_1$contributions)
names(varimp.brt_maxTemp_tuned_1)[2] <- "brt_maxTemp_tuned_1"
cvstats.brt_maxTemp_tuned_1 <- as.data.frame(brt_maxTemp_tuned_1$cv.statistics[c(1,3)])
cvstats.brt_maxTemp_tuned_1$deviance.null <- brt_maxTemp_tuned_1$self.statistics$mean.null
cvstats.brt_maxTemp_tuned_1$deviance.explained <- (cvstats.brt_maxTemp_tuned_1$deviance.null-cvstats.brt_maxTemp_tuned_1$deviance.mean)/cvstats.brt_maxTemp_tuned_1$deviance.null

cvstats.brt_maxTemp_tuned_1$model_name<-"maxTemp_tuned_1"
```

##### Identify and eliminate unimportant variables

Drop variables that don’t improve model performance.

``` r
simp_maxTemp_tuned <- gbm.simplify(brt_maxTemp_tuned_1)
save(simp_maxTemp_tuned, file="2_pipeline/store/models/simp_maxTemp_tuned.rData")

##  remove non-numeric characters from the row names
rownames(simp_maxTemp_tuned$deviance.summary) <- gsub("[^0-9]", "", rownames(simp_maxTemp_tuned$deviance.summary))

## get the optimal number of drops
optimal_no_drops<-as.numeric(rownames(simp_maxTemp_tuned$deviance.summary%>%slice_min(mean))) 
```

##### Run model with reduced variables

``` r
# recreate hypergrid
hyper_grid <- expand.grid(
  shrinkage = c(.001, .01, .1),
  interaction.depth = c(2, 3),
  # n.trees = seq(100, 1000, by = 100),
  n.minobsinnode = c(10, 15, 20, 30),
  bag.fraction = c(.5, .75, .85), 
  optimal_trees = 0,               # a place to dump results
  min_RMSE = 0                 # a place to dump results
)

### remove dropped variables from the dataframe
df2<-df1%>%
  dplyr::select(Tmax_diff,simp_maxTemp_tuned$pred.list[[optimal_no_drops]])

set.seed(123)
random_index <- sample(1:nrow(df2), nrow(df2))
random_df2 <- df2[random_index, ]

# grid search 
for(i in 1:nrow(hyper_grid)) {
  
  # reproducibility
  set.seed(123)
  
  # train model
  gbm.tune <- gbm(
    formula = Tmax_diff ~ .,
    distribution = "gaussian",
    data = random_df2,
    n.trees = 5000,
    interaction.depth = hyper_grid$interaction.depth[i],
    shrinkage = hyper_grid$shrinkage[i],
    n.minobsinnode = hyper_grid$n.minobsinnode[i],
    bag.fraction = hyper_grid$bag.fraction[i],
    train.fraction = .75,
    n.cores = NULL, # will use all cores by default
    verbose = FALSE
  )
  
  # add min training error and trees to grid
  hyper_grid$optimal_trees[i] <- which.min(gbm.tune$valid.error)
  hyper_grid$min_RMSE[i] <- sqrt(min(gbm.tune$valid.error))
}

# save
tune_param_max_2<-hyper_grid%>%
   dplyr::arrange(min_RMSE) 
save(tune_param_max_2, file="2_pipeline/store/tune_param_max_2.rData")


brt_maxTemp_tuned_2 <- gbm.step(data=df2, gbm.x = c(2:ncol(df2)), gbm.y = 1,
                        family = "gaussian", tree.complexity = 3,  n.minobsinnode = 30,
                        learning.rate = 0.1, bag.fraction = 0.85)
 

save(brt_maxTemp_tuned_2, file="2_pipeline/store/models/brt_maxTemp_tuned_2.rData")

summary(brt_maxTemp_tuned_2)
# view plots of all variables
gbm.plot(brt_maxTemp_tuned_2, n.plots=14, write.title = FALSE)
# view optimal number of trees
gbm.perf(brt_maxTemp_tuned_2)
#[1] 730



varimp.brt_maxTemp_tuned_2 <- as.data.frame(brt_maxTemp_tuned_2$contributions)
names(varimp.brt_maxTemp_tuned_2)[2] <- "brt_maxTemp_tuned_2"
cvstats.brt_maxTemp_tuned_2<- as.data.frame(brt_maxTemp_tuned_2$cv.statistics[c(1,3)])
cvstats.brt_maxTemp_tuned_2$deviance.null <- brt_maxTemp_tuned_2$self.statistics$mean.null
cvstats.brt_maxTemp_tuned_2$deviance.explained <- (cvstats.brt_maxTemp_tuned_2$deviance.null-cvstats.brt_maxTemp_tuned_2$deviance.mean)/cvstats.brt_maxTemp_tuned_2$deviance.null
cvstats.brt_maxTemp_tuned_2$model_name<-"maxTemp_tuned_2"
```

##### Small model with top predictors

``` r
df3<-df1%>%
  dplyr::select(Tmax_diff, tpi_50, tpi_500, canopy_height, srad, vs, northness, TWI, CHILI, pr)

set.seed(123)
random_index <- sample(1:nrow(df3), nrow(df3))
random_df3 <- df3[random_index, ]


hyper_grid <- expand.grid(
  shrinkage = c(.001, .01, .1),
  interaction.depth = c(2, 3),
  # n.trees = seq(100, 1000, by = 100),
  n.minobsinnode = c(10, 15, 20, 30),
  bag.fraction = c(.5, .75, .85), 
  optimal_trees = 0,               # a place to dump results
  min_RMSE = 0                 # a place to dump results
)

for(i in 1:nrow(hyper_grid)) {
  
  # reproducibility
  set.seed(123)
  
  # train model
  gbm.tune <- gbm(
    formula = Tmax_diff ~ .,
    distribution = "gaussian",
    data = random_df3,
    n.trees = 5000,
    interaction.depth = hyper_grid$interaction.depth[i],
    shrinkage = hyper_grid$shrinkage[i],
    n.minobsinnode = hyper_grid$n.minobsinnode[i],
    bag.fraction = hyper_grid$bag.fraction[i],
    train.fraction = .75,
    n.cores = NULL, # will use all cores by default
    verbose = FALSE
  )
  
  # add min training error and trees to grid
  hyper_grid$optimal_trees[i] <- which.min(gbm.tune$valid.error)
  hyper_grid$min_RMSE[i] <- sqrt(min(gbm.tune$valid.error))
}

# save
tune_param_max_3<-hyper_grid%>%
   dplyr::arrange(min_RMSE) 
save(tune_param_max_3, file="2_pipeline/store/tune_param_max_3.rData")

brt_maxTemp_tuned_3 <- gbm.step(data=df3, gbm.x = c(2:ncol(df3)), gbm.y = 1,
                        family = "gaussian", tree.complexity = 3,  n.minobsinnode = 10,
                        learning.rate = 0.1, bag.fraction = 0.75, max.trees = 50000)


save(brt_maxTemp_tuned_3, file="2_pipeline/store/models/brt_maxTemp_tuned_3.rData")


gbm.plot(brt_maxTemp_tuned_3)


summary(brt_maxTemp_tuned_3)

varimp.brt_maxTemp_tuned_3 <- as.data.frame(brt_maxTemp_tuned_3$contributions)
names(varimp.brt_maxTemp_tuned_3)[2] <- "brt_maxTemp_tuned_3"
cvstats.brt_maxTemp_tuned_3<- as.data.frame(brt_maxTemp_tuned_3$cv.statistics[c(1,3)])
cvstats.brt_maxTemp_tuned_3$deviance.null <- brt_maxTemp_tuned_3$self.statistics$mean.null
cvstats.brt_maxTemp_tuned_3$deviance.explained <- (cvstats.brt_maxTemp_tuned_3$deviance.null-cvstats.brt_maxTemp_tuned_3$deviance.mean)/cvstats.brt_maxTemp_tuned_3$deviance.null
cvstats.brt_maxTemp_tuned_3$model_name<-"maxTemp_tuned_3"

# reduce tree complexity
brt_maxTemp_tuned_4 <- gbm.step(data=df3, gbm.x = c(2:ncol(df3)), gbm.y = 1,
                        family = "gaussian", tree.complexity = 2,  n.maxobsinnode = 15,
                        learning.rate = 0.1, bag.fraction = 0.75, max.trees = 50000)

save(brt_maxTemp_tuned_4, file="2_pipeline/store/models/brt_maxTemp_tuned_4.rData")

summary(brt_maxTemp_tuned_4)

varimp.brt_maxTemp_tuned_4 <- as.data.frame(brt_maxTemp_tuned_4$contributions)
names(varimp.brt_maxTemp_tuned_4)[2] <- "brt_maxTemp_tuned_4"
cvstats.brt_maxTemp_tuned_4<- as.data.frame(brt_maxTemp_tuned_4$cv.statistics[c(1,3)])
cvstats.brt_maxTemp_tuned_4$deviance.null <- brt_maxTemp_tuned_4$self.statistics$mean.null
cvstats.brt_maxTemp_tuned_4$deviance.explained <- (cvstats.brt_maxTemp_tuned_4$deviance.null-cvstats.brt_maxTemp_tuned_4$deviance.mean)/cvstats.brt_maxTemp_tuned_4$deviance.null
cvstats.brt_maxTemp_tuned_4$model_name<-"maxTemp_tuned_4"

### Include season variable
df3<-data_sub%>%
  dplyr::select(Tmax_diff, tpi_50, tpi_500, canopy_height, srad, vs, northness, TWI, CHILI, pr, season_4)

brt_maxTemp_allSeasons <- gbm.step(data=df3, gbm.x = c(2:ncol(df3)), gbm.y = 1,
                        family = "gaussian", tree.complexity = 2,  n.maxobsinnode = 15,
                        learning.rate = 0.1, bag.fraction = 0.75, max.trees = 50000)

save(brt_maxTemp_allSeasons, file="2_pipeline/store/models/brt_maxTemp_allSeasons.rData")


varimp.brt_maxTemp_allSeasons <- as.data.frame(brt_maxTemp_allSeasons$contributions)
names(varimp.brt_maxTemp_allSeasons)[2] <- "brt_maxTemp_allSeasons"
cvstats.brt_maxTemp_allSeasons<- as.data.frame(brt_maxTemp_allSeasons$cv.statistics[c(1,3)])
cvstats.brt_maxTemp_allSeasons$deviance.null <- brt_maxTemp_allSeasons$self.statistics$mean.null
cvstats.brt_maxTemp_allSeasons$deviance.explained <- (cvstats.brt_maxTemp_allSeasons$deviance.null-cvstats.brt_maxTemp_allSeasons$deviance.mean)/cvstats.brt_maxTemp_allSeasons$deviance.null
cvstats.brt_maxTemp_allSeasons$model_name<-"maxTemp_allSeasons"
```

##### Models, split by season

``` r
df_summer<-data_sub_summer%>%
  dplyr::select(Tmax_diff, tpi_50, tpi_500, canopy_height, srad, vs, northness, TWI, CHILI, pr)


brt_maxTemp_summer <- gbm.step(data=df_summer, gbm.x = c(2:ncol(df_summer)), gbm.y = 1,
                        family = "gaussian", tree.complexity = 3,  n.maxobsinnode = 10,
                        learning.rate = 0.1, bag.fraction = 0.85, max.trees = 50000)

save(brt_maxTemp_summer, file="2_pipeline/store/models/brt_maxTemp_summer.rData")

summary(brt_maxTemp_summer)

varimp.brt_maxTemp_summer <- as.data.frame(brt_maxTemp_summer$contributions)
names(varimp.brt_maxTemp_summer)[2] <- "brt_maxTemp_summer"
cvstats.brt_maxTemp_summer<- as.data.frame(brt_maxTemp_summer$cv.statistics[c(1,3)])
cvstats.brt_maxTemp_summer$deviance.null <- brt_maxTemp_summer$self.statistics$mean.null
cvstats.brt_maxTemp_summer$deviance.explained <- (cvstats.brt_maxTemp_summer$deviance.null-cvstats.brt_maxTemp_summer$deviance.mean)/cvstats.brt_maxTemp_summer$deviance.null
cvstats.brt_maxTemp_summer$model_name<-"maxTemp_summer"

#########################
df_winter<-data_sub_winter%>%
  dplyr::select(Tmax_diff, tpi_50, tpi_500, canopy_height, srad, vs, northness, TWI, CHILI, pr)


brt_maxTemp_winter <- gbm.step(data=df_winter, gbm.x = c(2:ncol(df_winter)), gbm.y = 1,
                        family = "gaussian", tree.complexity = 3,  n.maxobsinnode = 10,
                        learning.rate = 0.1, bag.fraction = 0.85, max.trees = 50000)

save(brt_maxTemp_winter, file="2_pipeline/store/models/brt_maxTemp_winter.rData")

summary(brt_maxTemp_winter)

varimp.brt_maxTemp_winter <- as.data.frame(brt_maxTemp_winter$contributions)
names(varimp.brt_maxTemp_winter)[2] <- "brt_maxTemp_winter"
cvstats.brt_maxTemp_winter<- as.data.frame(brt_maxTemp_winter$cv.statistics[c(1,3)])
cvstats.brt_maxTemp_winter$deviance.null <- brt_maxTemp_winter$self.statistics$mean.null
cvstats.brt_maxTemp_winter$deviance.explained <- (cvstats.brt_maxTemp_winter$deviance.null-cvstats.brt_maxTemp_winter$deviance.mean)/cvstats.brt_maxTemp_winter$deviance.null
cvstats.brt_maxTemp_winter$model_name<-"maxTemp_winter"

#########################
df_spring<-data_sub_spring%>%
  dplyr::select(Tmax_diff, tpi_50, tpi_500, canopy_height, srad, vs, northness, TWI, CHILI, pr)


brt_maxTemp_spring <- gbm.step(data=df_spring, gbm.x = c(2:ncol(df_spring)), gbm.y = 1,
                        family = "gaussian", tree.complexity = 3,  n.maxobsinnode = 10,
                        learning.rate = 0.1, bag.fraction = 0.85, max.trees = 50000)

save(brt_maxTemp_spring, file="2_pipeline/store/models/brt_maxTemp_spring.rData")

summary(brt_maxTemp_spring)

varimp.brt_maxTemp_spring <- as.data.frame(brt_maxTemp_spring$contributions)
names(varimp.brt_maxTemp_spring)[2] <- "brt_maxTemp_spring"
cvstats.brt_maxTemp_spring<- as.data.frame(brt_maxTemp_spring$cv.statistics[c(1,3)])
cvstats.brt_maxTemp_spring$deviance.null <- brt_maxTemp_spring$self.statistics$mean.null
cvstats.brt_maxTemp_spring$deviance.explained <- (cvstats.brt_maxTemp_spring$deviance.null-cvstats.brt_maxTemp_spring$deviance.mean)/cvstats.brt_maxTemp_spring$deviance.null
cvstats.brt_maxTemp_spring$model_name<-"maxTemp_spring"

#########################
df_fall<-data_sub_fall%>%
  dplyr::select(Tmax_diff, tpi_50, tpi_500, canopy_height, srad, vs, northness, TWI, CHILI, pr)


brt_maxTemp_fall <- gbm.step(data=df_fall, gbm.x = c(2:ncol(df_fall)), gbm.y = 1,
                        family = "gaussian", tree.complexity = 3,  n.maxobsinnode = 10,
                        learning.rate = 0.1, bag.fraction = 0.85, max.trees = 50000)

save(brt_maxTemp_fall, file="2_pipeline/store/models/brt_maxTemp_fall.rData")

summary(brt_maxTemp_fall)

varimp.brt_maxTemp_fall <- as.data.frame(brt_maxTemp_fall$contributions)
names(varimp.brt_maxTemp_fall)[2] <- "brt_maxTemp_fall"
cvstats.brt_maxTemp_fall<- as.data.frame(brt_maxTemp_fall$cv.statistics[c(1,3)])
cvstats.brt_maxTemp_fall$deviance.null <- brt_maxTemp_fall$self.statistics$mean.null
cvstats.brt_maxTemp_fall$deviance.explained <- (cvstats.brt_maxTemp_fall$deviance.null-cvstats.brt_maxTemp_fall$deviance.mean)/cvstats.brt_maxTemp_fall$deviance.null
cvstats.brt_maxTemp_fall$model_name<-"maxTemp_fall"
```

#### Min temperature

``` r
df1<-data_sub%>%
  dplyr::select(-c(Tavg_diff, Tmax_diff))
```

##### Tune BRT parameters

Tutorials on tuning: - <https://uc-r.github.io/gbm_regression> - Kuhn,
M., & Johnson, K. (2013). Applied predictive modeling (Vol. 26, p. 13).
New York: Springer.

Create a hyper parameter grid that defines the different parameters I
want to compare.

``` r
set.seed(123)
random_index <- sample(1:nrow(df1), nrow(df1))
random_df1 <- df1[random_index, ]


# create hyperparameter grid
hyper_grid <- expand.grid(
  shrinkage = c(.001, .01, .1),
  interaction.depth = c(2, 3),
  # n.trees = seq(100, 1000, by = 100),
  n.minobsinnode = c(10, 15, 20, 30),
  bag.fraction = c(.5, .75, .85), 
  optimal_trees = 0,               # a place to dump results
  min_RMSE = 0                 # a place to dump results
)

# total number of combinationsco
nrow(hyper_grid)
## [1] 108
```

Create a function that will build gbm models for each combination of
parameters.

``` r
# grid search 
for(i in 1:nrow(hyper_grid)) {
  
  # reproducibility
  set.seed(123)
  
  # train model
  gbm.tune <- gbm(
    formula = Tmin_diff ~ .,
    distribution = "gaussian",
    data = random_df1,
    n.trees = 5000,
    interaction.depth = hyper_grid$interaction.depth[i],
    shrinkage = hyper_grid$shrinkage[i],
    n.minobsinnode = hyper_grid$n.minobsinnode[i],
    bag.fraction = hyper_grid$bag.fraction[i],
    train.fraction = .75,
    n.cores = NULL, # will use all cores by default
    verbose = FALSE
  )
  
  # add min training error and trees to grid
  hyper_grid$optimal_trees[i] <- which.min(gbm.tune$valid.error)
  hyper_grid$min_RMSE[i] <- sqrt(min(gbm.tune$valid.error))
}

# save
tune_param_min_1<-hyper_grid%>%
   dplyr::arrange(min_RMSE) 
save(tune_param_min_1, file="2_pipeline/store/tune_param_min_1.rData")
```

##### Apply dismo’s gbm.step to tuned parameters

``` r
set.seed(123)
#use gbm.step using tuned parameters
brt_minTemp_tuned_1 <- gbm.step(data=df1, gbm.x = c(2:ncol(df1)), gbm.y = 1,
                        family = "gaussian", tree.complexity = 3,  n.minobsinnode = 30,
                        learning.rate = 0.001, bag.fraction = 0.85, max.trees = 50000)

save(brt_minTemp_tuned_1, file="2_pipeline/store/models/brt_minTemp_tuned_1.rData")


# view relative importance of predictors
summary(brt_minTemp_tuned_1)

# view plots of all variables
gbm.plot(brt_minTemp_tuned_1, n.plots=21, write.title = FALSE)

# view optimal number of trees
gbm.perf(brt_minTemp_tuned_1)
#[1] 39400

# get model stats
# put relevant stats into a dataframe (e.g. explained deviance)
varimp.brt_minTemp_tuned_1 <- as.data.frame(brt_minTemp_tuned_1$contributions)
names(varimp.brt_minTemp_tuned_1)[2] <- "brt_minTemp_tuned_1"
cvstats.brt_minTemp_tuned_1 <- as.data.frame(brt_minTemp_tuned_1$cv.statistics[c(1,3)])
cvstats.brt_minTemp_tuned_1$deviance.null <- brt_minTemp_tuned_1$self.statistics$mean.null
cvstats.brt_minTemp_tuned_1$deviance.explained <- (cvstats.brt_minTemp_tuned_1$deviance.null-cvstats.brt_minTemp_tuned_1$deviance.mean)/cvstats.brt_minTemp_tuned_1$deviance.null

cvstats.brt_minTemp_tuned_1$model_name<-"minTemp_tuned_1"
```

##### Identify and eliminate unimportant variables

Drop variables that don’t improve model performance.

``` r
simp_minTemp_tuned <- gbm.simplify(brt_minTemp_tuned_1)
save(simp_minTemp_tuned, file="2_pipeline/store/models/simp_minTemp_tuned.rData")

##  remove non-numeric characters from the row names
rownames(simp_minTemp_tuned$deviance.summary) <- gsub("[^0-9]", "", rownames(simp_minTemp_tuned$deviance.summary))

## get the optimal number of drops
optimal_no_drops<-as.numeric(rownames(simp_minTemp_tuned$deviance.summary%>%slice_min(mean))) 
```

##### Run model with reduced variables

``` r
# recreate hypergrid
hyper_grid <- expand.grid(
  shrinkage = c(.001, .01, .1),
  interaction.depth = c(2,3),
  # n.trees = seq(100, 1000, by = 100),
  n.minobsinnode = c(10, 15, 20, 30),
  bag.fraction = c(.5, .75), 
  optimal_trees = 0,               # a place to dump results
  min_RMSE = 0                 # a place to dump results
)

### remove droped variables from the dataframe
df2<-df1%>%
  dplyr::select(Tmin_diff,simp_minTemp_tuned$pred.list[[optimal_no_drops]])

set.seed(123)
random_index <- sample(1:nrow(df2), nrow(df2))
random_df2 <- df2[random_index, ]

# grid search 
for(i in 1:nrow(hyper_grid)) {
  
  # reproducibility
  set.seed(123)
  
  # train model
  gbm.tune <- gbm(
    formula = Tmin_diff ~ .,
    distribution = "gaussian",
    data = random_df2,
    n.trees = 5000,
    interaction.depth = hyper_grid$interaction.depth[i],
    shrinkage = hyper_grid$shrinkage[i],
    n.minobsinnode = hyper_grid$n.minobsinnode[i],
    bag.fraction = hyper_grid$bag.fraction[i],
    train.fraction = .75,
    n.cores = NULL, # will use all cores by default
    verbose = FALSE
  )
  
  # add min training error and trees to grid
  hyper_grid$optimal_trees[i] <- which.min(gbm.tune$valid.error)
  hyper_grid$min_RMSE[i] <- sqrt(min(gbm.tune$valid.error))
}

# save
tune_param_min_2<-hyper_grid%>%
   dplyr::arrange(min_RMSE) 
save(tune_param_min_2, file="2_pipeline/store/tune_param_min_2.rData")


brt_minTemp_tuned_2 <- gbm.step(data=df2, gbm.x = c(2:ncol(df2)), gbm.y = 1,
                        family = "gaussian", tree.complexity = 3,  n.minobsinnode = 15,
                        learning.rate = 0.1, bag.fraction = 0.75)


save(brt_minTemp_tuned_2, file="2_pipeline/store/models/brt_minTemp_tuned_2.rData")

gbm.perf(brt_minTemp_tuned_2)
# 247

varimp.brt_minTemp_tuned_2 <- as.data.frame(brt_minTemp_tuned_2$contributions)
names(varimp.brt_minTemp_tuned_2)[2] <- "brt_minTemp_tuned_2"
cvstats.brt_minTemp_tuned_2 <- as.data.frame(brt_minTemp_tuned_2$cv.statistics[c(1,3)])
cvstats.brt_minTemp_tuned_2$deviance.null <- brt_minTemp_tuned_2$self.statistics$mean.null
cvstats.brt_minTemp_tuned_2$deviance.explained <- (cvstats.brt_minTemp_tuned_2$deviance.null-cvstats.brt_minTemp_tuned_2$deviance.mean)/cvstats.brt_minTemp_tuned_2$deviance.null

cvstats.brt_minTemp_tuned_2$model_name<-"minTemp_tuned_2"
```

##### Small model with top predictors

``` r
df3<-df1%>%
  dplyr::select(Tmin_diff, tpi_50, tpi_500, canopy_height, srad, vs, northness, TWI, CHILI, pr)

set.seed(123)
random_index <- sample(1:nrow(df3), nrow(df3))
random_df3 <- df3[random_index, ]


hyper_grid <- expand.grid(
  shrinkage = c(.001, .01, .1),
  interaction.depth = c(2, 3),
  # n.trees = seq(100, 1000, by = 100),
  n.minobsinnode = c(10, 15, 20, 30),
  bag.fraction = c(.5, .75, .85), 
  optimal_trees = 0,               # a place to dump results
  min_RMSE = 0                 # a place to dump results
)

for(i in 1:nrow(hyper_grid)) {
  
  # reproducibility
  set.seed(123)
  
  # train model
  gbm.tune <- gbm(
    formula = Tmin_diff ~ .,
    distribution = "gaussian",
    data = random_df3,
    n.trees = 5000,
    interaction.depth = hyper_grid$interaction.depth[i],
    shrinkage = hyper_grid$shrinkage[i],
    n.minobsinnode = hyper_grid$n.minobsinnode[i],
    bag.fraction = hyper_grid$bag.fraction[i],
    train.fraction = .75,
    n.cores = NULL, # will use all cores by default
    verbose = FALSE
  )
  
  # add min training error and trees to grid
  hyper_grid$optimal_trees[i] <- which.min(gbm.tune$valid.error)
  hyper_grid$min_RMSE[i] <- sqrt(min(gbm.tune$valid.error))
}

# save
tune_param_min_3<-hyper_grid%>%
   dplyr::arrange(min_RMSE) 
save(tune_param_min_3, file="2_pipeline/store/tune_param_min_3.rData")

brt_minTemp_tuned_3 <- gbm.step(data=df3, gbm.x = c(2:ncol(df3)), gbm.y = 1,
                        family = "gaussian", tree.complexity = 3,  n.minobsinnode = 15,
                        learning.rate = 0.1, bag.fraction = 0.75, max.trees = 50000)

save(brt_minTemp_tuned_3, file="2_pipeline/store/models/brt_minTemp_tuned_3.rData")

summary(brt_minTemp_tuned_3)

varimp.brt_minTemp_tuned_3 <- as.data.frame(brt_minTemp_tuned_3$contributions)
names(varimp.brt_minTemp_tuned_3)[2] <- "brt_minTemp_tuned_3"
cvstats.brt_minTemp_tuned_3<- as.data.frame(brt_minTemp_tuned_3$cv.statistics[c(1,3)])
cvstats.brt_minTemp_tuned_3$deviance.null <- brt_minTemp_tuned_3$self.statistics$mean.null
cvstats.brt_minTemp_tuned_3$deviance.explained <- (cvstats.brt_minTemp_tuned_3$deviance.null-cvstats.brt_minTemp_tuned_3$deviance.mean)/cvstats.brt_minTemp_tuned_3$deviance.null
cvstats.brt_minTemp_tuned_3$model_name<-"minTemp_tuned_3"


# reduce tree complexity
brt_minTemp_tuned_4 <- gbm.step(data=df3, gbm.x = c(2:ncol(df3)), gbm.y = 1,
                        family = "gaussian", tree.complexity = 2,  n.minobsinnode = 15,
                        learning.rate = 0.1, bag.fraction = 0.75, max.trees = 50000)

save(brt_minTemp_tuned_4, file="2_pipeline/store/models/brt_minTemp_tuned_4.rData")

summary(brt_minTemp_tuned_4)

plot(brt_minTemp_tuned_3)
plot(brt_minTemp_tuned_4)

varimp.brt_minTemp_tuned_4 <- as.data.frame(brt_minTemp_tuned_4$contributions)
names(varimp.brt_minTemp_tuned_4)[2] <- "brt_minTemp_tuned_4"
cvstats.brt_minTemp_tuned_4<- as.data.frame(brt_minTemp_tuned_4$cv.statistics[c(1,3)])
cvstats.brt_minTemp_tuned_4$deviance.null <- brt_minTemp_tuned_4$self.statistics$mean.null
cvstats.brt_minTemp_tuned_4$deviance.explained <- (cvstats.brt_minTemp_tuned_4$deviance.null-cvstats.brt_minTemp_tuned_4$deviance.mean)/cvstats.brt_minTemp_tuned_4$deviance.null
cvstats.brt_minTemp_tuned_4$model_name<-"minTemp_tuned_4"

### Include season variable
df3<-data_sub%>%
  dplyr::select(Tmin_diff, tpi_50, tpi_500, canopy_height, srad, vs, northness, TWI, CHILI, pr, season_4)

brt_minTemp_allSeasons <- gbm.step(data=df3, gbm.x = c(2:ncol(df3)), gbm.y = 1,
                        family = "gaussian", tree.complexity = 2,  n.minobsinnode = 15,
                        learning.rate = 0.1, bag.fraction = 0.75, min.trees = 50000)

save(brt_minTemp_allSeasons, file="2_pipeline/store/models/brt_minTemp_allSeasons.rData")


varimp.brt_minTemp_allSeasons <- as.data.frame(brt_minTemp_allSeasons$contributions)
names(varimp.brt_minTemp_allSeasons)[2] <- "brt_minTemp_allSeasons"
cvstats.brt_minTemp_allSeasons<- as.data.frame(brt_minTemp_allSeasons$cv.statistics[c(1,3)])
cvstats.brt_minTemp_allSeasons$deviance.null <- brt_minTemp_allSeasons$self.statistics$mean.null
cvstats.brt_minTemp_allSeasons$deviance.explained <- (cvstats.brt_minTemp_allSeasons$deviance.null-cvstats.brt_minTemp_allSeasons$deviance.mean)/cvstats.brt_minTemp_allSeasons$deviance.null
cvstats.brt_minTemp_allSeasons$model_name<-"minTemp_allSeasons"
```

##### Models, split by season

``` r
df_summer<-data_sub_summer%>%
  dplyr::select(Tmin_diff, tpi_50, tpi_500, canopy_height, srad, vs, northness, TWI, CHILI, pr)


brt_minTemp_summer <- gbm.step(data=df_summer, gbm.x = c(2:ncol(df_summer)), gbm.y = 1,
                        family = "gaussian", tree.complexity = 3,  n.minobsinnode = 10,
                        learning.rate = 0.1, bag.fraction = 0.85, max.trees = 50000)

save(brt_minTemp_summer, file="2_pipeline/store/models/brt_minTemp_summer.rData")

summary(brt_minTemp_summer)

varimp.brt_minTemp_summer <- as.data.frame(brt_minTemp_summer$contributions)
names(varimp.brt_minTemp_summer)[2] <- "brt_minTemp_summer"
cvstats.brt_minTemp_summer<- as.data.frame(brt_minTemp_summer$cv.statistics[c(1,3)])
cvstats.brt_minTemp_summer$deviance.null <- brt_minTemp_summer$self.statistics$mean.null
cvstats.brt_minTemp_summer$deviance.explained <- (cvstats.brt_minTemp_summer$deviance.null-cvstats.brt_minTemp_summer$deviance.mean)/cvstats.brt_minTemp_summer$deviance.null
cvstats.brt_minTemp_summer$model_name<-"minTemp_summer"

#########################
df_winter<-data_sub_winter%>%
  dplyr::select(Tmin_diff, tpi_50, tpi_500, canopy_height, srad, vs, northness, TWI, CHILI, pr)


brt_minTemp_winter <- gbm.step(data=df_winter, gbm.x = c(2:ncol(df_winter)), gbm.y = 1,
                        family = "gaussian", tree.complexity = 3,  n.minobsinnode = 10,
                        learning.rate = 0.1, bag.fraction = 0.85, max.trees = 50000)

save(brt_minTemp_winter, file="2_pipeline/store/models/brt_minTemp_winter.rData")

summary(brt_minTemp_winter)

varimp.brt_minTemp_winter <- as.data.frame(brt_minTemp_winter$contributions)
names(varimp.brt_minTemp_winter)[2] <- "brt_minTemp_winter"
cvstats.brt_minTemp_winter<- as.data.frame(brt_minTemp_winter$cv.statistics[c(1,3)])
cvstats.brt_minTemp_winter$deviance.null <- brt_minTemp_winter$self.statistics$mean.null
cvstats.brt_minTemp_winter$deviance.explained <- (cvstats.brt_minTemp_winter$deviance.null-cvstats.brt_minTemp_winter$deviance.mean)/cvstats.brt_minTemp_winter$deviance.null
cvstats.brt_minTemp_winter$model_name<-"minTemp_winter"

#########################
df_spring<-data_sub_spring%>%
  dplyr::select(Tmin_diff, tpi_50, tpi_500, canopy_height, srad, vs, northness, TWI, CHILI, pr)


brt_minTemp_spring <- gbm.step(data=df_spring, gbm.x = c(2:ncol(df_spring)), gbm.y = 1,
                        family = "gaussian", tree.complexity = 3,  n.minobsinnode = 10,
                        learning.rate = 0.1, bag.fraction = 0.85, max.trees = 50000)

save(brt_minTemp_spring, file="2_pipeline/store/models/brt_minTemp_spring.rData")

summary(brt_minTemp_spring)

varimp.brt_minTemp_spring <- as.data.frame(brt_minTemp_spring$contributions)
names(varimp.brt_minTemp_spring)[2] <- "brt_minTemp_spring"
cvstats.brt_minTemp_spring<- as.data.frame(brt_minTemp_spring$cv.statistics[c(1,3)])
cvstats.brt_minTemp_spring$deviance.null <- brt_minTemp_spring$self.statistics$mean.null
cvstats.brt_minTemp_spring$deviance.explained <- (cvstats.brt_minTemp_spring$deviance.null-cvstats.brt_minTemp_spring$deviance.mean)/cvstats.brt_minTemp_spring$deviance.null
cvstats.brt_minTemp_spring$model_name<-"minTemp_spring"

#########################
df_fall<-data_sub_fall%>%
  dplyr::select(Tmin_diff, tpi_50, tpi_500, canopy_height, srad, vs, northness, TWI, CHILI, pr)


brt_minTemp_fall <- gbm.step(data=df_fall, gbm.x = c(2:ncol(df_fall)), gbm.y = 1,
                        family = "gaussian", tree.complexity = 3,  n.minobsinnode = 10,
                        learning.rate = 0.1, bag.fraction = 0.85, max.trees = 50000)

save(brt_minTemp_fall, file="2_pipeline/store/models/brt_minTemp_fall.rData")

summary(brt_minTemp_fall)

varimp.brt_minTemp_fall <- as.data.frame(brt_minTemp_fall$contributions)
names(varimp.brt_minTemp_fall)[2] <- "brt_minTemp_fall"
cvstats.brt_minTemp_fall<- as.data.frame(brt_minTemp_fall$cv.statistics[c(1,3)])
cvstats.brt_minTemp_fall$deviance.null <- brt_minTemp_fall$self.statistics$mean.null
cvstats.brt_minTemp_fall$deviance.explained <- (cvstats.brt_minTemp_fall$deviance.null-cvstats.brt_minTemp_fall$deviance.mean)/cvstats.brt_minTemp_fall$deviance.null
cvstats.brt_minTemp_fall$model_name<-"minTemp_fall"
```

#### Combine results

``` r
cvstats_brt_all<-rbind(cvstats.brt_maxTemp_summer, cvstats.brt_maxTemp_fall, cvstats.brt_maxTemp_winter, cvstats.brt_maxTemp_spring,  cvstats.brt_meanTemp_tuned_1, cvstats.brt_meanTemp_tuned_2,cvstats.brt_meanTemp_tuned_3, cvstats.brt_meanTemp_tuned_4, cvstats.brt_minTemp_tuned_1, cvstats.brt_minTemp_tuned_2, cvstats.brt_minTemp_tuned_3, cvstats.brt_minTemp_tuned_4)%>%
  dplyr::select(c(5, 1:4))

save(cvstats_brt_all, file="3_output/tables/cvstats_brt_all.rData")

varimp_brt_all<-varimp.brt_meanTemp_tuned_1%>%
  left_join(varimp.brt_meanTemp_tuned_2, by="var")%>%
  left_join(varimp.brt_meanTemp_tuned_3, by="var")%>%
  left_join(varimp.brt_meanTemp_tuned_4, by="var")%>%
  left_join(varimp.brt_maxTemp_tuned_1, by="var")%>%
  left_join(varimp.brt_maxTemp_tuned_2, by="var")%>%
  left_join(varimp.brt_maxTemp_tuned_3, by="var")%>%
  left_join(varimp.brt_maxTemp_tuned_4, by="var")%>%
  left_join(varimp.brt_minTemp_tuned_1, by="var")%>%
  left_join(varimp.brt_minTemp_tuned_2, by="var")%>%
  left_join(varimp.brt_minTemp_tuned_3, by="var")%>%
  left_join(varimp.brt_minTemp_tuned_4, by="var")


save(varimp_brt_all, file="3_output/tables/varimp_brt_all.rData")


### Season models

cvstats_brt_seasons<-rbind(cvstats.brt_maxTemp_allSeasons, cvstats.brt_maxTemp_summer, cvstats.brt_maxTemp_fall, cvstats.brt_maxTemp_winter, cvstats.brt_maxTemp_spring, cvstats.brt_meanTemp_allSeasons, cvstats.brt_meanTemp_summer, cvstats.brt_meanTemp_fall,cvstats.brt_meanTemp_winter, cvstats.brt_meanTemp_spring, cvstats.brt_minTemp_allSeasons, cvstats.brt_minTemp_summer, cvstats.brt_minTemp_fall, cvstats.brt_minTemp_winter, cvstats.brt_minTemp_spring)%>%
  dplyr::select(c(5, 1:4))

cvstats_brt_seasons <- data.frame(lapply(cvstats_brt_seasons, function(x) {
                  gsub("tuned_3", "allSeasons", x)
              }))
save(cvstats_brt_seasons, file="3_output/tables/cvstats_brt_seasons.rData")

varimp_brt_seasons<-varimp.brt_meanTemp_allSeasons%>%
  left_join(varimp.brt_meanTemp_summer, by="var")%>%
  left_join(varimp.brt_meanTemp_fall, by="var")%>%
  left_join(varimp.brt_meanTemp_winter, by="var")%>%
  left_join(varimp.brt_meanTemp_spring, by="var")%>%
  left_join(varimp.brt_maxTemp_allSeasons, by="var")%>%
  left_join(varimp.brt_maxTemp_summer, by="var")%>%
  left_join(varimp.brt_maxTemp_fall, by="var")%>%
  left_join(varimp.brt_maxTemp_winter, by="var")%>%
  left_join(varimp.brt_maxTemp_spring, by="var")%>%
  left_join(varimp.brt_minTemp_summer, by="var")%>%
  left_join(varimp.brt_minTemp_allSeasons, by="var")%>%
  left_join(varimp.brt_minTemp_fall, by="var")%>%
  left_join(varimp.brt_minTemp_winter, by="var")%>%
  left_join(varimp.brt_minTemp_spring, by="var")

save(varimp_brt_seasons, file="3_output/tables/varimp_brt_seasons.rData")
```

## Predicted offset raster

Use `1_code/r_notebooks/modelling_offset_raster.Rmd`.

``` r
library(dismo)
library(raster)
library(gbm)
```

from <https://rspatial.org/raster/sdm/9_sdm_brt.html>

### Load spatial variable rasters

``` r
ts_summer<-raster::brick("0_data/manual/raster_mosaics/time_series_06.tif")

# test<-brick("0_data/external/processed_GEE/time_series_06/neighborhood_rasters_4s_2021_6-0000065536-0000065536.tif")
# names(ts_summer)<-gsub("_mean", "",names(test))

ts_winter<-raster::brick("0_data/manual/raster_mosaics/time_series_12.tif")
ts_spring<-raster::brick("0_data/manual/raster_mosaics/time_series_02.tif")
ts_fall<-raster::brick("0_data/manual/raster_mosaics/time_series_09.tif")

fixed<-raster::brick("0_data/manual/raster_mosaics/fixed.tif")

# create a season dataframe
# There is no raster for season so we'll create a data frame with a constant value to plug into the predict function.
load("0_data/manual/formatted_for_models/data_full.rData")
df<-data_full%>%
  mutate(season_2=as.factor(season_2))%>%
  mutate(season_4=as.factor(season_4))
df5<-df
```

#### Combine raster mosaics

``` r
gee_all_summer<-raster::stack(fixed, ts_summer)
crs(gee_all_summer)<-"EPSG:3348"

gee_all_spring<-stack(fixed, ts_spring)
crs(gee_all_spring)<-"EPSG:3348"

gee_all_winter<-stack(fixed, ts_winter)
crs(gee_all_winter)<-"EPSG:3348"

gee_all_fall<-stack(fixed, ts_fall)
crs(gee_all_winter)<-"EPSG:3348"
```

``` r
## Use smaller study area to test.
# test prediction code on a smaller raster area to reduce processing time

# load("../chapter_1/empirical/0_data/manual/bird/studyarea_big.rData")
# # study_area<-st_transform(c_bb, crs="EPSG:3348")
# # 
# # gee_all_summer_1<-crop(gee_all_summer, study_area)
```

### Difference between mean temperature

#### Summer

``` r
load("2_pipeline/store/models/brt_meanTemp_summer.rData")

# There is no raster for season so we'll create a data frame with a constant value to plug into the predict function.
# season_4 <- factor('Summer', levels = levels(df5$season_4))
# add <- data.frame(season_4)

p_summer <- predict(gee_all_summer, brt_meanTemp_summer,
       n.trees=brt_meanTemp_summer$gbm.call$best.trees, type="response")

names(p_summer)<-"Tmean_diff_summer"

writeRaster(p_summer, file="3_output/offset_rasters/meanTemp_summer_offset.tif", format='GTiff', overwrite=TRUE)
```

#### Fall

``` r
load("2_pipeline/store/models/brt_meanTemp_fall.rData")

# There is no raster for season so we'll create a data frame with a constant value to plug into the predict function.
season_4 <- factor('Fall', levels = levels(df5$season_4))
add <- data.frame(season_4)

p_fall <- predict(gee_all_fall, brt_meanTemp_fall, const=add,
       n.trees=brt_meanTemp_fall$gbm.call$best.trees, type="response")

names(p_fall)<-"Tmean_diff_fall"

writeRaster(p_fall, file="3_output/offset_rasters/meanTemp_fall_offset.tif", format='GTiff', overwrite=TRUE)
```

#### Winter

``` r
load("2_pipeline/store/models/brt_meanTemp_winter.rData")

# There is no raster for season so we'll create a data frame with a constant value to plug into the predict function.
season_4 <- factor('Winter', levels = levels(df5$season_4))
add <- data.frame(season_4)

p_winter <- predict(gee_all_winter, brt_meanTemp_winter, const=add,
       n.trees=brt_meanTemp_winter$gbm.call$best.trees, type="response")

names(p_winter)<-"Tmean_diff_winter"

writeRaster(p_winter, file="3_output/offset_rasters/meanTemp_winter_offset.tif", format='GTiff', overwrite=TRUE)
```

#### Spring

``` r
load("2_pipeline/store/models/brt_meanTemp_spring.rData")

# There is no raster for season so we'll create a data frame with a constant value to plug into the predict function.
season_4 <- factor('Spring', levels = levels(df5$season_4))
add <- data.frame(season_4)

p_spring <- predict(gee_all_spring, brt_meanTemp_spring, const=add,
       n.trees=brt_meanTemp_spring$gbm.call$best.trees, type="response")

names(p_spring)<-"Tmean_diff_spring"

writeRaster(p_spring, file="3_output/offset_rasters/meanTemp_spring_offset.tif", format='GTiff', overwrite=TRUE)
```

### Difference between max temperature

#### Summer

``` r
load("0_data/manual/formatted_for_models/data_full.rData")

df<-data_full%>%
  mutate(season_2=as.factor(season_2))%>%
  mutate(season_4=as.factor(season_4))
df5<-df
```

``` r
load("2_pipeline/store/models/brt_maxTemp_summer.rData")

# There is no raster for season so we'll create a data frame with a constant value to plug into the predict function.
season_4 <- factor('Summer', levels = levels(df5$season_4))
add <- data.frame(season_4)

p_summer <- predict(gee_all_summer, brt_maxTemp_summer, const=add,
       n.trees=brt_maxTemp_summer$gbm.call$best.trees, type="response")

names(p_summer)<-"Tmax_diff_summer"

writeRaster(p_summer, file="3_output/offset_rasters/maxTemp_summer_offset.tif", format='GTiff', overwrite=TRUE)
```

#### Fall

``` r
load("2_pipeline/store/models/brt_maxTemp_fall.rData")

# There is no raster for season so we'll create a data frame with a constant value to plug into the predict function.
season_4 <- factor('Fall', levels = levels(df5$season_4))
add <- data.frame(season_4)

p_fall <- predict(gee_all_fall, brt_maxTemp_fall, const=add,
       n.trees=brt_maxTemp_fall$gbm.call$best.trees, type="response")

names(p_fall)<-"Tmax_diff_fall"

writeRaster(p_fall, file="3_output/offset_rasters/maxTemp_fall_offset.tif", format='GTiff', overwrite=TRUE)
```

#### Winter

``` r
load("2_pipeline/store/models/brt_maxTemp_winter.rData")

# There is no raster for season so we'll create a data frame with a constant value to plug into the predict function.
season_4 <- factor('Winter', levels = levels(df5$season_4))
add <- data.frame(season_4)

p_winter <- predict(gee_all_winter, brt_maxTemp_winter, const=add,
       n.trees=brt_maxTemp_winter$gbm.call$best.trees, type="response")

names(p_winter)<-"Tmax_diff_winter"

writeRaster(p_winter, file="3_output/offset_rasters/maxTemp_winter_offset.tif", format='GTiff', overwrite=TRUE)
```

#### Spring

``` r
load("2_pipeline/store/models/brt_maxTemp_spring.rData")

# There is no raster for season so we'll create a data frame with a constant value to plug into the predict function.
season_4 <- factor('Spring', levels = levels(df5$season_4))
add <- data.frame(season_4)

p_spring <- predict(gee_all_spring, brt_maxTemp_spring, const=add,
       n.trees=brt_maxTemp_spring$gbm.call$best.trees, type="response")

names(p_spring)<-"Tmax_diff_spring"

writeRaster(p_spring, file="3_output/offset_rasters/maxTemp_spring_offset.tif", format='GTiff', overwrite=TRUE)
```

### Difference between min temperature

#### Summer

``` r
load("2_pipeline/store/models/brt_minTemp_summer.rData")

# There is no raster for season so we'll create a data frame with a constant value to plug into the predict function.
# season_4 <- factor('Summer', levels = levels(df5$season_4))
# add <- data.frame(season_4)

p_summer <- predict(gee_all_summer, brt_minTemp_summer,
       n.trees=brt_minTemp_summer$gbm.call$best.trees, type="response")

names(p_summer)<-"Tmin_diff_summer"

writeRaster(p_summer, file="3_output/offset_rasters/minTemp_summer_offset.tif", format='GTiff', overwrite=TRUE)
```

#### Fall

``` r
load("2_pipeline/store/models/brt_minTemp_fall.rData")

# There is no raster for season so we'll create a data frame with a constant value to plug into the predict function.
season_4 <- factor('Fall', levels = levels(df5$season_4))
add <- data.frame(season_4)

p_fall <- predict(gee_all_fall, brt_minTemp_fall, const=add,
       n.trees=brt_minTemp_fall$gbm.call$best.trees, type="response")

names(p_fall)<-"Tmin_diff_fall"

writeRaster(p_fall, file="3_output/offset_rasters/minTemp_fall_offset.tif", format='GTiff', overwrite=TRUE)
```

#### Winter

``` r
load("2_pipeline/store/models/brt_minTemp_winter.rData")

# There is no raster for season so we'll create a data frame with a constant value to plug into the predict function.
# season_4 <- factor('Winter', levels = levels(df5$season_4))
# add <- data.frame(season_4)

p_winter <- predict(gee_all_winter, brt_minTemp_winter,
       n.trees=brt_minTemp_winter$gbm.call$best.trees, type="response")

names(p_winter)<-"Tmin_diff_winter"

writeRaster(p_winter, file="3_output/offset_rasters/minTemp_winter_offset.tif", format='GTiff', overwrite=TRUE)
```

#### Spring

``` r
load("2_pipeline/store/models/brt_minTemp_spring.rData")

# There is no raster for season so we'll create a data frame with a constant value to plug into the predict function.
season_4 <- factor('Spring', levels = levels(df5$season_4))
add <- data.frame(season_4)

p_spring <- predict(gee_all_spring, brt_minTemp_spring, const=add,
       n.trees=brt_minTemp_spring$gbm.call$best.trees, type="response")

names(p_spring)<-"Tmin_diff_spring"

writeRaster(p_spring, file="3_output/offset_rasters/minTemp_spring_offset.tif", format='GTiff', overwrite=TRUE)
```

``` r
load("2_pipeline/store/models/brt_minTemp_tuned_3.rData")
```

## Combine predictive rasters into a single multi band raster

## Validate

Use `1_code/r_notebooks/modelling_validate_model.Rmd`.

# References

<div id="refs" class="references csl-bib-body hanging-indent">

<div id="ref-estevoTopographicVegetationDrivers2022" class="csl-entry">

Estevo, Cesar A., Diana Stralberg, Scott E. Nielsen, and Erin Bayne.
2022. “Topographic and Vegetation Drivers of Thermal Heterogeneity Along
the Boreal–Grassland Transition Zone in Western Canada: Implications for
Climate Change Refugia.” *Ecology and Evolution* 12 (6): e9008.
https://doi.org/<https://doi.org/10.1002/ece3.9008>.

</div>

<div id="ref-wood2017dtdf" class="csl-entry">

Wood, Wendy H, Shawn J Marshall, Shannon E Fargey, and Terri L
Whitehead. 2017. “Daily Temperature Data from the Foothills Climate
Array Mesonet, Canadian Rocky Mountains, 2005-2010.” PANGAEA.
<https://doi.org/10.1594/PANGAEA.880611>.

</div>

</div>

<!--chapter:end:index.Rmd-->
