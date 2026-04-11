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
