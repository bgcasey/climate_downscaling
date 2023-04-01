
// //########################################################################################################
// //##### Import assets ##### 
// //########################################################################################################

var study_area= ee.FeatureCollection("projects/ee-bgcasey-climate/assets/alberta_bc");
var aoi = study_area.geometry();

// import ibutton xy locations
var ibuttons = ee.FeatureCollection("projects/ee-bgcasey-climate/assets/ss_xy");
// print("ibuttons", ibuttons)

var temperature_offsets = ee.Image("projects/ee-bgcasey-climate/assets/temperature_offsets");

// offset rasters
var meanTemp_summer_offset = ee.Image("projects/ee-bgcasey-climate/assets/meanTemp_summer_offset").rename("meanTemp_summer").multiply(-1);
// var meanTemp_fall_offset = ee.Image("projects/ee-bgcasey-climate/assets/meanTemp_fall_offset").rename("meanTemp_fall").multiply(-1);
// var meanTemp_winter_offset = ee.Image("projects/ee-bgcasey-climate/assets/meanTemp_winter_offset").rename("meanTemp_winter").multiply(-1);
// var meanTemp_spring_offset = ee.Image("projects/ee-bgcasey-climate/assets/meanTemp_spring_offset").rename("meanTemp_spring").multiply(-1);

var maxTemp_summer_offset = ee.Image("projects/ee-bgcasey-climate/assets/maxTemp_summer_offset").rename("maxTemp_summer").multiply(-1);
var maxTemp_summer_offset_orig = ee.Image("projects/ee-bgcasey-climate/assets/maxTemp_summer_offset").rename("maxTemp_summer");
print(maxTemp_summer_offset, "maxTemp_summer_offset")
print(maxTemp_summer_offset_orig, "maxTemp_summer_offset_orig")

// var maxTemp_fall_offset = ee.Image("projects/ee-bgcasey-climate/assets/maxTemp_fall_offset").rename("maxTemp_fall").multiply(-1);
// var maxTemp_winter_offset = ee.Image("projects/ee-bgcasey-climate/assets/maxTemp_winter_offset").rename("maxTemp_winter").multiply(-1);
// var maxTemp_spring_offset = ee.Image("projects/ee-bgcasey-climate/assets/maxTemp_spring_offset").rename("maxTemp_spring").multiply(-1);

var minTemp_summer_offset = ee.Image("projects/ee-bgcasey-climate/assets/minTemp_summer_offset").rename("minTemp_summer").multiply(-1);
// var minTemp_fall_offset = ee.Image("projects/ee-bgcasey-climate/assets/minTemp_fall_offset").rename("minTemp_fall").multiply(-1);
var minTemp_winter_offset = ee.Image("projects/ee-bgcasey-climate/assets/minTemp_winter_offset").rename("minTemp_winter").multiply(-1);
// var minTemp_spring_offset = ee.Image("projects/ee-bgcasey-climate/assets/minTemp_spring_offset").rename("minTemp_spring").multiply(-1);

var temperature_offsets=meanTemp_summer_offset
        // .addBands(meanTemp_fall_offset)
        // .addBands(meanTemp_winter_offset)
        // .addBands(meanTemp_spring_offset)
        .addBands(maxTemp_summer_offset)
        // .addBands(maxTemp_fall_offset)
        // .addBands(maxTemp_winter_offset)
        // .addBands(maxTemp_spring_offset)
        .addBands(minTemp_winter_offset)
        // .addBands(maxTemp_spring_offset)
        .addBands(minTemp_summer_offset)
        ;
// print("temperature_offsets", temperature_offsets)


// var temperature_offsets=temperature_offsets
        // .addBands(meanTemp_summer_offset)
        // .addBands(meanTemp_fall_offset)
        // .addBands(meanTemp_winter_offset)
        // .addBands(meanTemp_spring_offset)
        // .addBands(maxTemp_summer_offset)
        // .addBands(maxTemp_fall_offset)
        // .addBands(maxTemp_winter_offset)
        // .addBands(minTemp_spring_offset)
        // .addBands(minTemp_winter_offset)
        // .addBands(maxTemp_spring_offset)
        // ;
// print("temperature_offsets", temperature_offsets)


//mask to study area
// Construct binary image which is 1 everywhere but the geometry
var boundaryMask= ee.Image.constant(0).paint(aoi, 1);
// Apply to existing image's mask
var temperature_offsets = temperature_offsets.updateMask(temperature_offsets.mask().multiply(boundaryMask));

Export.image.toAsset({
      image:temperature_offsets,
      assetId: "temperature_offsets_2",
      scale:30,
      crs:'EPSG:3348',
      maxPixels:503235344584,
    })

// var temperature_offsets = ee.Image("projects/ee-bgcasey-climate/assets/temperature_offsets");
// print("temperature_offsets",  temperature_offsets)

