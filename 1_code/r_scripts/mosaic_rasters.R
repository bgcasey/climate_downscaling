library(raster)
library(terra)
library(dplyr)
library(foreach)
library(stringr)


# List the folders containg rasters. 
# This below directory contains multiple folders, each containing rasters that need to be stitched together into a mosaic. 
bl<-list.dirs(path="0_data/external/GEE_rasters/", full.names = T, recursive = T)

#set temp directory to an external drive to free up harddrive space
rasterOptions(tmpdir=file.path("../r_tmp")) 

# Apply a function to each of the folders in the list

foreach (j = 1:length(bl)) %do%
  {
    t1 = proc.time()
    print(paste("---- Begin",bl[j], Sys.time()))
    #list .tif files in the folder
    fl <- list.files(path=paste0("0_data/external/GEE_rasters/", bl[j]), pattern = '*.tif$', recursive = T, full.names = T)
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
    ## Crop mosaic to a study area.
    # x<-raster::crop(x, study_area) # crop raster to study area
    # print(paste("----",bl[j]," crop complete", Sys.time())) 
    x<-terra::rast(x) # preserve band names when savinbg by converting the stack to a rast object from the terra package.
    writeRaster(x, filename=paste0("0_data/manual/raster_mosaics/",bl[j], ".tif"),  overwrite=T)
    print(paste("----",bl[j]," saved as TIFF", Sys.time()))
    print("process time")
    print(proc.time() - t1)
    removeTmpFiles(0) #The raster package can store a lot of files. This removes any temp raster files generated   during the loop
  }