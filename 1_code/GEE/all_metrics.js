//########################################################################################################
//##### User defined inputs ##### 
//########################################################################################################

// import ibutton xy locations
var ibuttons = ee.FeatureCollection("projects/ee-bgcasey-climate/assets/ss_xy");
print("ibuttons", ibuttons)

// define a buffer size around point locations (for zonal stats)
var buf=30

//// Define start and end dates for time series
var Date_Start = ee.Date('2005-01-01');
var Date_End = ee.Date('2021-12-31');

// var Date_Start = ee.Date('2021-01-01');
// var Date_End = ee.Date('2021-12-31');
 
 
 //set number of months in time interval
var interval=1;

// import shapefile of study area
var study_area= ee.FeatureCollection("projects/ee-bgcasey-climate/assets/alberta_bc");
// var study_area = ee.FeatureCollection("projects/ee-bgcasey-climate/assets/Alberta_boundary");
// var study_area = ee.FeatureCollection("users/bgcasey/studyarea_CL");


//########################################################################################################
//##### Helper functions ##### 
//########################################################################################################

// Get a time series of Landsat images
var ts = require("users/bgcasey/climate_downscaling:functions/timeseries_functions");
var tpi = require("users/bgcasey/climate_downscaling:functions/TPI");
var hli = require('users/bgcasey/climate_downscaling:functions/HLI');

//########################################################################################################
//##### Setup ##### 
//########################################################################################################

// for zonal stats create buffer around points
var ibuttons_buff= ibuttons.map(function(pt){
    return pt.buffer(buf);
  });

var aoi = study_area.geometry().bounds().buffer(10000).bounds();
// var aoi = study_area.geometry()

// convert the geometry to a feature to get the batch.Download.ImageCollection.toDrive function to work
var aoi1=ee.FeatureCollection(aoi)

// Create list of dates for time series. It start at the first of each month in the date range and progress by num_months_in_interval
var n_months = Date_End.difference(Date_Start,'month').round();
var dates = ee.List.sequence(0, n_months, interval);
var make_datelist = function(n) {
  return Date_Start.advance(n,'month');
};
dates = dates.map(make_datelist);

print('list of dates for time series', dates)

//########################################################################################################
//##### Get image collections
//########################################################################################################

////////////////////////////////////////
// Landsat Indices
////////////////////////////////////////
var leo7=ts.leo7_fn(dates, interval, aoi);
print("leo7", leo7)

var leo7_snow=ts.leo7_snow_fn(dates, interval, aoi);
print("leo7_snow", leo7_snow)

////////////////////////////////////////
// Terrain standard
////////////////////////////////////////

var dem = ee.ImageCollection('NRCan/CDEM')
  .mosaic()//combine the tiled image collection into a single image
  .clip(aoi)
  .setDefaultProjection('EPSG:3348')

print("dem", dem)

// Slope. Units are degrees, range is [0,90).
var slope = ee.Terrain.slope(dem);

// Aspect. Units are degrees where 0=N, 90=E, 180=S, 270=W.
var aspect = ee.Terrain.aspect(dem);

// calcuate northness variable. Convert aspect degrees to radians and take the cosine. 
var northness = aspect.multiply(Math.PI).divide(180).cos().rename('northness');

var terrain = dem.addBands(slope)
                  .addBands(northness)
                  .addBands(aspect)
  
////////////////////////////////////////
// TPI
////////////////////////////////////////

// Set TPI window parameters. These have a significant impact on output results.
var radius = 500;
var shape = "circle";
var units = "meters";

// Calculate a TPI image
var tpi_500 = tpi.tpi(dem, radius, shape, units).rename("tpi_500");
print("tpi_500", tpi_500)


// Set TPI window parameters.
var radius = 300;
var shape = "circle";
var units = "meters";

// Calculate a TPI image
var tpi_300 = tpi.tpi(dem, radius, shape, units).rename("tpi_300");
print("tpi_300", tpi_300)


