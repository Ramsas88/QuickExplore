# Summary Panel Module – Server

Computes and renders descriptive statistics for numeric and categorical
variables, plus a missing-value summary table.

## Usage

``` r
summary_panel_server(id, loaded_data)
```

## Arguments

- id:

  Character string. The Shiny module namespace identifier.

- loaded_data:

  A
  [`shiny::reactiveVal()`](https://rdrr.io/pkg/shiny/man/reactiveVal.html)
  containing the current `data.frame`.

## Value

`NULL` (invisibly). Called for side effects.

## See also

[`summary_panel_ui()`](https://ramsas88.github.io/quickexplorer/reference/summary_panel_ui.md)
