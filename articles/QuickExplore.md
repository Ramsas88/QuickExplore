# Getting Started with QuickExplore

## Overview

**QuickExplore** provides a point-and-click Shiny interface modelled
after SAS Studio’s library/dataset browser. It supports SAS
(`.sas7bdat`, `.xpt`), CSV, and R (`.rds`) files and lets you explore,
filter, summarise, and export datasets without writing any code.

The package also exposes a set of standalone R functions for use in
scripts or other Shiny applications.

## Launching the Application

``` r
library(QuickExplore)
run_app()
```

The app opens in your default browser. If you are running inside RStudio
it opens in the Viewer pane.

### First Steps

1.  Click **Add Library** in the left sidebar.
2.  Give the library a short name (e.g. `MYLIB`) and enter the path to a
    folder that contains your data files.
3.  Click a dataset name in the list to load it.
4.  Use the **Data**, **Summary**, and **Convert** tabs to explore and
    export.

## Standalone Utility Functions

All helper functions used internally by the app are exported and can be
called directly.

### Reading a Dataset

``` r
df <- read_dataset("/path/to/data/demog.sas7bdat")
df <- read_dataset("/path/to/data/analysis.csv")
df <- read_dataset("/path/to/data/model_output.rds")
```

### Listing Datasets in a Directory

``` r
datasets <- list_datasets("/path/to/data/")
print(datasets)
```

### Variable Metadata

``` r
info <- get_variable_info(df)
head(info)
```

### Descriptive Statistics

``` r
df <- data.frame(
  age  = c(25, 34, 45, 52, 28, NA),
  sex  = c("M", "F", "M", "F", "M", "F"),
  dose = c(10, 20, 10, 30, 20, 10)
)

# Numeric summary
library(QuickExplore)
compute_numeric_summary(df, c("age", "dose"))
#>   Variable N Missing  Mean Median    SD Min Max
#> 1      age 5       1 36.80     34 11.43  25  52
#> 2     dose 6       0 16.67     15  8.16  10  30

# Categorical summary
compute_categorical_summary(df, "sex")
#>   sex Frequency Percentage Variable
#> 1   F         3         50      sex
#> 2   M         3         50      sex
```

### Grouped Summaries

``` r
compute_numeric_summary(df, c("age", "dose"), group_var = "sex")
```

## Shiny Module API

Each tab in the application is implemented as a reusable Shiny module.
You can embed any of these modules in your own Shiny apps:

``` r
library(shiny)
library(QuickExplore)

ui <- fluidPage(
  data_viewer_ui("viewer")
)

server <- function(input, output, session) {
  my_data <- reactiveVal(mtcars)
  my_path <- reactiveVal("mtcars")    # or a real file path
  data_viewer_server("viewer", my_data, my_path)
}

shinyApp(ui, server)
```

Available module pairs:

| UI function                                                                                        | Server function                                                                                            | Purpose                        |
|----------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------|--------------------------------|
| [`dataset_browser_ui()`](https://ramsas88.github.io/data-explorer/reference/dataset_browser_ui.md) | [`dataset_browser_server()`](https://ramsas88.github.io/data-explorer/reference/dataset_browser_server.md) | Library + dataset sidebar      |
| [`data_viewer_ui()`](https://ramsas88.github.io/data-explorer/reference/data_viewer_ui.md)         | [`data_viewer_server()`](https://ramsas88.github.io/data-explorer/reference/data_viewer_server.md)         | Interactive table with filters |
| [`summary_panel_ui()`](https://ramsas88.github.io/data-explorer/reference/summary_panel_ui.md)     | [`summary_panel_server()`](https://ramsas88.github.io/data-explorer/reference/summary_panel_server.md)     | Descriptive statistics         |
| [`converter_ui()`](https://ramsas88.github.io/data-explorer/reference/converter_ui.md)             | [`converter_server()`](https://ramsas88.github.io/data-explorer/reference/converter_server.md)             | Multi-format export            |

## Session Info

``` r
sessionInfo()
#> R version 4.5.3 (2026-03-11)
#> Platform: x86_64-pc-linux-gnu
#> Running under: Ubuntu 24.04.4 LTS
#> 
#> Matrix products: default
#> BLAS:   /usr/lib/x86_64-linux-gnu/openblas-pthread/libblas.so.3 
#> LAPACK: /usr/lib/x86_64-linux-gnu/openblas-pthread/libopenblasp-r0.3.26.so;  LAPACK version 3.12.0
#> 
#> locale:
#>  [1] LC_CTYPE=C.UTF-8       LC_NUMERIC=C           LC_TIME=C.UTF-8       
#>  [4] LC_COLLATE=C.UTF-8     LC_MONETARY=C.UTF-8    LC_MESSAGES=C.UTF-8   
#>  [7] LC_PAPER=C.UTF-8       LC_NAME=C              LC_ADDRESS=C          
#> [10] LC_TELEPHONE=C         LC_MEASUREMENT=C.UTF-8 LC_IDENTIFICATION=C   
#> 
#> time zone: UTC
#> tzcode source: system (glibc)
#> 
#> attached base packages:
#> [1] stats     graphics  grDevices utils     datasets  methods   base     
#> 
#> other attached packages:
#> [1] QuickExplore_0.1.0
#> 
#> loaded via a namespace (and not attached):
#>  [1] vctrs_0.7.2       cli_3.6.6         knitr_1.51        rlang_1.2.0      
#>  [5] xfun_0.57         otel_0.2.0        generics_0.1.4    textshaping_1.0.5
#>  [9] jsonlite_2.0.0    glue_1.8.0        htmltools_0.5.9   ragg_1.5.2       
#> [13] sass_0.4.10       rmarkdown_2.31    tibble_3.3.1      evaluate_1.0.5   
#> [17] jquerylib_0.1.4   fastmap_1.2.0     yaml_2.3.12       lifecycle_1.0.5  
#> [21] compiler_4.5.3    dplyr_1.2.1       fs_2.0.1          pkgconfig_2.0.3  
#> [25] htmlwidgets_1.6.4 systemfonts_1.3.2 digest_0.6.39     R6_2.6.1         
#> [29] tidyselect_1.2.1  pillar_1.11.1     magrittr_2.0.5    bslib_0.10.0     
#> [33] tools_4.5.3       pkgdown_2.2.0     cachem_1.1.0      desc_1.4.3
```