// hillshade layer
var dem = ee.Image("projects/ee-bgcasey-climate/assets/ncan_dem_ABBC");
// Export.image.toAsset({
//       image:dem, 
//       scale:10,
//     minPixels:503235344584,
//     })
var exaggeration = 10;
// var hillshade360 = ee.Terrain.hillshade(dem.multiply(exaggeration), 360);  
// var hillshade315 = ee.Terrain.hillshade(dem.multiply(exaggeration), 315, 35);  
// var hillshade270 = ee.Terrain.hillshade(dem.multiply(exaggeration), 270);  
// var hillshade225 = ee.Terrain.hillshade(dem.multiply(exaggeration), 225);  
// var hillshade180 = ee.Terrain.hillshade(dem.multiply(exaggeration), 180);  
// var hillshade135= ee.Terrain.hillshade(dem.multiply(exaggeration), 135);  
// var hillshade90= ee.Terrain.hillshade(dem.multiply(exaggeration), 90);  
// var hillshade45 = ee.Terrain.hillshade(dem.multiply(exaggeration), 45);  

var hillshade = ee.Terrain.hillshade({
  input:dem.multiply(exaggeration), 
  azimuth:315, 
  elevation:35});  

var hillshade_ly=ui.Map.Layer(hillshade, {},'NRCan DEM Hillshade')

// var all_fixed = ee.Image("projects/ee-bgcasey-climate/assets/all_fixed");
// print(all_fixed)

// //########################################################################################################
// //##### vis_meanualization parameters ##### 
// //########################################################################################################

////////////////////////////////////////
// Offset layers
////////////////////////////////////////

var palettes = require('users/gena/packages:palettes');
var palette = palettes.cmocean.Balance[7];
// var palette2 = palettes.crameri.vik[50];
// var vis = {min: -9, max: 9, palette: palette};
var vis_mean = {min: -2.5, max: 2.5, palette: palette};
var vis_max = {min: -10, max: -3.5, palette: palette};
var vis_min = {min: -2, max: 5.7, palette: palette};
////////////////////////////////////////
// Points visualization
////////////////////////////////////////

// Style points according the project property
var projectStyles = ee.Dictionary({
  WOOD: {color: 'e41a1c', pointSize: 2, pointShape: 'circle'},
  RIVR: {color: '377eb8', pointSize: 2, pointShape: 'circle'},
  alex: {color: '4daf4a', pointSize: 2, pointShape: 'circle'},
  HL: {color: '984ea3', pointSize: 2, pointShape: 'circle'}
});

// Add feature-specific style properties to each feature based on fuel type.
var fc = ibuttons.map(function(feature) {
  return feature.set('style', projectStyles.get(feature.get('Project')));
});

// Style the FeatureCollection according to each feature's "style" property.
var ibuttons_vis = fc.style({
  styleProperty: 'style',
  neighborhood: 8  // maximum "pointSize" + "width" among features
});

// //########################################################################################################
// //##### Set ui map layers ##### 
// //########################################################################################################

// var meanTemp_summer = ui.Map.Layer(ee.Image("projects/ee-bgcasey-climate/assets/temperature_offsets")
//         .select('meanTemp_summer'),
//         vis, "mean summer temperature offset")
//         .setShown(0).setOpacity(.7)
        
var meanTemp_summer = ui.Map.Layer(ee.Image("projects/ee-bgcasey-climate/assets/temperature_offsets")
        .select('meanTemp_summer'),
        vis_mean, "summer mean temperature offset")
        .setShown(1).setOpacity(.7)        
// var meanTemp_fall = ui.Map.Layer(ee.Image("projects/ee-bgcasey-climate/assets/temperature_offsets")
//         .select('meanTemp_fall'),
//         vis, "mean fall temperature offset")
//         .setShown(0).setOpacity(.7)
// var meanTemp_winter = ui.Map.Layer(ee.Image("projects/ee-bgcasey-climate/assets/temperature_offsets")
//         .select('meanTemp_winter'),
//         vis, "mean winter temperature offset")
//         .setShown(0).setOpacity(.7)
// var meanTemp_spring = ui.Map.Layer(ee.Image("projects/ee-bgcasey-climate/assets/temperature_offsets")
//         .select('meanTemp_spring'),
//         vis, "mean spring temperature offset")
//         .setShown(0).setOpacity(.7)

var maxTemp_summer = ui.Map.Layer(ee.Image("projects/ee-bgcasey-climate/assets/temperature_offsets")
        .select('maxTemp_summer'),
        vis_max, "summer max temperature offset")
        .setShown(1).setOpacity(.7)
        
       
