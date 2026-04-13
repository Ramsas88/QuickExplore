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

A `data.frame` (or tibble) with the dataset contents. For SAS formats,
all-whitespace character values are coerced to `NA_character_`.

## Details

For SAS formats (`.sas7bdat`, `.xpt`), blank strings are automatically
converted to `NA` after loading. This matches SAS behaviour where a
blank character value is treated as a system-missing value, not as a
valid empty string.

## Examples

``` r
if (FALSE) { # \dontrun{
df <- read_dataset("/data/mylib/demog.sas7bdat")
df <- read_dataset("/data/exports/study.csv")
} # }
```
