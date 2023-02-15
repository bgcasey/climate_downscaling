//########################################################################################################
//##### Define Landsat time series functions ##### 
//########################################################################################################

// apply scaling factors
exports.applyScaleFactors =function(image) {
  var opticalBands = image.select('SR_B.').multiply(0.0000275).add(-0.2);
  var thermalBand = image.select('ST_B6').multiply(0.00341802).add(149.0);
  return image.addBands(opticalBands, null, true)
              .addBands(thermalBand, null, true);
}


// cloud and snow mask
exports.mask_cloud_snow =function(image) {
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
exports.addNDVI =function(image) {
  var NDVI = image.normalizedDifference(['SR_B4', 'SR_B3']).rename('NDVI')
  return image.addBands([NDVI])
}

// Function to adding a calculated Normalized Difference Moisture Index (NDMI) band
exports.addNDMI =function(image) {
  var NDMI = image.expression(
        '(NIR - SWIR) / (NIR + SWIR)', {
            'NIR': image.select('SR_B4'),
            'SWIR': image.select('SR_B5'),
        }).rename('NDMI')
  return image.addBands([NDMI])
}

// Function to adding a calculated  Enhanced Vegetation Index (EVI) 
exports.addEVI =function(image) {
  var EVI =image.expression(
        '2.5 * ((NIR - RED) / (NIR + 6 * RED - 7.5 * BLUE + 1))', {
            'NIR': image.select('SR_B4'),
            'RED': image.select('SR_B3'),
            'BLUE': image.select('SR_B1')
        }).rename('EVI')
  return image.addBands([EVI])
};


// Function to adding a calculated  Leaf Area Index (LAI) band
exports.addLAI =function(image) {
  var LAI = image.expression(
        '3.618 *(2.5 * ((NIR - RED) / (NIR + 6 * RED - 7.5 * BLUE + 1)))-0.118', {
            'NIR': image.select('SR_B4'),
            'RED': image.select('SR_B3'),
            'BLUE': image.select('SR_B1')
        }).rename('LAI')
  return image.addBands([LAI])
} 


// Function to adding a calculated Soil Adjusted Vegetation Index (SAVI) band
exports.addSAVI =function(image) {
  var SAVI =image.expression(
        '((NIR - R) / (NIR + R + 0.428)) * (1.428)', {
          'NIR': image.select('SR_B4'),
          'R': image.select('SR_B3')
        }).rename('SAVI')
    return image.addBands([SAVI])
}

// Function to adding a calculated Bare Soil Index (BSI) band
exports.addBSI =function(image) {
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
exports.addSI=function(image) {
  var SI =image.expression(
          '(1 - blue) * (1 - green) * (1 - red)', {
          'blue': image.select('SR_B1'),
          'green': image.select('SR_B2'),
          'red': image.select('SR_B3')
        }).rename('SI')
      return image.addBands([SI])
}


// cloud mask
exports.mask_cloud=function(image){
    var qa = image.select('QA_PIXEL'); 
    var cloudsBitMask = (1 << 3); // Get bit 3: cloud mask
    var cloudShadowBitMask = (1 << 4); // Get bit 4: cloud shadow mask
    var mask = qa.bitwiseAnd(cloudsBitMask).eq(0).and
          (qa.bitwiseAnd(cloudShadowBitMask).eq(0));
    return image.updateMask(mask);
}

// Function to adding a calculated Normalized Difference Snow Index NDSI band
exports.addNDSI=function(image){
  var NDSI = image.normalizedDifference(['SR_B2', 'SR_B5']).rename('NDSI')
  return image.addBands([NDSI])
}

// Function for creating a binary image of snow/not snow.   NDSI values greater than 0 are considered snow
exports.addSnow=function(image){
var snow = image.normalizedDifference(['SR_B2', 'SR_B5']).gt(0.4).rename('snow');
return image.addBands([snow])
}




