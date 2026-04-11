#' dataexplorer: Interactive Dataset Explorer for SAS and Other Data Formats
#'
#' @description
#' A 'Shiny' application that provides a SAS Studio-style interface for
#' browsing, exploring, summarising, and converting datasets in SAS
#' (`.sas7bdat`, `.xpt`), CSV, and R (`.rds`) formats.
#'
#' The main entry point is [run_app()].  The package also exports several
#' standalone helper functions useful outside the Shiny context:
#'
#' * [read_dataset()] – read any supported format into a data frame.
#' * [list_datasets()] – enumerate datasets in a directory.
#' * [get_variable_info()] – variable-level metadata.
#' * [compute_numeric_summary()] / [compute_categorical_summary()] – tidy
#'   descriptive statistics.
#' * [format_file_size()] – human-readable file size strings.
#'
#' @keywords internal
"_PACKAGE"

## usethis namespace: start
#' @importFrom dplyr bind_rows count filter group_by mutate summarise ungroup
#' @importFrom rlang .data parse_expr
#' @importFrom stats median na.omit quantile sd setNames
#' @importFrom utils head write.csv
## usethis namespace: end
NULL
