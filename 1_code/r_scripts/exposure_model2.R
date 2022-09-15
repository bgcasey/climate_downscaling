#Code to create model of 'exposure' offset for climate downscaling
#other variable are in google earth engine at the moment
#Kimblerly Morrison July 28 2022
library(sf)
library(raster)
library(plyr) 
library(data.table)
library(stringr)
library(microclima)



######################################## INPUTS ####################################################################
#Only input info here
climNA_dir<-"C:/Users/kimorris/ClimateNA_v730/" #where exe is stored
working_dir<-"C:/Users/kimorris/ClimateNA_v730/ibutton/" #file where all outputs will go
#ibutton_csv<-""

##################################################################################################################################################
#Load in ibutton data
#Avg_Monthly
#Avg_daily_minima
#import clean csv of ibutton data with missing data filled in, outliers removed and meaned by month
ib<-read.csv("W:/EDM/CCVegMod4/Downscaling/Cesar Data/doi_10.5061_dryad.f7m0cfxw2__v6/dataforglmms_summer_winter_imputted.csv")
tmax<-as.data.frame(cbind(ib$Avg_daily_maxima,ib$Lat,ib$Long,ib$Month,ib$Year,ib$Site_StationKey,1.5,"north","holden"))#put in north aspect.  in open grasslands no aspect?
colnames(tmax)<-c("tmax","lat","long",'month',"year","group","sensor_height","sensor_aspect","sensor_shield")
head(tmax)

#Do tmax first then tmin
#get elevation

#Right now use automicroclima package and extent of ibutton locations

#make csv of ibuttons into spatial data
tmax_unique<-tmax[!duplicated(tmax[,c('group')]),]
tmax_sp <- st_as_sf(tmax_unique, coords = c("long", "lat"), crs = 'EPSG:4326')
#write ponts shapefile for google earth engine
st_write(tmax_sp,paste0(working_dir, "ibutton_locations.shp"))

#use microclima package to get DEM at ibutton extent with 100m butter (otherwise some points have no values)
#DEM can be as low as 30m but it runs way to slow and this is only being used to extract elevation
tmax_sp <- st_transform(tmax_sp, crs=3978)
#add buffer to ensure extent of DEM includes all points
tmax_buf<-st_buffer(tmax_sp,100)
st_write(tmax_buf, paste0(working_dir, "study_area.shp"))
plot(tmax_buf)
e <- extent(tmax_buf) #maybe add to extent to ensure no NAs
r <- raster(e)
res(r) <- 100
crs(r) <- "+init=epsg:3978"
dem <- get_dem(r, resolution = 100)
writeRaster(dem,paste0(working_dir,'test_dem2.tif'))

elev<-extract(dem,tmax_sp)
tmax_elev<-cbind(tmax_sp,elev)
head(tmax_elev)
tmax_elev_t<-as.data.frame(tmax_elev)
head(tmax_elev_t)
#tmax_elev_t2<-tmax_elev_t[c(tmax_elev_t$group,tmax_elev_t$elev)]
tmax_elev_t2<-subset(tmax_elev_t,select=c("group","elev"))
tmax2<-merge(tmax,tmax_elev_t2,by="group",all.x=T)
#just checking to see if everything merged fine
nrow(tmax_elev_t2)
nrow(tmax)
nrow(tmax2)


#prepare tmax for input into climNA (the climateNA exe requires the file to be in the following format)
tmax_ClimNA<-as.data.frame(cbind(tmax2$group,"region1",tmax2$lat,tmax2$long,tmax2$elev))
head(tmax_ClimNA)
colnames(tmax_ClimNA)<-c("ID1","ID2","lat","long","el")
tmax_ClimNA_unique<-tmax_ClimNA[!duplicated(tmax_ClimNA[,c('ID1')]),]
tmax_ClimNA_unique$lat<-as.numeric(tmax_ClimNA_unique$lat)
tmax_ClimNA_unique$long<-as.numeric(tmax_ClimNA_unique$long)
tmax_ClimNA_unique$el<-as.numeric(tmax_ClimNA_unique$el)
head(tmax_ClimNA_unique)
#overwrites existing
write.csv(tmax_ClimNA_unique,"C:/Users/kimorris/ClimateNA_v730/ibutton/temp_input.csv", row.names = FALSE)
 


#Do I want to model straight ibutton temp, differenceof ibutton minus climNA or standardize short veg flat areas as 0 change after model created?
#or compare ibuttons to close weather stations
#Start with ibutton-ClimNA
#Load ClimateNA Normals 


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



#link to Google Earth Engine to 
#followed http://www.css.cornell.edu/faculty/dgr2/_static/files/R_html/ex_rgee.html
## install`reticulate`, only one time
if (!("reticulate" %in% installed.packages()[,1])) {
  print("Installing package `reticulate`...")
  install.packages("reticulate")
} else { 
  print("Package `reticulate` already installed") }

library(reticulate)
Sys.which("python3")   # system default

#need python 3 to work
use_python(Sys.which("python3"))  # use it

# install -- one time
## development version -- use with caution
# remotes::install_github("r-spatial/rgee")
## stable version on CRAN
if (!("rgee" %in% installed.packages()[,1])) {
  print("Installing package `rgee`...")
  install.packages("rgee")
} else
{ print("Package `rgee` already installed") }

library(rgee)

rgee::ee_install() #When you are asked if you want to store environment variables, answer Y

#if instalation fails try this to point to Python3
rgee::ee_install_set_pyenv(py_path = "/usr/bin/python3", py_env="rgee"). (#change path as needed)

#test
# use the standard Python numeric library
np <- reticulate::import("numpy", convert = FALSE)
# do some array manipulations with NumPy
a <- np$array(c(1:4))
print(a)  # this should be a Python array


