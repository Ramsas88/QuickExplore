# Dataset Converter Module – Server

Handles the dataset-conversion download for all supported output
formats: `.rds`, `.xlsx`, `.csv`, `.json`, and SAS transport `.xpt`.

## Usage

``` r
converter_server(id, loaded_data, selected_dataset)
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

`NULL` (invisibly). Called for side effects.

## See also

[`converter_ui()`](https://ramsas88.github.io/quickexplorer/reference/converter_ui.md)
