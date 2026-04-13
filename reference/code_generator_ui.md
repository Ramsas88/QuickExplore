# Code Generator Module - UI

Renders a panel displaying auto-generated R code that reproduces the
current QuickExplore session (load dataset -\> filter/select -\>
summarise -\> export). Users can copy the code to the clipboard or
download it as a `.R` script.

## Usage

``` r
code_generator_ui(id)
```

## Arguments

- id:

  Character string. The Shiny module namespace identifier.

## Value

A [`shiny::tagList()`](https://rdrr.io/pkg/shiny/man/reexports.html)
with the code generator UI.

## See also

[`code_generator_server()`](https://ramsas88.github.io/quickexplorer/reference/code_generator_server.md)
