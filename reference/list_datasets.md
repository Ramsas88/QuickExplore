# List supported dataset files in a directory

Scans a directory for files with extensions `.sas7bdat`, `.xpt`, `.csv`,
or `.rds` (case-insensitive) and returns a summary data frame.

## Usage

``` r
list_datasets(dirpath)
```

## Arguments

- dirpath:

  Character string. Path to the directory to scan.

## Value

A `data.frame` with columns `Name`, `Format`, `Size`, `Modified`, and
`Path`. Returns an empty data frame if no supported files are found.

## Examples

``` r
if (FALSE) { # \dontrun{
datasets <- list_datasets("/data/mylib")
} # }
```
