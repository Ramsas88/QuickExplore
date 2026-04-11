# Compute frequency statistics for categorical variables

Returns value frequencies and percentages for each non-numeric variable
in `vars`, optionally grouped by a second variable.

## Usage

``` r
compute_categorical_summary(df, vars, group_var = NULL)
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

A `data.frame` with columns for the grouping variable (if any), the
value, its frequency count, percentage, and the variable name. Returns
`NULL` if there are no categorical variables in `vars`.

## Examples

``` r
df <- data.frame(sex = c("M","F","M","F","M"), trt = c("A","A","B","B","A"))
compute_categorical_summary(df, c("sex", "trt"))
#>    sex Frequency Percentage Variable  trt
#> 1    F         2         40      sex <NA>
#> 2    M         3         60      sex <NA>
#> 3 <NA>         3         60      trt    A
#> 4 <NA>         2         40      trt    B
```
