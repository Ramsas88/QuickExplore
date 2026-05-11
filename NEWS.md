# QuickExplore 0.1.1

## Bug fixes

* Code Generator: closed the missing parenthesis on the `strat_levels` line
  emitted for stratified cross-tabs.  The generated `.R` script now parses
  cleanly (#BUG-03).
* Code Generator: normalise Windows back-slashes in file paths so the
  generated `.R` script is parseable on every platform (#BUG-04).
* Code Generator: emit `dplyr::select(dplyr::all_of(c(...)))` instead of
  bare column names, so non-syntactic names (spaces, hyphens, leading
  digits) survive the round-trip (#BUG-06).
* `read_dataset()`: preserve `haven` `label` / `format.sas` attributes and
  the `haven_labelled` class when converting blank SAS strings to `NA`
  (#BUG-05).  `get_variable_info()` once again populates `Label` and
  `Format` for SAS inputs.
* `read_dataset()`: reject `.rds` files whose top-level object is not a
  `data.frame`, with a clear error message instead of cryptic downstream
  failures (#BUG-20).
* `format_file_size()`: extended units to `TB` and `PB` and added a guard
  for negative sizes (#BUG-07).
* `get_variable_info()`: `N_Unique` now counts distinct non-missing values,
  matching `skimr` and `DataExplorer` (#BUG-08).  Missing counts continue
  to be reported separately in `Missing_Count`.
* `compute_numeric_summary()` / `compute_categorical_summary()`: emit a
  clear error naming the offending variable when `vars` includes a name
  that is not in `df`, instead of base R's `undefined columns selected`
  (#BUG-09).
* `compute_numeric_summary()`: now returns `Q1` and `Q3` quartile columns
  alongside the existing summary statistics (#BUG-13).
* `compute_crosstab()`: validate `row_var`, `col_var`, and `strat_var`
  up-front and fail with an actionable error if any is missing or
  duplicated (#BUG-15).
* `compute_crosstab()`: warn when the source data carries values literally
  equal to `Total` or `(Missing)`, which would otherwise be
  indistinguishable from synthetic totals / NA-relabel cells (#BUG-14).
* Converter: the CSV preview now honours the user's delimiter and
  header-row toggles, matching what the download handler writes (#BUG-11).
* Converter: rewrote XPT variable-name shortening so a `make.unique` step
  is no longer followed by truncation, avoiding duplicate 8-character
  names; if any name is shortened, a `_name_map.csv` is emitted alongside
  the `.xpt` so analysts can trace renames (#BUG-10).
* Dataset Browser: removing the currently active library now resets
  `selected_dataset` and `loaded_data` so the Data Viewer, Convert, and
  Code tabs stop showing stale content (#BUG-16).

## Documentation

* Removed contradictory `@keywords internal` on `code_generator_server`,
  which had been exported simultaneously (#BUG-17).
* Documented `compute_crosstab()`, the Cross-tabulation panel, the Code
  Generator tab, and the SAS blank-to-NA coercion that were already
  shipped in 0.1.0 (#BUG-18).

## Tests

* Added `tests/testthat/test_quickexplore_suite.R`: testthat edition-3
  suite with eight thematic sections (~40 test cases) covering file-format
  dispatch, metadata, numeric/categorical summaries, cross-tabulation,
  converter round-trip, code-generator parseability, and data-type
  coverage.
* Added `tests/testthat/test_quickexplore_runner.Rmd`: an R-Markdown
  runner that knits to an HTML report with pass/fail tallies and inline
  bug-regression demonstrations.


# QuickExplore 0.1.0

## Initial Release

* `run_app()` launches the Dataset Explorer Shiny application.
* Browse multiple directory-based libraries simultaneously.
* Load datasets in SAS (`.sas7bdat`, `.xpt`), CSV, and R (`.rds`) formats.
* Interactive data viewer with column-level filtering via DT.
* Explore panel with dplyr-expression filtering and quick-filter badges.
* Variable Explorer with type-coloured metadata and top-value frequency tables.
* Summary panel with automatic numeric and categorical statistics, plus a
  missing-value heat bar table.
* Converter panel exports to `.rds`, `.xlsx`, `.csv`, `.json`, and SAS V5
  transport (`.xpt`).
* Exported utility functions: `read_dataset()`, `list_datasets()`,
  `get_variable_info()`, `get_dataset_metadata()`, `format_file_size()`,
  `compute_numeric_summary()`, `compute_categorical_summary()`.
