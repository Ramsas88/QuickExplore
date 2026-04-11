# Launch the Dataset Explorer Shiny Application

Opens the interactive Dataset Explorer in your default web browser (or
the RStudio Viewer pane when called from within RStudio). The
application provides a SAS Studio-style interface for browsing
libraries, exploring datasets, computing summary statistics, and
converting between data formats.

## Usage

``` r
run_app(...)
```

## Arguments

- ...:

  Additional arguments passed to
  [`shiny::runApp()`](https://rdrr.io/pkg/shiny/man/runApp.html), such
  as `port`, `host`, or `launch.browser`.

## Value

Called for its side effect of launching a Shiny application. Returns
`NULL` invisibly.

## Examples

``` r
if (FALSE) { # \dontrun{
# Launch with default settings
run_app()

# Launch on a specific port without opening a browser
run_app(port = 4321, launch.browser = FALSE)
} # }
```
