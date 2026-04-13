# QuickExplore: Interactive Dataset Explorer for SAS and Other Data Formats

A 'Shiny' application that provides a SAS Studio-style interface for
browsing, exploring, summarising, and converting datasets in SAS
(`.sas7bdat`, `.xpt`), CSV, and R (`.rds`) formats.

The main entry point is
[`run_app()`](https://ramsas88.github.io/quickexplorer/reference/run_app.md).
The package also exports several standalone helper functions useful
outside the Shiny context:

- [`read_dataset()`](https://ramsas88.github.io/quickexplorer/reference/read_dataset.md)
  – read any supported format into a data frame.

- [`list_datasets()`](https://ramsas88.github.io/quickexplorer/reference/list_datasets.md)
  – enumerate datasets in a directory.

- [`get_variable_info()`](https://ramsas88.github.io/quickexplorer/reference/get_variable_info.md)
  – variable-level metadata.

- [`compute_numeric_summary()`](https://ramsas88.github.io/quickexplorer/reference/compute_numeric_summary.md)
  /
  [`compute_categorical_summary()`](https://ramsas88.github.io/quickexplorer/reference/compute_categorical_summary.md)
  – tidy descriptive statistics.

- [`format_file_size()`](https://ramsas88.github.io/quickexplorer/reference/format_file_size.md)
  – human-readable file size strings.

## See also

Useful links:

- <https://github.com/ramsas88/QuickExplore>

- Report bugs at <https://github.com/ramsas88/QuickExplore/issues>

## Author

**Maintainer**: Ram Gaduputi <ramsas88@gmail.com>

Authors:

- Jagadish Katam <Jagadish.katam@gmail.com>
