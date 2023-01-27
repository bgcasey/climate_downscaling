//########################################################################################################
//##### User defined inputs ##### 
//############################################################################


// import ibutton xy locations
var ibuttons = ee.FeatureCollection("projects/ee-bgcasey-climate/assets/ss_xy");
print("ibuttons", ibuttons)

// define a buffer size around point locations (for zonal stats)
var buf=30

//// set up time steps. In this case we want to extract median monthy spectral indices for a date range
// Define start and end dates
var Date_Start = ee.Date('2005-01-01');
var Date_End = ee.Date('2022-01-01');

var num_months_in_interval=3;

// //########################################################################################################
// //##### Buffer points and define study area ##### 
// //########################################################################################################


// for zonal stats create buffer around points
var ibuttons_buff= ibuttons.map(function(pt){
    return pt.buffer(buf);
  });

//define study area
// var aoi = ibuttons.geometry().bounds().buffer(10000).bounds();
// // var region_t = ibuttons.getInfo()
// print("aoi", aoi)



// albert provicial boundary
var alberta = ee.FeatureCollection("projects/ee-bgcasey-climate/assets/Alberta_boundary");


// Create geometry object,for study area
var geometry = alberta.geometry();
print(geometry, "geometry");
//Map.addLayer(geometry);

// defin e a geometry - there are lots of ways to do this, see the GEE User guide
var aoi = geometry

// convert the geometry to a feature to get the batch.Download.ImageCollection.toDrive function to work
var aoi1=ee.FeatureCollection(aoi)
print("aoi1", aoi1)

// //########################################################################################################
// //##### Get image collections
// //########################################################################################################







//########################################################################################################
//##### Define Landsat time series functions ##### 
//########################################################################################################

// apply scaling factors
function applyScaleFactors(image) {
  var opticalBands = image.select('SR_B.').multiply(0.0000275).add(-0.2);
  var thermalBand = image.select('ST_B6').multiply(0.00341802).add(149.0);
  return image.addBands(opticalBands, null, true)
              .addBands(thermalBand, null, true);
}


// cloud and snow mask
function mask_cloud_snow(image) {
    var qa = image.select('QA_PIXEL'); 
    var cloudsBitMask = (1 << 3); // Get bit 3: cloud mask
    var cloudShadowBitMask = (1 << 4); // Get bit 4: cloud shadow mask
    var snowBitMask = (1 << 5); // Get bit 5: snow mask
    var mask = qa.bitwiseAnd(cloudsBitMask).eq(0).and
          (qa.bitwiseAnd(cloudShadowBitMask).eq(0)).and
          (qa.bitwiseAnd(snowBitMask).eq(0));
return image.updateMask(mask);
}


// Function to adding a calculated Normalized Difference Vegetation Index NDVI band
function addNDVI(image) {
  var NDVI = image.normalizedDifference(['SR_B4', 'SR_B3']).rename('NDVI')
  return image.addBands([NDVI])
}

// Function to adding a calculated Normalized Difference Moisture Index (NDMI) band
function addNDMI(image) {
  var NDMI = image.expression(
        '(NIR - SWIR) / (NIR + SWIR)', {
            'NIR': image.select('SR_B4'),
            'SWIR': image.select('SR_B5'),
        }).rename('NDMI')
  return image.addBands([NDMI])
}

// Function to adding a calculated  Enhanced Vegetation Index (EVI) 
function addEVI(image) {
  var EVI =image.expression(
        '2.5 * ((NIR - RED) / (NIR + 6 * RED - 7.5 * BLUE + 1))', {
            'NIR': image.select('SR_B4'),
            'RED': image.select('SR_B3'),
            'BLUE': image.select('SR_B1')
        }).rename('EVI')
  return image.addBands([EVI])
}


// Function to adding a calculated  Leaf Area Index (LAI) band
function addLAI(image) {
  var LAI = image.expression(
        '3.618 *(2.5 * ((NIR - RED) / (NIR + 6 * RED - 7.5 * BLUE + 1)))-0.118', {
            'NIR': image.select('SR_B4'),
            'RED': image.select('SR_B3'),
            'BLUE': image.select('SR_B1')
        }).rename('LAI')
  return image.addBands([LAI])
}  
  

// Function to adding a calculated Soil Adjusted Vegetation Index (SAVI) band
function addSAVI(image) {
  var SAVI =image.expression(
        '((NIR - R) / (NIR + R + 0.428)) * (1.428)', {
          'NIR': image.select('SR_B4'),
          'R': image.select('SR_B3')
        }).rename('SAVI')
    return image.addBands([SAVI])
}

// Function to adding a calculated Bare Soil Index (BSI) band
function addBSI(image) {
  var BSI =image.expression(
        '((Red+SWIR) - (NIR+Blue)) / ((Red+SWIR) + (NIR+Blue))', {
          'NIR': image.select('SR_B4'),
          'Red': image.select('SR_B3'),
          'Blue': image.select('SR_B1'),
          'SWIR': image.select('SR_B5') 
        }).rename('BSI')
    return image.addBands([BSI])
}

