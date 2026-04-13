# Compute a cross-tabulation of two categorical variables

Produces a wide-format contingency table of `row_var` (rows) by
`col_var` (columns), including row and column totals. When a `strat_var`
is supplied the table is computed separately for each level of the
stratification variable and the results are stacked with a leading
`Stratum` column.

## Usage

``` r
compute_crosstab(df, row_var, col_var, strat_var = NULL)
```

## Arguments

- df:

  A `data.frame` or tibble.

- row_var:

  Character string. Name of the row variable (e.g. `"SEX"`).

- col_var:

  Character string. Name of the column variable (e.g. `"RACE"`).

- strat_var:

  Character string or `NULL`. Optional stratification variable (e.g.
  `"TRT01P"`). Pass `NULL` or `""` for an unstratified table.

## Value

A `data.frame` in wide format:

- Column 1 (or 2 if stratified): `row_var` levels plus a `"Total"` row.

- Middle columns: one column per `col_var` level.

- Last column: `Total` (row sums).

- If `strat_var` is given, a leading `Stratum` column identifies each
  stratum. A grand-total block across all strata is **not** appended
  automatically — compute the unstratified table for that.

## Details

Missing values in any of the three variables are displayed as
`"(Missing)"` rather than being silently dropped, so analysts can spot
incomplete records.

## Examples

``` r
df <- data.frame(
  SEX  = c("M","F","M","F","M","F"),
  RACE = c("White","White","Black","Asian","Black","White"),
  TRT  = c("A","A","B","B","A","B")
)
compute_crosstab(df, "SEX", "RACE")
#>     SEX Asian Black White Total
#> 1     F     1     0     2     3
#> 2     M     0     2     1     3
#> 3 Total     1     2     3     6
compute_crosstab(df, "SEX", "RACE", strat_var = "TRT")
#>   Stratum   SEX Black White Total Asian
#> 1 TRT = A     F     0     1     1    NA
#> 2 TRT = A     M     1     1     2    NA
#> 3 TRT = A Total     1     2     3    NA
#> 4 TRT = B     F     0     1     2     1
#> 5 TRT = B     M     1     0     1     0
#> 6 TRT = B Total     1     1     3     1
```
