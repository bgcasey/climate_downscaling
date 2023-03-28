- <a href="#import-and-clean-temperature-data"
  id="toc-import-and-clean-temperature-data">1. Import and clean
  temperature data</a>
- <a href="#get-xy-coordinates-of-data-loggers"
  id="toc-get-xy-coordinates-of-data-loggers">2. Get XY coordinates of
  data loggers</a>
- <a href="#references" id="toc-references">References</a>

Here we present our workflow and code for refining ClimateNA temperature
predictions using temperature data loggers and remote sensing data
accessed via Google Earth Engine. Temperature offset layers and project
spatial data can be viewed at
<https://bgcasey.users.earthengine.app/view/climateoffsets>.

Ecological studies often rely on interpolated climate data to predict
species distributions and identify climate change refugia. However, the
scale of climate data does not always correspond to the scale of habitat
conditions influencing organisms. ClimateNA, a freely available software
package, addresses this by providing scale-free predictions of climate
variables by interpolating gridded climate data and adjusting for
elevation. While useful, ClimateNA predictions could be improved by
incorporating other variables that influence micro-climatic variation.
We developed methods to refine ClimateNA air temperature predictions
using temperature data loggers and remote sensing data accessed via
Google Earth Engine. Monthly temperature variables from 2005-2021 were
calculated using near-surface temperatures gathered from 513 monitoring
sites across Alberta, Canada. We used variables associated with terrain,
vegetation structure, and atmospheric conditions in boosted-regression
trees to predict differences between ClimateNA temperature predictions
and micro-climate conditions. We produced 30 m seasonal offset layers
for mean, maximum, and minimum temperatures covering all of Alberta and
British Columbia. Mean summer temperatures were on average -0.03°C (SD =
0.71) greater than ClimateNA predictions; maximum summer temperatures
were on average 6.81°C (SD = 1.11) less than CimateNA predictions; and
winter minimum temperatures were on average -0.81°C (SD = 0.98) greater
than CimateNA predictions. Offset adjusted ClimateNA predictions should
better reflect micro-climatic variation and improve the accuracy of
species-habitat models.

# 1. Import and clean temperature data

First we gathered temperature data from temperature data loggers
deployed across the province of Alberta.

| Project code | Number of loggers | Time frame | Region  | Reference                                                           |
|:-------------|------------------:|:-----------|:--------|:--------------------------------------------------------------------|
| RIVR         |                88 | 2018-2020  | Alberta | Estevo et al. ([2022](#ref-estevoTopographicVegetationDrivers2022)) |
| HILLS        |               152 | 2014-2016  | Alberta | NA                                                                  |
| WOOD         |               232 | 2005-2010  | Alberta | Wood et al. ([2017](#ref-wood2017dtdf))                             |

Sources of temperature data loggers.

<div class="figure">

<img src="3_output/maps/ss_xy.png" alt="Locations of temperature data loggers." width="80%" />
<p class="caption">
Locations of temperature data loggers.
</p>

</div>

The file `1_code/r_notebooks/ibutton_data_xy.Rmd` provides code and
instructions for importing and cleaning data from both raw and processed
iButton temperature data. We did the following for each source of
iButton data:

1.  Imported temperature data into the r project.
2.  Identified and removed pre-deployment and post-retrieval temperature
    data.
3.  Identified and fixed errors in date-time strings.
4.  Identified and fixed errors in iButton site names and made sure that
    each iButton deployment was associated with a unique identifier.
5.  Calculated daily temperature summaries including:
    - Tmax (maximum temperature)

    - Tmin (minimum temperature)

    - Tavg (mean temperature)
6.  Combined daily temperature data from all sources into a single data
    frame.

# 2. Get XY coordinates of data loggers

# References

<div id="refs" class="references csl-bib-body hanging-indent">

<div id="ref-estevoTopographicVegetationDrivers2022" class="csl-entry">

Estevo, Cesar A., Diana Stralberg, Scott E. Nielsen, and Erin Bayne.
2022. “Topographic and Vegetation Drivers of Thermal Heterogeneity Along
the Boreal–Grassland Transition Zone in Western Canada: Implications for
Climate Change Refugia.” *Ecology and Evolution* 12 (6): e9008.
https://doi.org/<https://doi.org/10.1002/ece3.9008>.

</div>

<div id="ref-wood2017dtdf" class="csl-entry">

Wood, Wendy H, Shawn J Marshall, Shannon E Fargey, and Terri L
Whitehead. 2017. “Daily Temperature Data from the Foothills Climate
Array Mesonet, Canadian Rocky Mountains, 2005-2010.” PANGAEA.
<https://doi.org/10.1594/PANGAEA.880611>.

</div>

</div>

<!--chapter:end:index.Rmd-->
