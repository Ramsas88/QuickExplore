# Changelog

## QuickExplore 0.1.0

### Initial Release

- [`run_app()`](https://ramsas88.github.io/data-explorer/reference/run_app.md)
  launches the Dataset Explorer Shiny application.
- Browse multiple directory-based libraries simultaneously.
- Load datasets in SAS (`.sas7bdat`, `.xpt`), CSV, and R (`.rds`)
  formats.
- Interactive data viewer with column-level filtering via DT.
- Explore panel with dplyr-expression filtering and quick-filter badges.
- Variable Explorer with type-coloured metadata and top-value frequency
  tables.
- Summary panel with automatic numeric and categorical statistics, plus
  a missing-value heat bar table.
- Converter panel exports to `.rds`, `.xlsx`, `.csv`, `.json`, and SAS
  V5 transport (`.xpt`).
- Exported utility functions:
  [`read_dataset()`](https://ramsas88.github.io/data-explorer/reference/read_dataset.md),
  [`list_datasets()`](https://ramsas88.github.io/data-explorer/reference/list_datasets.md),
  [`get_variable_info()`](https://ramsas88.github.io/data-explorer/reference/get_variable_info.md),
  [`get_dataset_metadata()`](https://ramsas88.github.io/data-explorer/reference/get_dataset_metadata.md),
  [`format_file_size()`](https://ramsas88.github.io/data-explorer/reference/format_file_size.md),
  [`compute_numeric_summary()`](https://ramsas88.github.io/data-explorer/reference/compute_numeric_summary.md),
  [`compute_categorical_summary()`](https://ramsas88.github.io/data-explorer/reference/compute_categorical_summary.md).
