// Run this script using the Earth Engine code editor at code.earthengine.google.com


//########################################################################################################
//##### User defined inputs ##### 
//############################################################################


// import ibutton xy locations
var ibuttons = ee.FeatureCollection("projects/ee-bgcasey-climate/assets/ss_xy");
print("ibuttons", ibuttons)


var CHILI = ee.Image('CSP/ERGo/1_0/Global/ALOS_CHILI').rename("CHILI");
print("CHILI", CHILI)
var b1scale = CHILI.select('CHILI').projection().nominalScale();
print('CHILI scale:', b1scale);  // ee.Number


// define a buffer size around point locations (for zonal stats)
var buf=30

// //########################################################################################################
// //##### Buffer points and define study area ##### 
// //########################################################################################################


// for zonal stats create buffer around points
var ibuttons_buff= ibuttons.map(function(pt){
    return pt.buffer(buf);
  });

//define study area
var aoi = ibuttons.geometry().bounds().buffer(10000).bounds();
// var region_t = ibuttons.getInfo()
print("aoi", aoi)

// convert the geometry to a feature to get the batch.Download.ImageCollection.toDrive function to work
var aoi1=ee.FeatureCollection(aoi)
print("aoi1", aoi1)


//########################################################################################################
// // ### Extract the terrain metrics to each ibutton location ###
//########################################################################################################

var pts_CHILI = CHILI.reduceRegions({
  collection: ibuttons_buff,
  scale: 30,
  reducer: ee.Reducer.mean()
})
print('pts_CHILI', pts_CHILI.limit(10))

// Export data to a csv
Export.table.toDrive({
  folder: 'google_earth_engine_tables',
  collection: pts_CHILI,
  description:'ibutton_CHILI',
  fileFormat: 'csv',
    selectors: [ // choose properties to include in export table
                  'Project', 
                  'St_SttK',
                  'mean'
                  ] 
});


// // ########################################################################################################
// // // ### Focal statistics via reduceNeighborhood ###
// //########################################################################################################


var neighborhood= CHILI.reduceNeighborhood({
    reducer: ee.Reducer.mean(), // set the names of output properties to the corresponding band names
    kernel: ee.Kernel.circle(30, "meters")
})
print("canopy neighborhood", neighborhood)

Export.image.toDrive({ 
  image: neighborhood,
  description: 'CHILI_neighborhood',
  folder: 'neighborhood_rasters',
  scale: 30,
  region: aoi,
  maxPixels: 116856502500,
});

var pts_CHILI_neighborhood = neighborhood.reduceRegions({
  collection: ibuttons,
  reducer: ee.Reducer.first()
})
print('pts_CHILI_neighborhood', pts_CHILI.limit(10))


// Export data to a csv
Export.table.toDrive({
  folder: 'google_earth_engine_tables',
  collection: pts_CHILI_neighborhood,
  description:'ibutton_CHILI_neighborhood',
  fileFormat: 'csv',
    selectors: [ // choose properties to include in export table
                  'Project', 
                  'St_SttK',
                  'mean'
                  ] 
});

