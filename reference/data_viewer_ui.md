# Data Viewer Module – UI

Creates a tabbed panel with three sub-tabs: an interactive data table
(Data Viewer), a filter/subset interface (Explore Data), and a variable
metadata explorer (Variables).

## Usage

``` r
data_viewer_ui(id)
```

## Arguments

- id:

  Character string. The Shiny module namespace identifier.

## Value

A [`shiny::tagList()`](https://rdrr.io/pkg/shiny/man/reexports.html)
with the viewer UI.

## See also

[`data_viewer_server()`](https://ramsas88.github.io/quickexplorer/reference/data_viewer_server.md)
