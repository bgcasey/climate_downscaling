# climate_downscaling


**Project directory index:**

```
climate_downscaling
├── 0_data
│   ├── external
│   │   ├── Hills_iButton_Data_Combined_Corrected_for_Deployment_no_extremes_Apr_27.csv
│   │   └── iButtons_RIVR_combined_April7_2022_no_extremes.csv
│   └── manual
│       └── spatial
│           ├── RIVR_xy.dbf
│           ├── RIVR_xy.prj
│           ├── RIVR_xy.rData
│           ├── RIVR_xy.shp
│           └── RIVR_xy.shx
├── 1_code
│   ├── GEE
│   ├── r_notebooks
│   │   ├── generate_shapefiles_for_GEE.Rmd
│   │   └── generate_shapefiles_for_GEE.nb.html
│   └── r_scripts
│       ├── exposure_model2.R
│       └── ibutton_imputting_monthly_means.R
├── 2_pipeline
│   ├── out
│   ├── store
│   └── tmp
├── 3_output
│   ├── book
│   ├── data
│   ├── figures
│   ├── maps
│   │   └── RIVR_xy.png
│   ├── results
│   │   ├── figures
│   │   └── tables
│   └── tables
├── README.md
└── climate_downscaling.Rproj
```

```{r echo=FALSE}
library(fs)
root.dir = rprojroot::find_rstudio_root_file()

fs::dir_tree(path = root.dir, recurse = TRUE)
```

# test


```{r child = '1_code/r_notebooks/generate_shapefiles_for_GEE'}
```


![Screen Shot 2022-09-28 at 8 02 24 AM](https://user-images.githubusercontent.com/31937548/193309798-0c38d7a9-d0ee-419c-b7a5-22be5fe35931.png)