# Extract variable-level metadata from a dataset

Returns a data frame describing each variable: its type, SAS label, SAS
format, missing value counts, and number of unique values.

## Usage

``` r
get_variable_info(df)
```

## Arguments

- df:

  A `data.frame` or tibble.

## Value

A `data.frame` with columns `Variable`, `Type`, `Label`, `Format`,
`Missing_Count`, `Missing_Pct`, and `N_Unique`.

## Examples

``` r
df <- data.frame(x = 1:5, y = letters[1:5])
get_variable_info(df)
#>   Variable      Type Label Format Missing_Count Missing_Pct N_Unique
#> 1        x   Numeric                          0           0        5
#> 2        y Character                          0           0        5
```
