//########################################################################################################
//##### Uer defined inputs ##### 
//########################################################################################################

// import ibutton xy locations
var ibuttons = ee.FeatureCollection("projects/ee-bgcasey-climate/assets/RIVR_xy");
print(ibuttons, "ibuttons")

// define a buffer size around point locations
var buf=100

//// set up time steps. In this case we want to extract median monthy spectral indices for a date range
// Define start and end dates
var Date_Start = ee.Date('2015-01-01');
var Date_End = ee.Date('2021-12-01');


var Date_window = ee.Number(30); //creates a 30day/month time step

//########################################################################################################
//##### Buffer points and define study area ##### 
//########################################################################################################

// create buffer around points
var ibuttons= ibuttons.map(function(pt){
    return pt.buffer(buf);
  });


//define study area
var aoi = ibuttons.geometry().bounds().buffer(10000).bounds();

// Map the study area and ibutton locations
var outline = ee.Image().byte().paint({  // get border of study area
  featureCollection: aoi,
  color: 1,
  width: 3
});
Map.centerObject(aoi, 6) // center the map on the study area
Map.addLayer(outline, {palette: ['blue']}, 'AOI')
// add ibutton locations
Map.addLayer(ibuttons,{color: 'bf1b29'}, "iButtons")

//########################################################################################################
//##### Sentinel Indices ##### 
//########################################################################################################


// Create list of dates for time series. It start at the firest of each month in the date range
var n_months = Date_End.difference(Date_Start,'month').round();
var dates = ee.List.sequence(0,n_months,1);
var make_datelist = function(n) {
  return Date_Start.advance(n,'month');
};
dates = dates.map(make_datelist);
print(dates, 'list of dates for time series')


// Function to remove cloud and snow pixels
function maskCloudAndShadows(image) {
  var cloudProb = image.select('MSK_CLDPRB');
  var snowProb = image.select('MSK_SNWPRB');
  var cloud = cloudProb.lt(5);
  var snow = snowProb.lt(5);
  var scl = image.select('SCL'); 
  var shadow = scl.eq(3); // 3 = cloud shadow
  var cirrus = scl.eq(10); // 10 = cirrus
  // Cloud probability less than 5% or cloud shadow classification
  var mask = (cloud.and(snow)).and(cirrus.neq(1)).and(shadow.neq(1));
  return image.updateMask(mask);
}

// Function to adding a calculated Normalized Difference Vegetation Index NDVI band
function addNDVI(image) {
  var NDVI = image.normalizedDifference(['B8', 'B4']).rename('NDVI')
  return image.addBands([NDVI])
}

// Function to adding a calculated Normalized Difference Moisture Index (NDMI) band
function addNDMI(image) {
  var NDMI = image.normalizedDifference(['B8', 'B11']).rename('NDMI')
  return image.addBands([NDMI])
}


// Function to adding a calculated  Enhanced Vegetation Index (EVI) band (Sentinel 2 imagery in EE has been scaled by 10000. Divided by 10000 to adjust for scale factor)
function addEVI(image) {
  var EVI =image.expression(
        '2.5 * ((NIR - RED) / (NIR + 6 * RED - 7.5 * BLUE + 1))', {
            'NIR': image.select('B8').divide(10000),
            'RED': image.select('B4').divide(10000),
            'BLUE': image.select('B2').divide(10000)
        }).rename('EVI')
  return image.addBands([EVI])
}


// Function to adding a calculated  Leaf Area Index (LAI) band
function addLAI(image) {
  var LAI = image.expression(
        '3.618 *(2.5 * ((NIR - RED) / (NIR + 6 * RED - 7.5 * BLUE + 1)))-0.118', {
            'NIR': image.select('B8').divide(10000),
            'RED': image.select('B4').divide(10000),
            'BLUE': image.select('B2').divide(10000)
        }).rename('LAI')
  return image.addBands([LAI])
}  
  


