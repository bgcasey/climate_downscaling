

/////////////////////////////////////////////////////////////////////////
//// landsat
/////////////////////////////////////////////////////////////////////////
var landsat = require("users/bgcasey/climate_downscaling:functions/landsat_functions");


exports.leo7_fn = function(dates, interval, aoi) {
  
  var leo7_ts = function(d1) {
  var start = ee.Date(d1);
  var end = ee.Date(d1).advance(interval, 'month');
  var date_range = ee.DateRange(start, end);
  var date =ee.Date(d1)
  var leo7=ee.ImageCollection('LANDSAT/LE07/C02/T1_L2')
    .filterDate(date_range)
    .map(landsat.applyScaleFactors)
    .map(landsat.mask_cloud_snow) // apply the cloud mask function
    .map(landsat.addNDVI)  // apply NDVI function
    .map(landsat.addNDMI)  // apply NDMI function
    .map(landsat.addEVI)  // apply NDMI function
    .map(landsat.addSAVI)
    .map(landsat.addBSI)
    .map(landsat.addSI)
    .map(landsat.addLAI)
    // .map(function(img){return img.clip(aoi).reproject({crs: 'EPSG:4326', scale:30})})//clip to study area
  return(leo7
        .median()
        .set("date", date,"month", date.get('month'), "year", date.get('year'))
        .select(['NDVI', 'NDMI', 'EVI', 'SAVI', 'BSI', 'SI', 'LAI']))
        ;
  };

  var leo7=ee.ImageCollection((dates).map(leo7_ts))
    .map(function(img){return img.clip(aoi)});
  return leo7;

};




/////////////////////////////////////////////////////////////////////////
//// Snow landsat
/////////////////////////////////////////////////////////////////////////

exports.leo7_snow_fn = function(dates, interval, aoi) {
  
  var leo7_snow_ts = function(d1) {
  var start = ee.Date(d1);
  var end = ee.Date(d1).advance(interval, 'month');
  var date_range = ee.DateRange(start, end);
  var date =ee.Date(d1)
  var leo7=ee.ImageCollection('LANDSAT/LE07/C02/T1_L2')
    .filterDate(date_range)
    .map(landsat.applyScaleFactors)
    .map(landsat.mask_cloud) // apply the cloud mask function
    .map(landsat.addNDSI)  // apply NDSI function
    .map(landsat.addSnow)  // apply Snow function
  return(leo7
        .median()
        .set("date", date,"month", date.get('month'), "year", date.get('year'))
        .select(['NDSI', 'snow']))
        ;
  };
  
  var leo7=ee.ImageCollection((dates).map(leo7_snow_ts))
    .map(function(img){return img.clip(aoi)});
  return leo7;

};


/////////////////////////////////////////////////////////////////////////
//// Terra 
/////////////////////////////////////////////////////////////////////////

exports.terra_fn = function(dates, interval, aoi) {
  
        var terra_ts = function(d1) {
        function applyScaleFactors(image) {
        var bands_1 = image.select('aet',
                                        'def',
                                        'pet',
                                        'soil',
                                        'srad',
                                        'tmmn',
                                        'tmmx').multiply(0.1);
        var bands_01 = image.select('pdsi',
                                    'vpd',
                                    'vs').multiply(0.1);
        var bands_001 = image.select('vap').multiply(0.001);                            
        return image.addBands(bands_1, null, true)
                    .addBands(bands_01, null, true)
                    .addBands(bands_001, null, true);
      }
        var start = ee.Date(d1);
        var end = ee.Date(d1).advance(interval, 'month');
        var date_range = ee.DateRange(start, end);
        var date =ee.Date(d1)
        var terra=ee.ImageCollection('IDAHO_EPSCOR/TERRACLIMATE')
          .filterDate(date_range)
          .map(applyScaleFactors)
        return(terra
              .median()
              .set("date", date,"month", date.get('month'), "year", date.get('year'))
              )
              ;
      };

  var leo7=ee.ImageCollection((dates).map(terra_ts))
    .map(function(img){return img.clip(aoi)});
  return leo7;

};

/////////////////////////////////////////////////////////////////////////
//// NOAA cloud
/////////////////////////////////////////////////////////////////////////

exports.noaa_fn = function(dates, interval, aoi) {
  
        var noaa_ts = function(d1) {
      function applyScaleFactors(image) {
        var bands_1 = image.select('cloud_fraction', 'cloud_probability').multiply(0.00393701).add(0.5);
        return image.addBands(bands_1, null, true);
      }
        var start = ee.Date(d1);
        var end = ee.Date(d1).advance(interval, 'month');
        var date_range = ee.DateRange(start, end);
        var date =ee.Date(d1)
        var noaa=ee.ImageCollection('NOAA/CDR/PATMOSX/V53')
          .select(['cloud_fraction', 'cloud_probability'])
          .filterDate(date_range)
          .map(applyScaleFactors)
        return(noaa
              .median()
              .set("date", date,"month", date.get('month'), "year", date.get('year'))
              )
              ;
      };
      
  var leo7=ee.ImageCollection((dates).map(noaa_ts))
    .map(function(img){return img.clip(aoi)});
  return leo7;

};



