// https://gis.stackexchange.com/questions/363058/calculating-area-of-snow-cover-in-gee

var collection = ee.ImageCollection('COPERNICUS/S2') 
  .filter(ee.Filter.lt("CLOUDY_PIXEL_PERCENTAGE", 10)) 
  .filterDate('2020-04-01' ,'2020-04-27') 
  .filterBounds(polygon) ;


print(collection) ;

  //Let's centre the map view over our ROI
Map.centerObject(polygon, 13);
var medianpixels = collection.median(); // This finds the median value of all the pixels which meet the criteria. 

var medianpixelsclipped = medianpixels.clip(polygon).divide(10000);
// Now visualise the mosaic as a natural colour image. 
Map.addLayer(medianpixelsclipped, {bands: ['B4', 'B3', 'B2'], min: 0, max: 1, gamma: 1.5}, 'Sentinel_2 mosaic',false);

// User specified parameters

// setup Visualization
var viz = {min:-0.50, max:0.75, palette:['red', 'green', 'orange', 'white']};

// Data
// calculate ndsi
var ndsi = medianpixelsclipped.normalizedDifference(['B3', 'B11']);
var scale=30;
Map.addLayer(ndsi, {min:0.4, max:1, palette:['EB984E ','FDFEFE  ']}, 'ndsi');
var reducer = ndsi.reduceRegion({
reducer: ee.Reducer.sum(),
geometry: polygon,
scale: 30,
maxPixels: 1E13
});
// km square
var area = ee.Number(reducer.get('NDSI')).multiply(scale).multiply(scale).divide(1000000);
print('area of ndsi ', area.getInfo() + ' km2');