// var maxTemp_fall = ui.Map.Layer(ee.Image("projects/ee-bgcasey-climate/assets/temperature_offsets")
//         .select('maxTemp_fall'),
//         vis, "max fall temperature offset")
//         .setShown(0).setOpacity(.7)
// var maxTemp_winter = ui.Map.Layer(ee.Image("projects/ee-bgcasey-climate/assets/temperature_offsets")
//         .select('maxTemp_winter'),
//         vis, "max winter temperature offset")
//         .setShown(0).setOpacity(.7)
// var maxTemp_spring = ui.Map.Layer(ee.Image("projects/ee-bgcasey-climate/assets/temperature_offsets")
//         .select('maxTemp_spring'),
//         vis, "max spring temperature offset")
//         .setShown(0).setOpacity(.7)
        
var minTemp_summer = ui.Map.Layer(ee.Image("projects/ee-bgcasey-climate/assets/temperature_offsets")
        .select('minTemp_summer'),
        vis_min, "summer min temperature offset")
        .setShown(1).setOpacity(.7)


// var minTemp_fall = ui.Map.Layer(ee.Image("projects/ee-bgcasey-climate/assets/temperature_offsets")
//         .select('minTemp_fall'),
//         vis, "min fall temperature offset")
//         .setShown(0).setOpacity(.7)
var minTemp_winter = ui.Map.Layer(ee.Image("projects/ee-bgcasey-climate/assets/temperature_offsets")
        .select('minTemp_winter'),
        vis_min, "winter min temperature offset")
        .setShown(1).setOpacity(.7)

// var minTemp_winter = ui.Map.Layer(ee.Image("projects/ee-bgcasey-climate/assets/minTemp_winter_offset"),
//         vis, "min summer temperature offset")
//         .setShown(0).setOpacity(.7)

// var minTemp_spring = ui.Map.Layer(ee.Image("projects/ee-bgcasey-climate/assets/temperature_offsets")
//         .select('minTemp_spring'),
//         vis, "min spring temperature offset")
//         .setShown(0).setOpacity(.7)        


var ibuttons_ui = ui.Map.Layer(ibuttons_vis, null, 'iButtons').setShown(0);

// //########################################################################################################
// //##### Set Map ui ##### 
// //########################################################################################################

// add layers to map panel
//CHILI
// var alosChili = all_fixed.select('CHILI');
// var alosChiliVis = {
//   min: 0.0,
//   max: 255.0,
// palette: palettes.crameri.lajolla[10]
// };
// // Map.addLayer(alosChili, alosChiliVis, 'Continuous Heat-Insolation Load Index').setShown(0);

// var alosChili=ui.Map.Layer(alosChili)

// // TWI
// var TWI = all_fixed.select('TWI');
// var TWI_Vis = {
//   min: -3,
//   max: 30,
//   palette: palettes.kovesi.linear_bmw_5_95_c86[7]
// };
// Map.addLayer(TWI, TWI_Vis, 'Topographic Wetness index').setShown(0);

// // canopy height
// var canopy_height = all_fixed.select('canopy_height');
// var forestCanopyHeightVis = {
//   min: 0.0,
//   max: 50.0,
//   palette:palettes.cmocean.Thermal[7]
//   // palette: [
//   //   'ffffff', 'fcd163', '99b718', '66a000', '3e8601', '207401', '056201',
//   //   '004c00', '011301'
//   // ],
// };
// Map.addLayer(canopy_height, forestCanopyHeightVis, 'Forest Canopy Height').setShown(0);

// // canopy standard deviation
// var canopy_standard_deviation = all_fixed.select('canopy_standard_deviation');
// var forestCanopyHeightVis = {
//   min: 0.0,
//   max: 15,
//   palette:palettes.cmocean.Tempo[7]
// };

// Map.addLayer(canopy_standard_deviation, forestCanopyHeightVis, 'Forest Canopy Standard Deviation').setShown(0);

// // TPI 50
// var tpi_50 = all_fixed.select('tpi_50');
// var TPI_Vis = {
//   min: -0.2,
//   max: 2
//   // palette:palettes.cmocean.Gray[7].reverse()
// };
// Map.addLayer(tpi_50, TPI_Vis, 'Topographic Position Index (50m)').setShown(0);

// // TPI 500
// var tpi_500 = all_fixed.select('tpi_500');
// var TPI_Vis = {
//   min: -26,
//   max: 26
//   // palette:palettes.cmocean.Gray[7].reverse()
// };
// Map.addLayer(tpi_500, TPI_Vis, 'Topographic Position Index (500m)').setShown(0);


// hillshade
// Map.addLayer(hillshade360, null, 'hillshade360').setShown(1);
// Map.addLayer(hillshade315_15, null, 'hillshade315_15').setShown(1);
// Map.addLayer(hillshade315_25, null, 'hillshade315_25').setShown(1);
// Map.addLayer(hillshade315_35, null, 'hillshade315_35').setShown(1);
// Map.addLayer(hillshade315_45, null, 'hillshade315_45').setShown(1);
// Map.addLayer(hillshade315_55, null, 'hillshade315_55').setShown(1);
// Map.addLayer(hillshade315_65, null, 'hillshade315_65').setShown(1);
// Map.addLayer(hillshade315_75, null, 'hillshade315_75').setShown(1);

