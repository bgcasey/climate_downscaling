//########################################################################################################
//##### INPUTS ##### 
//########################################################################################################
 
// import ibutton xy locations and  and the study area.
var ibuttons = ee.FeatureCollection("projects/ee-bgcasey-climate/assets/RIVR_xy"),
    aoi = ee.FeatureCollection("projects/ee-bgcasey-climate/assets/study_area");

print(ibuttons, "ibuttons")

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


// TPI equation is ln(α/tanβ)) where α=cumulative upslope drainage area and β is slope 
var slope = ee.Terrain.slope(elv)
var upslopeArea = upslopeArea.multiply(1000000).rename('UpslopeArea') //multiply to conver km^2 to m^2
var slopeRad = slope.divide(180).multiply(Math.PI) //convert degrees to radians
var TWI = (upslopeArea.divide(slopeRad.tan())).rename('TWI')
var logTWI = TWI.log().rename('logTWI')

print(logTWI, "logTWI")
// create a multiband image with all of the terrain metrics
var terrainTWI = elv.addBands([upslopeArea, slope, slopeRad, TWI, logTWI])
print(terrainTWI, "terrainTWI")


//########################################################################################################
// // ### Map ###
//########################################################################################################

Map.addLayer(TWI, {}, "TWI")
Map.addLayer(logTWI, {min: 0, max: 20}, "logTWI")
Map.centerObject(aoi, 6) // center the map on the study area

// add ibutton locations
Map.addLayer(ibuttons,{color: 'bf1b29'}, "iButtons")


// //########################################################################################################
// // // ### Extract the terrain metrics to each ibutton location ###
// //########################################################################################################

var pts_terrainTWI = terrainTWI.reduceRegions({
  collection: ibuttons,
  reducer: ee.Reducer.first()
})
print(pts_terrainTWI.limit(10), 'pts_terrainTWI')


// //########################################################################################################
// // // ### Save/export elevation data ###
// //########################################################################################################

// Export elevation data to a csv
Export.table.toDrive({
  folder: 'google_earth_engine_tables',
  collection: pts_terrainTWI,
  description:'ibutton_TWI',
  fileFormat: 'csv',
    selectors: [ // choose properties to include in export table
                  'Project', 
                  'St_SttK',
                  'logTWI',
                  'TWI',
                  ] 
});
