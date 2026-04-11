# Get metadata for a loaded dataset

Returns file-level metadata including the number of rows and columns,
file size, and timestamps.

## Usage

``` r
get_dataset_metadata(df, filepath)
```

## Arguments

- df:

  A `data.frame` or tibble (the loaded data).

- filepath:

  Character string. Path to the source file.

## Value

A named list with elements: `filename`, `filepath`, `format`, `n_rows`,
`n_cols`, `file_size`, `modified`, and `created`.

## Examples

``` r
if (FALSE) { # \dontrun{
df <- read_dataset("/data/demog.csv")
meta <- get_dataset_metadata(df, "/data/demog.csv")
meta$n_rows
} # }
```