// Function to adding a calculated Shadow index (SI)
function addSI(image) {
  var SI =image.expression(
          '(1 - blue) * (1 - green) * (1 - red)', {
          'blue': image.select('SR_B1'),
          'green': image.select('SR_B2'),
          'red': image.select('SR_B3')
        }).rename('SI')
      return image.addBands([SI])
}


//#######################################################################################################
//##### Map a list of dates through the above functions to create an image time series ##### 
//########################################################################################################

// Create list of dates for time series. It start at the firest of each month in the date range
var n_months = Date_End.difference(Date_Start,'month').round();
var dates = ee.List.sequence(0, n_months, num_months_in_interval);
var make_datelist = function(n) {
  return Date_Start.advance(n,'month');
};
dates = dates.map(make_datelist);

print(dates, 'list of dates for time series')


// function that can be used to map the dates list through the  above function. 
var leo7_fn = function(d1) {
  var start = ee.Date(d1);
  var end = ee.Date(d1).advance(num_months_in_interval, 'month');
  var date_range = ee.DateRange(start, end);
  var date =ee.Date(d1)
  var leo7=ee.ImageCollection('LANDSAT/LE07/C02/T1_L2')
    .filterDate(date_range)
    .map(applyScaleFactors)
    .map(mask_cloud_snow) // apply the cloud mask function
    .map(addNDVI)  // apply NDVI function
    .map(addNDMI)  // apply NDMI function
    .map(addEVI)  // apply NDMI function
    .map(addSAVI)
    .map(addBSI)
    .map(addSI)
    .map(addLAI)
    .map(function(img){return img.clip(aoi).reproject({crs: 'EPSG:4326', scale:30})})//clip to study area
  return(leo7
        .median()
        .set("date", date,"month", date.get('month'), "year", date.get('year'))
        .select(['NDVI', 'NDMI', 'EVI', 'SAVI', 'BSI', 'SI', 'LAI']))
        ;
};


var leo7_monthly_list = dates.map(leo7_fn);
print("leo7_monthly_list", leo7_monthly_list);
var leo7_monthly = ee.ImageCollection(leo7_monthly_list); // add the list of images to a single image collection
print("leo7_monthly", leo7_monthly);


// Get information about the Landsat projection.
var leo7 = ee.Image(leo7_monthly.first())
    .select('EVI');
var leo7Projection = leo7.projection();
print('Landsat projection:', leo7Projection);

var landsat_resample = function(image){
  return image
    .reduceResolution({
      reducer: ee.Reducer.mean(),
      maxPixels: 30
    })
    // Request the data at the scale and projection of the mage.
    .reproject({
      crs: leo7Projection
    })
    .copyProperties(image)
}




// //########################################################################################################
// //##### Canopy
// //########################################################################################################
var canopy_height = ee.Image('users/nlang/ETH_GlobalCanopyHeight_2020_10m_v1').rename("canopy_height");
print('canopy_height metadata:', canopy_height);
var b1scale = canopy_height.select('canopy_height').projection().nominalScale();
print('canopy_height 1 scale:', b1scale);  // ee.Number

var canopy_standard_deviation = ee.Image('users/nlang/ETH_GlobalCanopyHeightSD_2020_10m_v1').rename('canopy_standard_deviation');
print('standard_deviation metadata:', canopy_standard_deviation);
var b1scale = canopy_standard_deviation.select('canopy_standard_deviation').projection().nominalScale();
print('standard_deviation scale:', b1scale);  // ee.Number

//combine bands into single image
var canopy = canopy_height.addBands([canopy_standard_deviation])
print("canopy", canopy)


var canopy2 = canopy.reproject({crs: 'EPSG:4326', scale:30}).clip(aoi)

var b1scale = canopy2.projection().nominalScale();
print('canopy2 scale:', b1scale);  // ee.Number


// map(function(im){
//   var reproject=im;
//   return reproject;
// });

print("canopy2", canopy2)

// var canopy_standard_deviation = canopy2.select('canopy_height')
// Map.addLayer(canopy_standard_deviation, {}, "canopy_standard_deviation")
// Map.centerObject(aoi, 6) // center the map on the study area


//########################################################################################################
// // ### TWI ###
//########################################################################################################

// # Calculate Topographic wetness index and extract points
var upslopeArea = (ee.Image("MERIT/Hydro/v1_0_1")
    .clip(aoi)
    .select('upa')) //flow accumulation area

var elv = (ee.Image("MERIT/Hydro/v1_0_1")
    .clip(aoi)
    .select('elv'))

var hnd = (ee.Image("MERIT/Hydro/v1_0_1")
    .clip(aoi)
    .select('hnd'))

print('All metadata:', upslopeArea);


// TPI equation is ln(α/tanβ)) where α=cumulative upslope drainage area and β is slope 
var slope = ee.Terrain.slope(elv)
var upslopeArea = upslopeArea.multiply(1000000).rename('UpslopeArea') //multiply to conver km^2 to m^2
var slopeRad = slope.divide(180).multiply(Math.PI).rename('slopeRad') //convert degrees to radians
var TWI = (upslopeArea.divide(slopeRad.tan())).log().rename('TWI')
//var logTWI = TWI.log().rename('logTWI')
 


