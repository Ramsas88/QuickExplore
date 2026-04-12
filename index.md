## Overview

**QuickExplore** provides a point-and-click Shiny interface modelled
after SAS Studio’s library/dataset browser. It supports SAS
(`.sas7bdat`, `.xpt`), CSV, and R (`.rds`) files and lets you explore,
filter, summarise, and export datasets without writing any code.

The package also exposes a set of standalone R functions for use in
scripts or other Shiny applications.

## install package from GitHub

``` r
pak::pak("Ramsas88/QuickExplore")
```

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

# Categorical summary
compute_categorical_summary(df, "sex")
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
| [`dataset_browser_ui()`](https://ramsas88.github.io/quickexplorer/reference/dataset_browser_ui.md) | [`dataset_browser_server()`](https://ramsas88.github.io/quickexplorer/reference/dataset_browser_server.md) | Library + dataset sidebar      |
| [`data_viewer_ui()`](https://ramsas88.github.io/quickexplorer/reference/data_viewer_ui.md)         | [`data_viewer_server()`](https://ramsas88.github.io/quickexplorer/reference/data_viewer_server.md)         | Interactive table with filters |
| [`summary_panel_ui()`](https://ramsas88.github.io/quickexplorer/reference/summary_panel_ui.md)     | [`summary_panel_server()`](https://ramsas88.github.io/quickexplorer/reference/summary_panel_server.md)     | Descriptive statistics         |
| [`converter_ui()`](https://ramsas88.github.io/quickexplorer/reference/converter_ui.md)             | [`converter_server()`](https://ramsas88.github.io/quickexplorer/reference/converter_server.md)             | Multi-format export            |
