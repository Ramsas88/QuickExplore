# Code Generator Module - Server

Generates reproducible R code that mirrors the current QuickExplore
session and provides clipboard-copy (via JS) and download-as-`.R`
handlers.

## Usage

``` r
code_generator_server(
  id,
  selected_dataset,
  filter_expr,
  selected_vars,
  group_var,
  summary_vars,
  output_format,
  csv_delim,
  json_pretty,
  crosstab_row = shiny::reactive(""),
  crosstab_col = shiny::reactive(""),
  crosstab_strat = shiny::reactive("")
)
```

## Arguments

- id:

  Character string. The Shiny module namespace identifier.

- selected_dataset:

  A
  [`shiny::reactiveVal()`](https://rdrr.io/pkg/shiny/man/reactiveVal.html)
  holding the file path of the active dataset, or `NULL` when none is
  loaded.

- filter_expr:

  A reactive expression returning the dplyr filter string typed in the
  Explore Data tab (may be `""` or `NULL`).

- selected_vars:

  A reactive expression returning a character vector of variable names
  chosen in the Explore Data tab (may be `NULL` / empty).

- group_var:

  A reactive expression returning the grouping variable name selected in
  the Summary panel (`""` means no grouping).

- summary_vars:

  A reactive expression returning variable names used for summary
  statistics (`NULL` / empty means all variables).

- output_format:

  A reactive expression returning the converter output format: `"csv"`,
  `"rds"`, `"xlsx"`, `"json"`, or `"xpt"`.

- csv_delim:

  A reactive returning the CSV delimiter character (default `","`).

- json_pretty:

  A reactive returning `TRUE` to pretty-print JSON.

- crosstab_row:

  A reactive returning the cross-tab row variable name (`""` = none
  selected).

- crosstab_col:

  A reactive returning the cross-tab column variable name (`""` = none
  selected).

- crosstab_strat:

  A reactive returning the stratification variable name (`""` =
  unstratified).

## Value

`NULL` (invisibly). Called for side effects.

## See also

[`code_generator_ui()`](https://ramsas88.github.io/quickexplorer/reference/code_generator_ui.md)