print(TWI, "TWI")
// create a multiband image with all of the terrain metrics
var terrainTWI = elv.addBands([upslopeArea, slope, slopeRad, TWI, hnd]).resample('bilinear').reproject({crs: 'EPSG:4326',
scale: 30.0})
print(terrainTWI, "terrainTWI")
var b1scale = terrainTWI.projection().nominalScale();
print('terrainTWI scale', b1scale);  // ee.Number


// var TWI = terrainTWI.select('TWI')
// Map.addLayer(TWI, {}, "TWI")
// Map.centerObject(aoi, 6) // center the map on the study area


//########################################################################################################
// // ### Copernicus landcover classification data ###
//########################################################################################################

// import Copernicus landcover classification data
var LC = ee.Image("COPERNICUS/Landcover/100m/Proba-V-C3/Global/2019")
  .clip(aoi)
  .resample('bilinear').reproject({crs:'EPSG:4326', scale:30});
print("LC", LC)

var b1scale = LC.projection().nominalScale();
print('LC', b1scale);  // ee.Number

// var LC_dc = LC.select('discrete_classification');
// Map.addLayer(LC_dc, {}, "TLC_dc")
// Map.centerObject(aoi, 6) // center the map on the study area



//########################################################################################################
// // ### Terrain ###
//########################################################################################################
var dem = ee.ImageCollection('NRCan/CDEM')
  .mosaic()//combine the tiled image collection into a single image
  .clip(aoi)// clip to the study area
  .reproject({crs: 'EPSG:4326', scale:30})

print("dem", dem)



var b1scale = dem.projection().nominalScale();
print('dem scale', b1scale);  // ee.Number



// Slope. Units are degrees, range is [0,90).
var slope = ee.Terrain.slope(dem);

// Aspect. Units are degrees where 0=N, 90=E, 180=S, 270=W.
var aspect = ee.Terrain.aspect(dem);

// var northness = aspect.cos().rename("northness"); 

// calcuate northness variable. Convert aspect degrees to radians and take the cosine. 
var northness = aspect.multiply(Math.PI).divide(180).cos().rename('northness')

// function to calculate neighborhood metrics for elevation
var calculateNeighborhoodMean = function(image, kernelRadius) {
      return image.reduceNeighborhood({
        reducer: ee.Reducer.mean(),
        kernel: ee.Kernel.square(kernelRadius,'pixels',false),
        optimization: 'boxcar',
      });
    }

// function to calculate TPI
var calculateTPI = function(image, meanImage) {
      return image.subtract(meanImage).rename('TPI')
    }

// define a kernal radius for the neighborhood function
var kernelRadius = 180 // define kernal radius

// create an elevation neighborhood raster
var demMean = calculateNeighborhoodMean(dem, kernelRadius);

// calculate TPI usimng the dem and neighborhood dem.
var TPI = calculateTPI(dem, demMean);

//////////
// Heat load index
////////////
var hli_f = require('users/bgcasey/climate_downscaling:HLI');
var HLI = hli_f.hli(dem);


// create a multiband image with all of the terrain metrics
var terrain = dem.addBands([slope, aspect, TPI, HLI, northness])

print(terrain, "terrain")





// var terrainResample = terrain.reduceResolution({
//       reducer: ee.Reducer.mean(),
//       maxPixels: 30
//     })
//     // Request the data at the scale and projection of the MODIS image.
//     .reproject({
//       crs:'EPSG:4326'
//     });
// print(terrainResample, "terrainResample")


// var TPIa = terrainResample.select('slope')
// Map.addLayer(TPIa, {}, "TPI")
// Map.centerObject(aoi, 6) // center the map on the study area

























//########################################################################################################
// // ### Merge image collections ###
//########################################################################################################
// var mergedCollection = terrainTWI.addBands([canopy2, LC, terrain]);
// var mergedCollection = terrainTWI.addBands([canopy2]).addBands([terrain]).addBands([LC]);
var mergedCollection = terrainTWI.addBands([terrain])

print("mergedCollection", mergedCollection)

// var mergedCollection2 = leo7_monthly.merge(mergedCollection);
// print("mergedCollection2", mergedCollection2)


var bandtypes = mergedCollection.bandTypes()
print("bandtypes", bandtypes)


//########################################################################################################
// // ### Plot ###
//########################################################################################################

// Map.addLayer(slope, {min: 0, max: 89.99}, 'Slope');
// Map.addLayer(aspect, {min: 0, max: 359.99}, 'Aspect');
// Map.addLayer(dem, {min:-300, max:3500}, "dem")
// Map.addLayer(TPI, {min:-2000, max:3500}, "tpi_270")
// Map.addLayer(HLI, {}, "HLI")
// Map.centerObject(aoi, 6) // center the map on the study area

// var height= mergedCollection.select('elevation')
// Map.addLayer(height, {}, "TPI")
// Map.centerObject(aoi, 6) // center the map on the study area



Export.image.toDrive({ 
  image: mergedCollection.toFloat(),
  description: 'mergedCollection',
  folder: 'neighborhood_rasters',
  scale: 30,
  // region: aoi,
  maxPixels: 116856502500,
});





