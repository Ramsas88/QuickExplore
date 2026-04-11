# Compute summary statistics for numeric variables

Returns a tidy data frame with N, mean, median, standard deviation,
minimum, and maximum for each numeric variable in `vars`.

## Usage

``` r
compute_numeric_summary(df, vars, group_var = NULL)
```

## Arguments

- df:

  A `data.frame` or tibble.

- vars:

  Character vector of variable names to summarise.

- group_var:

  Optional character string naming a grouping variable. Pass `NULL`
  (default) for no grouping.

## Value

A `data.frame` (one row per variable, or per variable × group level) or
`NULL` if there are no numeric variables in `vars`.

## Examples

``` r
df <- data.frame(x = rnorm(100), y = runif(100), g = rep(c("A", "B"), 50))
compute_numeric_summary(df, c("x", "y"))
#>   Variable   N Missing Mean Median   SD   Min  Max
#> 1        x 100       0 0.07   0.09 1.05 -2.61 2.76
#> 2        y 100       0 0.52   0.55 0.31  0.02 0.98
compute_numeric_summary(df, c("x", "y"), group_var = "g")
#> # A tibble: 4 × 9
#>   g     Variable     N Missing  Mean Median    SD   Min   Max
#>   <chr> <chr>    <int>   <int> <dbl>  <dbl> <dbl> <dbl> <dbl>
#> 1 A     x           50       0  0.02   0.15  1.12 -2.61  2.07
#> 2 B     x           50       0  0.12  -0.01  0.99 -1.91  2.76
#> 3 A     y           50       0  0.5    0.53  0.29  0.04  0.98
#> 4 B     y           50       0  0.54   0.61  0.32  0.02  0.98
```
