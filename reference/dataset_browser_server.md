# Dataset Browser Module – Server

Handles library registration, dataset listing, and dataset loading for
the sidebar browser panel.

## Usage

``` r
dataset_browser_server(id, selected_dataset, loaded_data)
```

## Arguments

- id:

  Character string. The Shiny module namespace identifier.

- selected_dataset:

  A
  [`shiny::reactiveVal()`](https://rdrr.io/pkg/shiny/man/reactiveVal.html)
  that stores the full file path of the currently selected dataset.

- loaded_data:

  A
  [`shiny::reactiveVal()`](https://rdrr.io/pkg/shiny/man/reactiveVal.html)
  that stores the loaded `data.frame`.

## Value

A list of reactive values: `libraries` (named list of library-path
pairs) and `selected_library` (the currently active library name).

## See also

[`dataset_browser_ui()`](https://ramsas88.github.io/quickexplorer/reference/dataset_browser_ui.md)
