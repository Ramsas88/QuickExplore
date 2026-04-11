# Data Viewer Module – Server

Handles data display, filtering, variable inspection, and download for
the Data Viewer tab.

## Usage

``` r
data_viewer_server(id, loaded_data, selected_dataset)
```

## Arguments

- id:

  Character string. The Shiny module namespace identifier.

- loaded_data:

  A
  [`shiny::reactiveVal()`](https://rdrr.io/pkg/shiny/man/reactiveVal.html)
  containing the current `data.frame`.

- selected_dataset:

  A
  [`shiny::reactiveVal()`](https://rdrr.io/pkg/shiny/man/reactiveVal.html)
  with the file path of the active dataset.

## Value

A
[`shiny::reactiveVal()`](https://rdrr.io/pkg/shiny/man/reactiveVal.html)
containing the currently filtered `data.frame`.

## See also

[`data_viewer_ui()`](https://ramsas88.github.io/quickexplorer/reference/data_viewer_ui.md)
