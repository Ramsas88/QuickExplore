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

A named list with two elements:

- `summary_vars`:

  A [`shiny::reactive()`](https://rdrr.io/pkg/shiny/man/reactive.html)
  returning the selected variable names.

- `group_var`:

  A [`shiny::reactive()`](https://rdrr.io/pkg/shiny/man/reactive.html)
  returning the grouping variable name (`""` = none).

## See also

[`summary_panel_ui()`](https://ramsas88.github.io/quickexplorer/reference/summary_panel_ui.md)