// Function to adding a calculated Soil Adjusted Vegetation Index (SAVI) band
function addSAVI(image) {
  var SAVI =image.expression(
        '((NIR - R) / (NIR + R + 0.428)) * (1.428)', {
          'NIR': image.select('B8').divide(10000),
          'R': image.select('B4').divide(10000)
        }).rename('SAVI')
    return image.addBands([SAVI])
}

// Function to adding a calculated Bare Soil Index (BSI) band
function addBSI(image) {
  var BSI =image.expression(
        '((Red+SWIR) - (NIR+Blue)) / ((Red+SWIR) + (NIR+Blue))', {
          'NIR': image.select('B8'),
          'Red': image.select('B4'),
          'Blue': image.select('B2'),
          'SWIR': image.select('B11') 
        }).rename('BSI')
    return image.addBands([BSI])
}

// Function to adding a calculated Shadow index (SI)
function addSI(image) {
  var SI =image.expression(
          '(1 - blue) * (1 - green) * (1 - red)', {
          'blue': image.select('B2').divide(10000),
          'green': image.select('B3').divide(10000),
          'red': image.select('B4').divide(10000)
        }).rename('SI')
       return image.addBands([SI])
}


// define a function that will extract monthly sentinel data, apply the cloud mask and NDVI functions already defined.
var S2_fn= function(d1) {
  var start = ee.Date(d1);
  var end = ee.Date(d1).advance(1,'month');
  var date_range = ee.DateRange(start,end);
  var date =ee.Date(d1) //set a date a field for each composite image
  var S2 = ee.ImageCollection('COPERNICUS/S2_SR')
    .filterDate(Date_Start, Date_End) // filter to images acquired between the start and end date
    .map(maskCloudAndShadows) // apply the cloud mask function
    .map(addNDVI)  // apply NDVI function
    .map(addNDMI)  // apply NDMI function
    .map(addEVI)  // apply NDMI function
    .map(addSAVI)
    .map(addBSI)
    .map(addSI)
    .map(addLAI)
    .map(function(img){return img.clip(aoi)}); //clip to study area
  return(S2.median().set("date", date,"month", date.get('month'), "year", date.get('year')));
};

print(S2_fn, 'S2_monthly_fn')


//////////////////////////////////////////////////
// Run the sentinel function and add monthly images to an image collection
var S2_monthly_list = dates.map(S2_fn); // get a list of median composite sentinal images by mapping the dates over the above function
print('S2_monthly_list', S2_monthly_list);
var S2_monthly = ee.ImageCollection(S2_monthly_list); // add the list of images to a single image collection
print(S2_monthly, "S2_monthly");
// Map.addLayer(mt, {}, 'mt');


//########################################################################################################
// // ### Extract a time series of indices over each ibutton location ###
//########################################################################################################

// use the map function to apply reduceRegions to every ibutton locations. reduceRegions extract each layer of the 
// image collection to the ibutton locations where as reduceRegion would just process a single layer. 
// Here we selected the ndvi band to map over ibutton locations.
var extracted_values = S2_monthly.select(['NDVI', 'NDMI', 'EVI', 'SAVI', 'BSI', 'SI', 'LAI']).map(function(img) {
  return img.reduceRegions({
    collection: ibuttons,
    reducer: ee.Reducer.mean(), // set the names of output properties to the corresponding band names
    scale: 30,
    tileScale: 2
  }).map(function (featureWithReduction) {
    return featureWithReduction.copyProperties(img); //to get year and month properties from the ERA5 mosaic stack
  });
}).flatten(); //  Flattens collections of collections into a feature collection of those collections

print (extracted_values.limit(10), "extracted_values")


//########################################################################################################
// // ### Save/export elevation data ###
//########################################################################################################

// Export data to a csv
Export.table.toDrive({
  folder: 'google_earth_engine_tables',
  collection: extracted_values,
  description:'ibutton_sentinel_indices',
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
                  'LAI'] 
});









