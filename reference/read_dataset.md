# Read a dataset based on its file extension

Dispatches to the appropriate reader based on the file extension.
Supported formats: `.sas7bdat`, `.xpt`, `.csv`, `.rds`.

## Usage

``` r
read_dataset(filepath)
```

## Arguments

- filepath:

  Character string. Full path to the dataset file.

## Value

A `data.frame` (or tibble) with the dataset contents.

## Examples

``` r
if (FALSE) { # \dontrun{
df <- read_dataset("/data/mylib/demog.sas7bdat")
df <- read_dataset("/data/exports/study.csv")
} # }
```