// Set TPI window parameters.
var radius = 100;
var shape = "circle";
var units = "meters";

// Calculate a TPI image
var tpi_100 = tpi.tpi(dem, radius, shape, units).rename("tpi_100");
print("tpi100", tpi_100)

// Set TPI window parameters.
var radius = 50;
var shape = "circle";
var units = "meters";

// Calculate a TPI image
var tpi_50= tpi.tpi(dem, radius, shape, units).rename("tpi_50");
print("tpi50", tpi_50)

////////////////////////////////////////
// Canopy height
////////////////////////////////////////

var canopy_height = ee.Image('users/nlang/ETH_GlobalCanopyHeight_2020_10m_v1')
      .rename("canopy_height")
      .clip(aoi)
      //.setDefaultProjection(L7proj);
print('canopy_height metadata:', canopy_height);

var canopy_standard_deviation = ee.Image('users/nlang/ETH_GlobalCanopyHeightSD_2020_10m_v1')
      .rename('canopy_standard_deviation')
      .clip(aoi)
      //.setDefaultProjection(L7proj);
print('standard_deviation metadata:', canopy_standard_deviation);

//combine bands into single image
var canopy = canopy_height.addBands([canopy_standard_deviation])
print("canopy", canopy)

////////////////////////////////////////
// TWI
////////////////////////////////////////

// # Calculate Topographic wetness index and extract points
var upslopeArea = (ee.Image("MERIT/Hydro/v1_0_1")
    .clip(aoi)
    //.setDefaultProjection(L7proj)
    .select('upa')); //flow accumulation area

var elv = (ee.Image("MERIT/Hydro/v1_0_1")
    .clip(aoi)
    //.setDefaultProjection(L7proj)
    .select('elv'));

// TWI equation is ln(α/tanβ)) where α=cumulative upslope drainage area and β is slope 
var slope = ee.Terrain.slope(elv)
var upslopeArea = upslopeArea.multiply(1000000).rename('UpslopeArea') //multiply to conver km^2 to m^2
var slopeRad = slope.divide(180).multiply(Math.PI).rename('slopeRad') //convert degrees to radians
var TWI = (upslopeArea.divide(slopeRad.tan())).log().rename('TWI')
print("TWI", TWI)


////////////////////////////////////////
// Landcover
////////////////////////////////////////

var LC = ee.Image("COPERNICUS/Landcover/100m/Proba-V-C3/Global/2019")
  .clip(aoi)
print("LC", LC)

////////////////////////////////////////
// Heat load index
////////////////////////////////////////

var HLI = hli.hli(dem);
print("HLI", HLI)

var CHILI = ee.Image('CSP/ERGo/1_0/Global/ALOS_CHILI').rename("CHILI")
  .clip(aoi)
print("CHILI", CHILI)


////////////////////////////////////////
// TERRA
////////////////////////////////////////

var terra=ts.terra_fn(dates, interval, aoi);
print("terra", terra)

////////////////////////////////////////
// NOAA
////////////////////////////////////////

var noaa=ts.noaa_fn(dates, interval, aoi);
print("noaa", noaa)

// //########################################################################################################
// // // ### Merge image collections ###
// //########################################################################################################

var all_fixed = terrain.addBands(CHILI)
              .addBands(TWI)
              .addBands(HLI)
              .addBands(tpi_50)
              .addBands(tpi_100)
              .addBands(tpi_300)
              .addBands(tpi_500)
              .addBands(canopy)
              ;
print("all_fixed", all_fixed)

var all_ts = noaa.combine(terra)
              .combine(leo7)
              .combine(leo7_snow);
print("all_ts", all_ts)

// // //########################################################################################################
// // // // ### Extract data to points ###
// // //########################################################################################################

var ev_fixed = all_fixed.reduceRegions({
  collection: ibuttons_buff,
  reducer: ee.Reducer.mean(),
  crs:'EPSG:3348',
  scale: 30
});
print(ev_fixed.limit(10), "ev")