// Map.addLayer(hillshade315, null, 'hillshade315').setShown(1);

// Map.addLayer(hillshade270, null, 'hillshade270').setShown(1);
// Map.addLayer(hillshade225, null, 'hillshade225').setShown(1);
// Map.addLayer(hillshade180, null, 'hillshade180').setShown(1);
// Map.addLayer(hillshade135, null, 'hillshade135').setShown(1);
// Map.addLayer(hillshade90, null, 'hillshade90').setShown(1);
// Map.addLayer(hillshade45, null, 'hillshade45').setShown(1);
// Map.addLayer(hillshade, null, 'ncan_dem_hillshade').setShown(1);

// offset layers


// // Map.add(meanTemp_fall)
// // Map.add(meanTemp_winter)
// // Map.add(meanTemp_spring)

// Map.add(maxTemp_summer)
// // Map.add(maxTemp_fall)
// // Map.add(maxTemp_winter)
// // Map.add(maxTemp_spring)

// // Map.add(minTemp_summer)
// // Map.add(minTemp_fall)
// Map.add(minTemp_winter)
// Map.add(minTemp_spring)

// ibuttons


Map.add(hillshade_ly)
Map.add(meanTemp_summer)
print(meanTemp_summer)
print(meanTemp_summer.getEeObject())

Map.add(ibuttons_ui)

Map.setCenter (-122.81174713947657, 54.783344009340574, 5.5) // center the map on the study area

// -120.49478641570207,55.02524277898975
// //########################################################################################################
// //##### Legend ##### 
// //########################################################################################################

////////////////////////////////////////
// Raster Legend
////////////////////////////////////////

var legend_raster = ui.Panel({
  style: {
    padding: '8px 30px'
  }
});

// var legend_ibutton = ui.Panel({
//   style: {
//     position: 'bottom-right',
//     padding: '8px 15px'
//   }
// });

// Create legend title
// var legendTitle = ui.Label({
//   value: 'iButton Projects',
//   style: {
//     fontWeight: 'bold',
//     fontSize: '12px',
//     margin: '0 0 20px 0',
//     }
// });

// Add legend title
var legendTitle = ui.Label({
  value: 'Temperature offset (C)',
  style: {fontWeight: 'bold',
          fontSize: '12px',
          margin: '0 0 0px 7px',
  }
});

// Add the title to the panel
legend_raster.add(legendTitle);

var palette = palettes.cmocean.Balance[7].reverse();
// Creates a color bar thumbnail image for use in legend from the given color palette.
function makeColorBarParams(palette) {
  return {
    bbox: [0, 0, 0.01, 1],
    dimensions: '20x70',
    // bbox: [0, 0, 1, 0.1],
    // dimensions: '100x10',
    format: 'png',
    min: 0,
    max: 1,
    palette: palette  
  };
}


// create multple legends for mean, max and min

// Create the color bar for the legend.
var colorBar_mean = ui.Thumbnail({
  image: ee.Image.pixelLonLat().select('latitude'),
  params: makeColorBarParams(vis_mean.palette),
  style: {stretch: 'vertical', margin: '0px 0px', maxHeight: '100px'},
});

colorBar_mean.style().set({
    padding: '0px 8px'})

// Create a panel with three numbers for the legend.
var legendLabels_mean = ui.Panel({
  widgets: [
    ui.Label(vis_mean.min, {margin: '0px 0px',fontSize: '10px'}),
    ui.Label(
        ((vis_mean.max-vis_mean.min) / 2+vis_mean.min),
        {margin: '30px 4px', textAlign: 'center', stretch: 'vertical', fontSize: '10px'}),
    ui.Label(vis_mean.max, {margin: '4px 4px', fontSize: '10px'})
    ],
  layout: ui.Panel.Layout.flow('vertical'),
});
legendLabels_mean.style().set({
    position: 'top-right', padding: '0px 5px'
  });
  
var legend_mean=ui.Panel({
        widgets: [colorBar_mean, legendLabels_mean],
        layout: ui.Panel.Layout.Flow('horizontal')
      })

var legendSubTitle_mean = ui.Label({
  value: 'mean',
  style: {fontWeight: 'bold',
          fontSize: '10px'
  }
});

legendSubTitle_mean.style().set({
    padding: '0px 0px'})



var legend_mean_2=ui.Panel({
        widgets: [legendSubTitle_mean, legend_mean],
        // layout: ui.Panel.Layout.Flow('vertical'),
        style: {
          margin: '0px 15px 0 0',
  }
      })
      
///////

// Create the color bar for the legend.
var colorBar_min = ui.Thumbnail({
  image: ee.Image.pixelLonLat().select('latitude'),
  params: makeColorBarParams(vis_mean.palette),
  style: {stretch: 'vertical', margin: '0px 0px', maxHeight: '100px'},
});

