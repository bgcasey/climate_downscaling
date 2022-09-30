# Overview

`{r GlobalOptions, echo=FALSE} options(bookdown.render.file_scope = FALSE, knitr.duplicate.label = "allow")  knitr::opts_chunk$set(cache.path = "5_cache/") knitr::opts_knit$set(root.dir = rprojroot::find_rstudio_root_file())`

`{r setup, include=FALSE, cache=FALSE} #Set root directory to R project root knitr::opts_knit$set(root.dir = rprojroot::find_rstudio_root_file())`

\`\`\`{css, echo=FALSE} \# set max height of code chunks using the
following css styling

pre { max-height: 300px; overflow-y: auto; }

pre\[class\] { max-height: 500px; }







    # Gather iButton data

    ```{r child = '1_code/r_notebooks/generate_shapefiles_for_GEE.Rmd'}

# References

<!--chapter:end:index.Rmd-->