var ev_LC = LC.reduceRegions({
  collection: ev_fixed,
  crs:'EPSG:3348',
  reducer: ee.Reducer.first(),
  scale: 30
});

print(ev_LC.limit(10), "ev_lc")

var ev_all = all_ts.map(function(img) {
  return img.reduceRegions({
    collection: ev_LC,
    crs:'EPSG:3348',
    reducer: ee.Reducer.mean(), // set the names of output properties to the corresponding band names
    scale: 30,
    tileScale: 4
  }).map(function (featureWithReduction) {
    return featureWithReduction.copyProperties(img); //to get year and month properties from the stack
  });
}).flatten(); //  Flattens collections
 
print(ev_all.limit(10), "ev.all")


// Export data to a csv
Export.table.toDrive({
  folder: 'google_earth_engine_tables',
  collection: ev_all,
  description:'ibutton_all_indices',
  fileFormat: 'csv',
    selectors: [ // choose properties to include in export table
                  'year',
                  'month',
                  'date',
                  'Project', 
                  'St_SttK',
                  'NDVI',
                  'EVI',
                  'NDMI',
                  'SAVI',
                  'BSI',
                  'SI',
                  'LAI',
                  'NDSI',
                  'snow',
                  'discrete_classification',
                  'forest_type',
                  'tree-coverfraction',
                  'elevation',
                  'slope',
                  'aspect',
                  'tpi_50',
                  'tpi_100',
                  'tpi_300',
                  'tpi_500',
                  'TWI',
                  'HLI',
                  'CHILI',
                  'northness',
                  'canopy_height',
                  'canopy_standard_deviation',
                  'cloud_fraction',
                  'cloud_probability',
                  'soil',
                  'srad',
                  'vs'
                  ] 
});


// //########################################################################################################
// // // // ### Focal statistics via reduceNeighborhood ###
// // //########################################################################################################


var all_ts_n= all_ts.map(function(img) {
return img.reduceNeighborhood({
    reducer: ee.Reducer.mean(), // set the names of output properties to the corresponding band names
    kernel: ee.Kernel.square(30, "meters"),
    }).copyProperties(img)
}); 

print("all_ts_n", all_ts_n)

var all_fixed_n= all_fixed.reduceNeighborhood({
    reducer: ee.Reducer.mean(), // set the names of output properties to the corresponding band names
    kernel: ee.Kernel.square(30, "meters"),
    });

print("all_fixed_n", all_fixed_n)


// // //########################################################################################################
// // // // ### Download rasters ###
// // //########################################################################################################

/////// #### ORIGINAL ####

// Export.image.toDrive({ 
//   image: all_fixed.toFloat(),
//   description: 'all_fixed',
//   folder: 'raster_csd',
//   crs:'EPSG:3348',
//   scale: 30,
//   region: aoi1,
//   maxPixels: 6000000000
// });

// var batch = require('users/fitoprincipe/geetools:batch')

// batch.Download.ImageCollection.toDrive(all_ts, 'raster_csd', 
//                 {name:'rasters_{year}_{month}',
//                 scale: 30,
//                 crs:'EPSG:3348',
//                 region:aoi1,
//                 maxPixels: 6000000000
// });


/////// #### NEIGHBORHOOD ####

// Export.image.toDrive({ 
//   image: all_fixed_n.toFloat(),
//   description: 'neighborhood_all_fixed',
//   folder: 'raster_csd',
//   crs:'EPSG:3348',
//   scale: 30,
//   region: aoi1,
//   maxPixels: 6000000000
// });

// var batch = require('users/fitoprincipe/geetools:batch')

// batch.Download.ImageCollection.toDrive(all_ts_n, 'raster_csd', 
//                 {name:'neighborhood_rasters_{year}_{month}',
//                 scale: 30,
//                 crs:'EPSG:3348',
//                 region:aoi1,
//                 maxPixels: 6000000000
// });

