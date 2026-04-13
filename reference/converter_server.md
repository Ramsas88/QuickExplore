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

A named list with three elements:

- `output_format`:

  A [`shiny::reactive()`](https://rdrr.io/pkg/shiny/man/reactive.html)
  returning the selected output format string.

- `csv_delim`:

  A [`shiny::reactive()`](https://rdrr.io/pkg/shiny/man/reactive.html)
  returning the CSV delimiter character.

- `json_pretty`:

  A [`shiny::reactive()`](https://rdrr.io/pkg/shiny/man/reactive.html)
  returning `TRUE` to pretty-print JSON output.

## See also

[`converter_ui()`](https://ramsas88.github.io/quickexplorer/reference/converter_ui.md)
