-   <a href="#overview" id="toc-overview">Overview</a>
-   <a href="#ibutton-data" id="toc-ibutton-data">iButton Data</a>
    -   <a href="#gather" id="toc-gather">Gather</a>
        -   <a href="#setup" id="toc-setup">Setup</a>
        -   <a href="#combine-ibutton-data" id="toc-combine-ibutton-data">Combine
            iButton data</a>
        -   <a href="#create-spatial-data-frame-of-ibutton-locations"
            id="toc-create-spatial-data-frame-of-ibutton-locations">Create spatial
            data frame of iButton locations</a>
    -   <a href="#clean" id="toc-clean">Clean</a>
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

## Gather

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

<table>
<thead>
<tr>
<th style="text-align:right;">
X
</th>
<th style="text-align:left;">
Site_StationKey
</th>
<th style="text-align:left;">
Date
</th>
<th style="text-align:left;">
Time
</th>
<th style="text-align:right;">
Temperature
</th>
<th style="text-align:left;">
Date.Time
</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
HL-1-01-1
</td>
<td style="text-align:left;">
2014-06-25
</td>
<td style="text-align:left;">
11:00:01
</td>
<td style="text-align:right;">
19.107
</td>
<td style="text-align:left;">
2014-06-25 11:00:01
</td>
</tr>
<tr>
<td style="text-align:right;">
2
</td>
<td style="text-align:left;">
HL-1-01-1
</td>
<td style="text-align:left;">
2014-06-25
</td>
<td style="text-align:left;">
13:30:01
</td>
<td style="text-align:right;">
14.600
</td>
<td style="text-align:left;">
2014-06-25 13:30:01
</td>
</tr>
<tr>
<td style="text-align:right;">
3
</td>
<td style="text-align:left;">
HL-1-01-1
</td>
<td style="text-align:left;">
2014-06-25
</td>
<td style="text-align:left;">
16:00:01
</td>
<td style="text-align:right;">
17.605
</td>
<td style="text-align:left;">
2014-06-25 16:00:01
</td>
</tr>
<tr>
<td style="text-align:right;">
4
</td>
<td style="text-align:left;">
HL-1-01-1
</td>
<td style="text-align:left;">
2014-06-25
</td>
<td style="text-align:left;">
18:30:01
</td>
<td style="text-align:right;">
18.607
</td>
<td style="text-align:left;">
2014-06-25 18:30:01
</td>
</tr>
<tr>
<td style="text-align:right;">
5
</td>
<td style="text-align:left;">
HL-1-01-1
</td>
<td style="text-align:left;">
2014-06-25
</td>
<td style="text-align:left;">
21:00:01
</td>
<td style="text-align:right;">
17.105
</td>
<td style="text-align:left;">
2014-06-25 21:00:01
</td>
</tr>
<tr>
<td style="text-align:right;">
6
</td>
<td style="text-align:left;">
HL-1-01-1
</td>
<td style="text-align:left;">
2014-06-25
</td>
<td style="text-align:left;">
23:30:01
</td>
<td style="text-align:right;">
13.096
</td>
<td style="text-align:left;">
2014-06-25 23:30:01
</td>
</tr>
</tbody>
</table>
<table>
<thead>
<tr>
<th style="text-align:right;">
X
</th>
<th style="text-align:right;">
Site
</th>
<th style="text-align:right;">
Point
</th>
<th style="text-align:left;">
Project
</th>
<th style="text-align:left;">
iBt_type
</th>
<th style="text-align:left;">
Site_StationKey
</th>
<th style="text-align:right;">
Value
</th>
<th style="text-align:left;">
Date_Time
</th>
<th style="text-align:right;">
N_of_heat_shields_at_station
</th>
<th style="text-align:left;">
old_wrong\_
</th>
<th style="text-align:left;">
Top_ibutton_id
</th>
<th style="text-align:left;">
Bottom_ibutton_id
</th>
<th style="text-align:left;">
Extra_top_ibutton_id
</th>
<th style="text-align:left;">
Extra_bottom_ibutton_id
</th>
<th style="text-align:right;">
Zone
</th>
<th style="text-align:right;">
Easting
</th>
<th style="text-align:right;">
Northing
</th>
<th style="text-align:left;">
Date_deplo
</th>
<th style="text-align:left;">
Time_deplo
</th>
<th style="text-align:left;">
Comments
</th>
<th style="text-align:right;">
Lat
</th>
<th style="text-align:right;">
Long
</th>
<th style="text-align:left;">
Status
</th>
<th style="text-align:left;">
Date_Time_dpl
</th>
<th style="text-align:left;">
Date_Time_rtv
</th>
<th style="text-align:right;">
Month
</th>
<th style="text-align:right;">
Year
</th>
<th style="text-align:right;">
Day
</th>
<th style="text-align:left;">
Month_Year
</th>
<th style="text-align:left;">
New_Site_Key
</th>
<th style="text-align:right;">
week
</th>
<th style="text-align:left;">
extreme
</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
RIVR
</td>
<td style="text-align:left;">
BOT
</td>
<td style="text-align:left;">
RIVR-001-01
</td>
<td style="text-align:right;">
25.090
</td>
<td style="text-align:left;">
2018-05-28 21:01:01
</td>
<td style="text-align:right;">
2
</td>
<td style="text-align:left;">
</td>
<td style="text-align:left;">
9A-2F324B41
</td>
<td style="text-align:left;">
67-2F33FA41
</td>
<td style="text-align:left;">
</td>
<td style="text-align:left;">
74-2F11C641
</td>
<td style="text-align:right;">
12
</td>
<td style="text-align:right;">
519088
</td>
<td style="text-align:right;">
5437719
</td>
<td style="text-align:left;">
5/28/2018 0:00
</td>
<td style="text-align:left;">
16:13
</td>
<td style="text-align:left;">
NA
</td>
<td style="text-align:right;">
49.09203
</td>
<td style="text-align:right;">
-110.7385
</td>
<td style="text-align:left;">
Deployed
</td>
<td style="text-align:left;">
2018-05-28 16:13:00
</td>
<td style="text-align:left;">
2020-08-03 10:53:00
</td>
<td style="text-align:right;">
5
</td>
<td style="text-align:right;">
2018
</td>
<td style="text-align:right;">
28
</td>
<td style="text-align:left;">
5-2018
</td>
<td style="text-align:left;">
RIVR-001-01-BOT
</td>
<td style="text-align:right;">
22
</td>
<td style="text-align:left;">
NA
</td>
</tr>
<tr>
<td style="text-align:right;">
2
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
RIVR
</td>
<td style="text-align:left;">
BOT
</td>
<td style="text-align:left;">
RIVR-001-01
</td>
<td style="text-align:right;">
19.587
</td>
<td style="text-align:left;">
2018-05-28 23:31:01
</td>
<td style="text-align:right;">
2
</td>
<td style="text-align:left;">
</td>
<td style="text-align:left;">
9A-2F324B41
</td>
<td style="text-align:left;">
67-2F33FA41
</td>
<td style="text-align:left;">
</td>
<td style="text-align:left;">
74-2F11C641
</td>
<td style="text-align:right;">
12
</td>
<td style="text-align:right;">
519088
</td>
<td style="text-align:right;">
5437719
</td>
<td style="text-align:left;">
5/28/2018 0:00
</td>
<td style="text-align:left;">
16:13
</td>
<td style="text-align:left;">
NA
</td>
<td style="text-align:right;">
49.09203
</td>
<td style="text-align:right;">
-110.7385
</td>
<td style="text-align:left;">
Deployed
</td>
<td style="text-align:left;">
2018-05-28 16:13:00
</td>
<td style="text-align:left;">
2020-08-03 10:53:00
</td>
<td style="text-align:right;">
5
</td>
<td style="text-align:right;">
2018
</td>
<td style="text-align:right;">
28
</td>
<td style="text-align:left;">
5-2018
</td>
<td style="text-align:left;">
RIVR-001-01-BOT
</td>
<td style="text-align:right;">
22
</td>
<td style="text-align:left;">
NA
</td>
</tr>
<tr>
<td style="text-align:right;">
3
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
RIVR
</td>
<td style="text-align:left;">
BOT
</td>
<td style="text-align:left;">
RIVR-001-01
</td>
<td style="text-align:right;">
17.585
</td>
<td style="text-align:left;">
2018-05-29 02:01:01
</td>
<td style="text-align:right;">
2
</td>
<td style="text-align:left;">
</td>
<td style="text-align:left;">
9A-2F324B41
</td>
<td style="text-align:left;">
67-2F33FA41
</td>
<td style="text-align:left;">
</td>
<td style="text-align:left;">
74-2F11C641
</td>
<td style="text-align:right;">
12
</td>
<td style="text-align:right;">
519088
</td>
<td style="text-align:right;">
5437719
</td>
<td style="text-align:left;">
5/28/2018 0:00
</td>
<td style="text-align:left;">
16:13
</td>
<td style="text-align:left;">
NA
</td>
<td style="text-align:right;">
49.09203
</td>
<td style="text-align:right;">
-110.7385
</td>
<td style="text-align:left;">
Deployed
</td>
<td style="text-align:left;">
2018-05-28 16:13:00
</td>
<td style="text-align:left;">
2020-08-03 10:53:00
</td>
<td style="text-align:right;">
5
</td>
<td style="text-align:right;">
2018
</td>
<td style="text-align:right;">
29
</td>
<td style="text-align:left;">
5-2018
</td>
<td style="text-align:left;">
RIVR-001-01-BOT
</td>
<td style="text-align:right;">
22
</td>
<td style="text-align:left;">
NA
</td>
</tr>
<tr>
<td style="text-align:right;">
4
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
RIVR
</td>
<td style="text-align:left;">
BOT
</td>
<td style="text-align:left;">
RIVR-001-01
</td>
<td style="text-align:right;">
17.085
</td>
<td style="text-align:left;">
2018-05-29 04:31:01
</td>
<td style="text-align:right;">
2
</td>
<td style="text-align:left;">
</td>
<td style="text-align:left;">
9A-2F324B41
</td>
<td style="text-align:left;">
67-2F33FA41
</td>
<td style="text-align:left;">
</td>
<td style="text-align:left;">
74-2F11C641
</td>
<td style="text-align:right;">
12
</td>
<td style="text-align:right;">
519088
</td>
<td style="text-align:right;">
5437719
</td>
<td style="text-align:left;">
5/28/2018 0:00
</td>
<td style="text-align:left;">
16:13
</td>
<td style="text-align:left;">
NA
</td>
<td style="text-align:right;">
49.09203
</td>
<td style="text-align:right;">
-110.7385
</td>
<td style="text-align:left;">
Deployed
</td>
<td style="text-align:left;">
2018-05-28 16:13:00
</td>
<td style="text-align:left;">
2020-08-03 10:53:00
</td>
<td style="text-align:right;">
5
</td>
<td style="text-align:right;">
2018
</td>
<td style="text-align:right;">
29
</td>
<td style="text-align:left;">
5-2018
</td>
<td style="text-align:left;">
RIVR-001-01-BOT
</td>
<td style="text-align:right;">
22
</td>
<td style="text-align:left;">
NA
</td>
</tr>
<tr>
<td style="text-align:right;">
5
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
RIVR
</td>
<td style="text-align:left;">
BOT
</td>
<td style="text-align:left;">
RIVR-001-01
</td>
<td style="text-align:right;">
14.080
</td>
<td style="text-align:left;">
2018-05-29 07:01:01
</td>
<td style="text-align:right;">
2
</td>
<td style="text-align:left;">
</td>
<td style="text-align:left;">
9A-2F324B41
</td>
<td style="text-align:left;">
67-2F33FA41
</td>
<td style="text-align:left;">
</td>
<td style="text-align:left;">
74-2F11C641
</td>
<td style="text-align:right;">
12
</td>
<td style="text-align:right;">
519088
</td>
<td style="text-align:right;">
5437719
</td>
<td style="text-align:left;">
5/28/2018 0:00
</td>
<td style="text-align:left;">
16:13
</td>
<td style="text-align:left;">
NA
</td>
<td style="text-align:right;">
49.09203
</td>
<td style="text-align:right;">
-110.7385
</td>
<td style="text-align:left;">
Deployed
</td>
<td style="text-align:left;">
2018-05-28 16:13:00
</td>
<td style="text-align:left;">
2020-08-03 10:53:00
</td>
<td style="text-align:right;">
5
</td>
<td style="text-align:right;">
2018
</td>
<td style="text-align:right;">
29
</td>
<td style="text-align:left;">
5-2018
</td>
<td style="text-align:left;">
RIVR-001-01-BOT
</td>
<td style="text-align:right;">
22
</td>
<td style="text-align:left;">
NA
</td>
</tr>
<tr>
<td style="text-align:right;">
6
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
RIVR
</td>
<td style="text-align:left;">
BOT
</td>
<td style="text-align:left;">
RIVR-001-01
</td>
<td style="text-align:right;">
16.083
</td>
<td style="text-align:left;">
2018-05-29 09:31:01
</td>
<td style="text-align:right;">
2
</td>
<td style="text-align:left;">
</td>
<td style="text-align:left;">
9A-2F324B41
</td>
<td style="text-align:left;">
67-2F33FA41
</td>
<td style="text-align:left;">
</td>
<td style="text-align:left;">
74-2F11C641
</td>
<td style="text-align:right;">
12
</td>
<td style="text-align:right;">
519088
</td>
<td style="text-align:right;">
5437719
</td>
<td style="text-align:left;">
5/28/2018 0:00
</td>
<td style="text-align:left;">
16:13
</td>
<td style="text-align:left;">
NA
</td>
<td style="text-align:right;">
49.09203
</td>
<td style="text-align:right;">
-110.7385
</td>
<td style="text-align:left;">
Deployed
</td>
<td style="text-align:left;">
2018-05-28 16:13:00
</td>
<td style="text-align:left;">
2020-08-03 10:53:00
</td>
<td style="text-align:right;">
5
</td>
<td style="text-align:right;">
2018
</td>
<td style="text-align:right;">
29
</td>
<td style="text-align:left;">
5-2018
</td>
<td style="text-align:left;">
RIVR-001-01-BOT
</td>
<td style="text-align:right;">
22
</td>
<td style="text-align:left;">
NA
</td>
</tr>
</tbody>
</table>

#### Join iButton data frames

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

## Clean

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