colorBar_min.style().set({
    padding: '0px 8px'})
  
var legendLabels_min = ui.Panel({
  widgets: [
    ui.Label(vis_min.min, {margin: '0px 0px',fontSize: '10px'}),
    ui.Label(
        ((vis_min.max-vis_min.min) / 2+vis_min.min),
        {margin: '30px 4px', textAlign: 'center', stretch: 'vertical', fontSize: '10px'}),
    ui.Label(vis_min.max, {margin: '4px 4px', fontSize: '10px'})
    ],
  layout: ui.Panel.Layout.flow('vertical'),
});
legendLabels_min.style().set({
    position: 'top-right', padding: '0px 5px'
  });  

var legend_min=ui.Panel({
        widgets: [colorBar_min, legendLabels_min],
        layout: ui.Panel.Layout.Flow('horizontal')
      })

var legendSubTitle_min = ui.Label({
  value: 'min',
  style: {fontWeight: 'bold',
          fontSize: '10px'
  }
});

var legend_min_2=ui.Panel({
        widgets: [legendSubTitle_min, legend_min],
        layout: ui.Panel.Layout.Flow('vertical'),
                style: {
          margin: '0 15px 0 0',
  }
      })
  

// Create the color bar for the legend.
var colorBar_max = ui.Thumbnail({
  image: ee.Image.pixelLonLat().select('latitude'),
  params: makeColorBarParams(vis_mean.palette),
  style: {stretch: 'vertical', margin: '0px 0px', maxHeight: '100px'},
});

colorBar_max.style().set({
    padding: '0px 8px'})

var legendLabels_max = ui.Panel({
  widgets: [
    ui.Label(vis_max.min, {margin: '0px 0px',fontSize: '10px'}),
    ui.Label(
        ((vis_max.max-vis_max.min) / 2+vis_max.min),
        {margin: '30px 4px', textAlign: 'center', stretch: 'vertical', fontSize: '10px'}),
    ui.Label(vis_max.max, {margin: '4px 4px', fontSize: '10px'})
    ],
  layout: ui.Panel.Layout.flow('vertical'),
});
legendLabels_max.style().set({
    position: 'top-right', padding: '0px 5px'
  });  

var legend_max=ui.Panel({
        widgets: [colorBar_max, legendLabels_max],
        layout: ui.Panel.Layout.Flow('horizontal')
        
      })
    
var legendSubTitle_max = ui.Label({
  value: 'max',
  style: {fontWeight: 'bold',
          fontSize: '10px'
  }
});

var legend_max_2=ui.Panel({
        widgets: [legendSubTitle_max, legend_max],
        layout: ui.Panel.Layout.Flow('vertical')
      })  
  
  
// combine legend panels
var legend_multi=ui.Panel({
        widgets: [legend_mean_2, legend_min_2, legend_max_2],
        layout: ui.Panel.Layout.Flow('horizontal')
      })
  
// Add the legendPanel to the map.
// legend_raster.add(vertcolorlegend);
legend_raster.add(legend_multi);

/////////////////////////////////
//// add vertical color ramp
/////////////////////////////////

// // Creates a color bar thumbnail image for use in legend from the given color palette.
// function makeColorBarParams(palette) {
//   return {
//     bbox: [0, 0, 1, 0.1],
//     dimensions: '100x10',
//     format: 'png',
//     min: 0,
//     max: 1,
//     palette: palette  
//   };
// }

// // Create the color bar for the legend.
// var colorBar = ui.Thumbnail({
//   image: ee.Image.pixelLonLat().select(0),
//   params: makeColorBarParams(vis.palette),
//   style: {stretch: 'horizontal', margin: '0px 4px', maxHeight: '30px'},
// });

// // Create a panel with three numbers for the legend.
// var legendLabels = ui.Panel({
//   widgets: [
//     ui.Label(vis.min, {margin: '4px 4px',fontSize: '10px'}),
//     ui.Label(
//         ((vis.max-vis.min) / 2+vis.min),
//         {margin: '4px 4px', textAlign: 'center', stretch: 'horizontal', fontSize: '10px'}),
//     ui.Label(vis.max, {margin: '4px 4px', fontSize: '10px'})
//     ],
//   layout: ui.Panel.Layout.flow('horizontal'),
 
// });

// var legendPanel = ui.Panel([legendTitle, colorBar, legendLabels]);
// var legendPanel = ui.Panel([legendTitle, vertcolorlegend]);
//     legendPanel.style().set({
//     padding: '0px 30px'
//   });
// Map.add(legendPanel);


///////////////////////////////////////
// Point Legend
////////////////////////////////////////

// set position of panel
var legend_ibutton = ui.Panel({
  style: {
    position: 'bottom-right',
    padding: '8px 15px'
  }
});

