//########################################################################################################
//##### INPUTS ##### 
//########################################################################################################

// import ibutton xy locations and  and the study area.
var ibuttons = ee.FeatureCollection("projects/ee-bgcasey-climate/assets/RIVR_xy_buf"),
    aoi = ee.FeatureCollection("projects/ee-bgcasey-climate/assets/study_area");

// Import image collection. Here we are using the ERA5 monthly summaries
var era5_complete = ee.ImageCollection("ECMWF/ERA5/MONTHLY");                       


//########################################################################################################
//##### Filter image collection ##### 
//########################################################################################################

// Clip to the study area
// To clip all images in an image collection, create a function to crop with table boundaries
var table_bounds = function(image) {
  // Crop by table extension
  return image.clip(aoi);
};
var era5_aoi =era5_complete.map(table_bounds);

// Visualize
var dataset = ee.ImageCollection("ECMWF/ERA5/MONTHLY");

var visualization = {
  bands: ['mean_2m_air_temperature'],
  min: 250.0,
  max: 320.0,
  palette: [
    "#000080","#0000D9","#4000FF","#8000FF","#0080FF","#00FFFF",
    "#00FF80","#80FF00","#DAFF00","#FFFF00","#FFF500","#FFDA00",
    "#FFB000","#FFA400","#FF4F00","#FF2500","#FF0A00","#FF00FF",
  ]
};
Map.centerObject(aoi, 6)
Map.addLayer(era5_aoi, visualization, "Monthly average air temperature [K] at 2m height");
Map.addLayer(ibuttons,{color: 'bf1b29'}, "iButtons")

print(era5_aoi, 'era5_aoi')

//filter to specifc years and summer months only
var era5_filterYr = era5_aoi.filter(ee.Filter.calendarRange(2015,2022,'year'));
//.filter(ee.Filter.calendarRange(6,8,'month'));
print(era5_filterYr, 'era5_filterYr')


//########################################################################################################
// // ### Get a time series of ERA5 over each ibutton location ###
//########################################################################################################

// use the map function to apply reduceRegions to every ibutton locations. reduceRegions extract each layer of the 
// image collection to the ibutton locations where as reduceRegion would just process a single layer. 

var regionalTemp = era5_filterYr.map(function(img) {
  return img.reduceRegions({
    collection: ibuttons,
    reducer: ee.Reducer.mean(),
    scale: 30,
  }).map(function (featureWithReduction) {
    return featureWithReduction.copyProperties(img); //to get year and month properties from the ERA5 mosaic stack
  });
}).flatten(); //  Flattens collections of collections into a feature collection of those collections

print (regionalTemp.limit(10), "regionalTemp")


//########################################################################################################
// // ### Save/export time series data ###
//########################################################################################################

// Export ERA5 variables to a csv
Export.table.toDrive({
  folder: 'google_earth_engine_tables',
  collection: regionalTemp,
  description:'ibutton_timeSeries_ERA5',
  fileFormat: 'csv',
    selectors: [ // choose properties to include in export table
                  'year', 
                  'month', 
                  'Project', 
                  'St_SttK',
                  'dewpoint_2m_temperature', 
                  'maximum_2m_air_temperature', 
                  'mean_2m_air_temperature', 
                  'mean_sea_level_pressure', 
                  'minimum_2m_air_temperature', 
                  'surface_pressure', 
                  'total_precipitation', 
                  'u_component_of_wind_10m', 
                  'v_component_of_wind_10m'] 
});