// Create legend title
var legendTitle = ui.Label({
  value: 'iButton Projects',
  style: {
    fontWeight: 'bold',
    fontSize: '12px',
    margin: '0 0 16px 0',
    }
});

// Add the title to the panel
legend_ibutton.add(legendTitle);

// Creates and styles 1 row of the legend.
var makeRow = function(color, name) {

      // Create the label that is actually the colored box.
      var colorBox = ui.Label({
        style: {
          backgroundColor: '#' + color,
          // Use padding to give the box height and width.
          padding: '11px',
          margin: '0 0 8px 0'
        }
      });

      // Create the label filled with the description text.
      var description = ui.Label({
        value: name,
        style: {margin: '0 0 4px 6px',
          fontSize: '10px'
        }
      });

      // return the panel
      return ui.Panel({
        widgets: [colorBox, description],
        layout: ui.Panel.Layout.Flow('horizontal')
      });
};

//  Palette with the colors
var palette =['e41a1c', '377eb8', '4daf4a', '984ea3'];

// name of the legend
var names = ['WOOD','RIVR','ALEX', 'HL'];

// Add color and and names
for (var i = 0; i < 4; i++) {
  legend_ibutton.add(makeRow(palette[i], names[i]));
  }  


var legendPanelMaster= ui.Panel({
  layout: ui.Panel.Layout.flow('horizontal'),
  style: {width: '100%', height:'200px'}
});

// add legends

legendPanelMaster.add(legend_ibutton);
legendPanelMaster.add(legend_raster);



// //########################################################################################################
// //##### Toggle points and hillshade ##### 
// //########################################################################################################

// create a check box to toggle points
var checkbox_1 = ui.Checkbox('iButton locations', false);

checkbox_1.onChange(function(checked1) {
  // Shows or hides the first map layer based on the checkbox's value.
  ibuttons_ui.setShown(checked1);
});


var checkbox_2 = ui.Checkbox('NCAN Hillshade', true);
// create a check box to toggle hillshade
checkbox_2.onChange(function(checked2) {
  // Shows or hides the first map layer based on the checkbox's value.
  hillshade_ly.setShown(checked2);
});


var checkboxMaster= ui.Panel({
  layout: ui.Panel.Layout.flow('horizontal'),
  style: {width: '100%'}
});

checkboxMaster.add(checkbox_1);
checkboxMaster.add(checkbox_2);


// //########################################################################################################
// //##### Layer select ##### 
// //########################################################################################################


// Offset layers
// Define Layers as a dictionary
var off_layers = {
      minTemp_summer: minTemp_summer,
      minTemp_winter: minTemp_winter,
      // minTemp_fall: minTemp_fall,
      // minTemp_spring: minTemp_spring,
      maxTemp_summer: maxTemp_summer,
      // maxTemp_winter: maxTemp_winter,
      // maxTemp_fall: maxTemp_fall,
      // maxTemp_spring: maxTemp_spring,
      meanTemp_summer: meanTemp_summer,
      // meanTemp_winter: meanTemp_winter,
      // meanTemp_fall: meanTemp_fall,
      // meanTemp_spring: meanTemp_spring,
}
print(off_layers)

function changeLayers(){
  var offsetValue = offset_select.getValue()
  // var baseValue = base_select.getValue()
  var checkbox_1_value=checkbox_1.getValue()
  var checkbox_2_value=checkbox_2.getValue()
  Map.layers().reset([
    // base_layers[baseValue],
    hillshade_ly.setShown(checkbox_2_value),
    off_layers[offsetValue],
    ibuttons_ui.setShown(checkbox_1_value)
    ])
   var chart=ui.Chart.image.histogram({image:off_layers[offsetValue].getEeObject(), scale: 10000})
        // .setSeriesNames(['mean_temp_offset'])
        .setOptions({
          // title: 'Offset Histogram',
          hAxis: {
            title: 'offset',
            titleTextStyle: {italic: false, bold: true},
          },
          vAxis:
              {title: 'count', titleTextStyle: {italic: false, bold: true}},
          colors: ['2D333C'],
          legend: {position: 'none'},
          titlePosition: 'none'
        });
    //reset charge on change    
    chartMaster.widgets().reset([chart]);
// chartMaster.add(chart);
 
}
    

// Make a selection ui.element that will update the layer
var offset_select = ui.Select({
  placeholder: 'summer mean temperature offset',
  items: [
    {value: 'meanTemp_summer', label: 'summer mean temperature offset'},
    {value: 'maxTemp_summer', label: 'summer maximum temperature offset'},
    {value: 'minTemp_summer', label: 'summer minimum temperature offset'},
    // {value: 'meanTemp_fall', label: 'fall mean temperature offset'},
    // {value: 'maxTemp_fall', label: 'fall maximum temperature offset'},
    // {value: 'minTemp_fall', label: 'fall minimum temperature offset'},
    // {value: 'meanTemp_winter', label: 'winter mean temperature offset'},
    // {value: 'maxTemp_winter', label: 'winter maximum temperature offset'},
    {value: 'minTemp_winter', label: 'winter minimum temperature offset'},
    // {value: 'meanTemp_spring', label: 'spring mean temperature offset'}
    // {value: 'maxTemp_spring', label: 'spring maximum temperature offset'},
    // {value: 'minTemp_spring', label: 'spring minimum temperature offset'},
  ],
  onChange: changeLayers,
  style: {width:'50%'}
})

// style: {width:'30%', padding: '20px 20px '}
///// Base layers drop down list 

// // Base layers
// Define Layers as a dictionary
// var base_layers = {
//   hillshade: hillshade,
//   alosChili: alosChili,
// }


// // Make a selection ui.element that will update the layer
// var base_select = ui.Select({
//   placeholder: 'Select base layer',
//   items: [
//     {value: 'hillshade', label: 'hillshade'}, 
//     {value: 'alosChili', label: 'CHILI'}
//   ],
//   onChange: changeLayers
// })

// //########################################################################################################
// //##### Histogram ##### 
// //########################################################################################################

 
 

// set position of panel
// var hist = ui.Panel({
//   style: {
//     position: 'bottom-left',
//     padding: '8px 15px'
//   }
// });
// //########################################################################################################
// //##### Main panel ##### 
// //########################################################################################################

// Generate main panel and add it to the map.
var panel = ui.Panel({style: {width:'30%', padding: '20px 20px '}});
ui.root.insert(0,panel);

// Define title and description.
var intro = ui.Label('Climate Downscaling: Raster Offsets ',
  {fontWeight: 'bold', fontSize: '24px', margin: '10px 5px'}
);
var description = ui.Label('Remote sensing and iButton data were used to create temperature offsets for microclimate conditions.' + 
'The offests are used to generate downscaled '+ 
'climate layers from ClimateNA temperature data.', {});

// add github link
var github = ui.Label('https://github.com/bgcasey/climate_downscaling', {color: '0000EE'},'https://github.com/bgcasey/climate_downscaling');

// var gee_link = ui.Label('https://code.earthengine.google.com/?accept_repo=users/bgcasey/climate_downscaling', {color: '0000EE'},'https://code.earthengine.google.com/?accept_repo=users/bgcasey/climate_downscaling');

// add line sperator
var hline = ui.Panel([
  ui.Label({
    value: '______________________________________________________________________',
    style: {fontWeight: 'bold',  color: '2D333C'},
  })]);


var hline_2 = ui.Panel([
  ui.Label({
    value: '______________________________________________________________________',
    style: {fontWeight: 'bold',  color: 'FFFFFF'},
  })]);  


var hline_3 = ui.Panel([
  ui.Label({
    value: '______________________________________________________________________',
    style: {fontWeight: 'bold',  color: '2D333C'},
  })]);  

// Earth Engine asset link
var asset_lab = ui.Label('Earth Engine Assets:',
  {fontWeight: 'bold', fontSize: '14px'}
);


var download_temperature_offsets = ui.Label('var temperature_offsets = ee.Image("projects/ee-bgcasey-climate/assets/temperature_offsets");',
{fontFamily:'monospace', fontSize: '12px', margin: '5px 5px 5px 10px', backgroundColor:'#f0f0f0'}
)

// Histogram of pixel values
var chartMaster= ui.Panel({
  // layout: ui.Panel.Layout.flow('horizontal'),
  style: {width: '85%'}
});

var chart_default=ui.Chart.image.histogram({image:meanTemp_summer.getEeObject(), scale: 10000})
        // .setSeriesNames(['mean_temp_offset'])
        .setOptions({
          // title: 'Offset Histogram',
          hAxis: {
            title: 'offset',
            titleTextStyle: {italic: false, bold: true},
          },
          vAxis:
              {title: 'count', titleTextStyle: {italic: false, bold: true}},
          colors: ['2D333C'],
          legend: {position: 'none'},
          titlePosition: 'none'
        });

chartMaster.add(chart_default)

// Add title and description to the panel  
panel.add(intro)
      .add(description)
      .add(github)
      .add(hline)
      .add(legendPanelMaster)
      .add(checkboxMaster)
      .add(offset_select)
      // .add(base_select)
      .add(hline_2)
      .add(chartMaster)
      .add(hline_3)
      .add(asset_lab)
      .add(download_temperature_offsets)
  ;




















  
// //########################################################################################################
// //##### Customize Basemap ##### 
// //########################################################################################################

//code from https://snazzymaps.com/#google_vignette

var Basemap = 
[
    {
        "stylers": [
            {
                "hue": "#ff1a00"
            },
            {
                "invert_lightness": true
            },
            {
                "saturation": -100
            },
            {
                "lightness": 33
            },
            {
                "gamma": 0.5
            }
        ]
    },
    {
        "featureType": "water",
        "elementType": "geometry",
        "stylers": [
            {
                "color": "#2D333C"
            }
        ]
    }
]
;

Map.setOptions('Basemap', {'Basemap': Basemap});


// //########################################################################################################
// //##### Cutumize map UI elements ##### 
// //########################################################################################################
var drawingTools = Map.drawingTools();
drawingTools.setShown(false);



// //########################################################################################################
// //##### Customize Basemap ##### 
// //########################################################################################################


// // This sets the available draw modes. point and line would also be available
// Map.drawingTools().setDrawModes(["polygon", "rectangle"])
// // This sets the shape selected by default
// Map.drawingTools().setShape("rectangle")


// // function to generate a download URL of the image for the viewport region. 
// function downloadImg() {
//   var viewBounds = ee.Geometry.Rectangle(Map.getBounds()); // entire viewport is selected
//   var downloadArgs = {
//     name: 'meanTemp_summer',
//     crs:'EPSG:3348',
//     // This gets the first layer of the drawn geometries and unions all of them into one
//     scale: 30,
//     region: Map.drawingTools().layers().get(0).toGeometry(),
//     maxPixels: 600000000000
// };
// // var size = offset_select.getValue().size();
// var img = temperature_offsets.select('minTemp_summer');
// print(img, "img")

// var url =img.getDownloadURL(downloadArgs);
// urlLabel.setUrl(url);
// urlLabel.style().set({shown: true});
// }

// var downloadButton = ui.Button('Get download link', downloadImg);
// var urlLabel = ui.Label('Download', {shown: false});
// var buttons = ui.Panel([downloadButton, urlLabel]);
// panel.add(buttons);


// //########################################################################################################
// //##### Print layer stats ##### 
// //########################################################################################################

// // Compute the mean elevation in the polygon.
// var maxTemp_meanDict = maxTemp_summer.getEeObject().reduceRegion({
//   reducer: ee.Reducer.mean(),
//   geometry: aoi,
//   scale: 1000,
//   maxPixels: 2729795541
// });
// // print(meanDict, "meanDict")

// // Get the mean from the dictionary and print it.
// var maxTemp_mean = maxTemp_meanDict.get('maxTemp_summer');
// print('maxTemp_mean', maxTemp_mean);

// var meanTemp_meanDict = meanTemp_summer.getEeObject().reduceRegion({
//   reducer: ee.Reducer.mean(),
//   geometry: aoi,
//   scale: 1000,
//   maxPixels: 2729795541
// });
// // print(meanDict, "meanDict")

// // Get the mean from the dictionary and print it.
// var meanTemp_mean = meanTemp_meanDict.get('meanTemp_summer');
// print('meanTemp_mean', meanTemp_mean);

// var minTemp_meanDict = minTemp_summer.getEeObject().reduceRegion({
//   reducer: ee.Reducer.mean(),
//   geometry: aoi,
//   scale: 1000,
//   maxPixels: 2729795541
// });
// // print(meanDict, "meanDict")

// // Get the mean from the dictionary and print it.
// var minTemp_mean = minTemp_meanDict.get('minTemp_summer');
// print('minTemp_mean', minTemp_mean);

// // Compute the mean elevation in the polygon.
// var maxTemp_stdDevDict = maxTemp_summer.getEeObject().reduceRegion({
//   reducer: ee.Reducer.stdDev(),
//   geometry: aoi,
//   scale: 1000,
//   maxPixels: 2729795541
// });
// // print(maxTemp_stdDevDict, "maxTemp_stdDevDict")

// // Get the stdDev from the dictionary and print it.
// var maxTemp_stdDev = maxTemp_stdDevDict.get('maxTemp_summer');
// print('maxTemp_stdDev', maxTemp_stdDev);

// var meanTemp_stdDevDict = meanTemp_summer.getEeObject().reduceRegion({
//   reducer: ee.Reducer.stdDev(),
//   geometry: aoi,
//   scale: 1000,
//   maxPixels: 2729795541
// });
// // print(meanTemp_stdDevDict, "meanTemp_stdDevDict")

// // Get the stdDev from the dictionary and print it.
// var meanTemp_stdDev = meanTemp_stdDevDict.get('meanTemp_summer');
// print('meanTemp_stdDev', meanTemp_stdDev);

// var minTemp_stdDevDict = minTemp_summer.getEeObject().reduceRegion({
//   reducer: ee.Reducer.stdDev(),
//   geometry: aoi,
//   scale: 1000,
//   maxPixels: 2729795541
// });
// // print(minTemp_stdDevDict, "minTemp_stdDevDict")

// // Get the stdDev from the dictionary and print it.
// var minTemp_stdDev = minTemp_stdDevDict.get('minTemp_summer');
// print('minTemp_stdDev', minTemp_stdDev);
