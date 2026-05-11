#' Read a dataset based on its file extension
#'
#' Dispatches to the appropriate reader based on the file extension.
#' Supported formats: `.sas7bdat`, `.xpt`, `.csv`, `.rds`.
#'
#' For SAS formats (`.sas7bdat`, `.xpt`), blank strings are automatically
#' converted to `NA` after loading.  This matches SAS behaviour where a
#' blank character value is treated as a system-missing value, not as a
#' valid empty string.
#'
#' @param filepath Character string. Full path to the dataset file.
#'
#' @return A `data.frame` (or tibble) with the dataset contents.  For SAS
#'   formats, all-whitespace character values are coerced to `NA_character_`.
#'
#' @examples
#' \dontrun{
#' df <- read_dataset("/data/mylib/demog.sas7bdat")
#' df <- read_dataset("/data/exports/study.csv")
#' }
#'
#' @export
read_dataset <- function(filepath) {
  ext <- tolower(tools::file_ext(filepath))

  tryCatch({
    df <- switch(ext,
      "sas7bdat" = haven::read_sas(filepath),
      "xpt"      = haven::read_xpt(filepath),
      "csv"      = readr::read_csv(filepath, show_col_types = FALSE),
      "rds"      = readRDS(filepath),
      stop(paste("Unsupported file format:", ext))
    )

    # SAS blank-to-NA: SAS stores missing character values as " " (one space).
    # Convert any all-whitespace character column value to NA so that
    # downstream summaries and filters behave consistently with other formats.
    #
    # NOTE (BUG-05 fix): preserve per-column attributes and class.  The
    # previous as.data.frame(lapply(df, ...)) round-trip dropped haven's
    # `label`, `format.sas`, and `haven_labelled` class, which broke the
    # Variable Metadata table for SAS inputs.  We now modify in-place and
    # only touch character columns.
    if (ext %in% c("sas7bdat", "xpt")) {
      for (nm in names(df)) {
        if (is.character(df[[nm]])) {
          attrs_cls <- list(attrs = attributes(df[[nm]]),
                            cls   = class(df[[nm]]))
          df[[nm]][trimws(df[[nm]]) == ""] <- NA_character_
          # Re-attach saved attributes / class (replacement assignment can drop them)
          for (a in names(attrs_cls$attrs)) {
            attr(df[[nm]], a) <- attrs_cls$attrs[[a]]
          }
          class(df[[nm]]) <- attrs_cls$cls
        }
      }
    }

    # BUG-20 fix: .rds files may contain any serialised R object.  Reject
    # anything that isn't a data.frame so the user gets a clear error
    # instead of cryptic failures in downstream tabs.
    if (ext == "rds" && !inherits(df, "data.frame")) {
      stop(sprintf(
        "RDS file does not contain a data.frame (got: %s). Only data frames are supported.",
        paste(class(df), collapse = "/")
      ), call. = FALSE)
    }

    df
  }, error = function(e) {
    stop(paste("Error reading file:", e$message))
  })
}


#' Get metadata for a loaded dataset
#'
#' Returns file-level metadata including the number of rows and columns,
#' file size, and timestamps.
#'
#' @param df A `data.frame` or tibble (the loaded data).
#' @param filepath Character string. Path to the source file.
#'
#' @return A named list with elements: `filename`, `filepath`, `format`,
#'   `n_rows`, `n_cols`, `file_size`, `modified`, and `created`.
#'
#' @examples
#' \dontrun{
#' df <- read_dataset("/data/demog.csv")
#' meta <- get_dataset_metadata(df, "/data/demog.csv")
#' meta$n_rows
#' }
#'
#' @export
get_dataset_metadata <- function(df, filepath) {
  file_info <- file.info(filepath)

  list(
    filename  = basename(filepath),
    filepath  = filepath,
    format    = toupper(tools::file_ext(filepath)),
    n_rows    = nrow(df),
    n_cols    = ncol(df),
    file_size = format_file_size(file_info$size),
    modified  = as.character(file_info$mtime),
    created   = as.character(file_info$ctime)
  )
}


#' Extract variable-level metadata from a dataset
#'
#' Returns a data frame describing each variable: its type, SAS label,
#' SAS format, missing value counts, and number of unique values.
#'
#' @param df A `data.frame` or tibble.
#'
#' @return A `data.frame` with columns `Variable`, `Type`, `Label`, `Format`,
#'   `Missing_Count`, `Missing_Pct`, and `N_Unique`.  As of 0.1.1,
#'   `N_Unique` counts distinct **non-missing** values, consistent with
#'   `skimr` and `DataExplorer`; the missing count is reported separately
#'   in `Missing_Count`.
#'
#' @examples
#' df <- data.frame(x = 1:5, y = letters[1:5])
#' get_variable_info(df)
#'
#' @export
get_variable_info <- function(df) {
  var_info <- data.frame(
    Variable      = names(df),
    Type          = vapply(df, function(x) {
      if (is.numeric(x))           "Numeric"
      else if (is.factor(x))       "Factor"
      else if (is.character(x))    "Character"
      else if (inherits(x, "Date")) "Date"
      else if (inherits(x, "POSIXct")) "DateTime"
      else class(x)[1]
    }, character(1)),
    Label         = vapply(df, function(x) {
      lbl <- attr(x, "label")
      if (is.null(lbl)) "" else as.character(lbl)
    }, character(1)),
    Format        = vapply(df, function(x) {
      fmt <- attr(x, "format.sas")
      if (is.null(fmt)) "" else as.character(fmt)
    }, character(1)),
    Missing_Count = vapply(df, function(x) sum(is.na(x)), integer(1)),
    Missing_Pct   = vapply(df, function(x)
      round(sum(is.na(x)) / length(x) * 100, 1), numeric(1)),
    # BUG-08 fix: count distinct NON-MISSING values, matching skimr / DataExplorer
    N_Unique      = vapply(df, function(x) length(unique(stats::na.omit(x))), integer(1)),
    stringsAsFactors = FALSE
  )
  rownames(var_info) <- NULL
  var_info
}


#' List supported dataset files in a directory
#'
#' Scans a directory for files with extensions `.sas7bdat`, `.xpt`, `.csv`,
#' or `.rds` (case-insensitive) and returns a summary data frame.
#'
#' @param dirpath Character string. Path to the directory to scan.
#'
#' @return A `data.frame` with columns `Name`, `Format`, `Size`, `Modified`,
#'   and `Path`.  Returns an empty data frame if no supported files are found.
#'
#' @examples
#' \dontrun{
#' datasets <- list_datasets("/data/mylib")
#' }
#'
#' @export
list_datasets <- function(dirpath) {
  supported_ext <- c("sas7bdat", "xpt", "csv", "rds")
  pattern <- paste0("\\.(", paste(supported_ext, collapse = "|"), ")$")

  files <- list.files(dirpath,
    pattern     = pattern,
    ignore.case = TRUE,
    full.names  = TRUE
  )

  if (length(files) == 0) {
    return(data.frame(
      Name     = character(0),
      Format   = character(0),
      Size     = character(0),
      Modified = character(0),
      Path     = character(0),
      stringsAsFactors = FALSE
    ))
  }

  info <- file.info(files)

  data.frame(
    Name     = tools::file_path_sans_ext(basename(files)),
    Format   = toupper(tools::file_ext(files)),
    Size     = vapply(info$size, format_file_size, character(1)),
    Modified = format(info$mtime, "%Y-%m-%d %H:%M"),
    Path     = files,
    stringsAsFactors = FALSE
  )
}


#' Format a file size in bytes as a human-readable string
#'
#' @param size Numeric. File size in bytes.
#'
#' @return A character string such as `"1.4 MB"` or `"340 KB"`.
#'
#' @examples
#' format_file_size(1048576)   # "1 MB"
#' format_file_size(512)       # "512 B"
#'
#' @export
format_file_size <- function(size) {
  if (is.na(size))     return("Unknown")
  if (size < 0)        return("Unknown")                # BUG-07 fix: guard against negative sizes
  units <- c("B", "KB", "MB", "GB", "TB", "PB")         # BUG-07 fix: extend beyond GB
  i <- 1L
  while (size >= 1024 && i < length(units)) {
    size <- size / 1024
    i <- i + 1L
  }
  paste(round(size, 1), units[i])
}


#' Compute summary statistics for numeric variables
#'
#' Returns a tidy data frame with N, mean, median, standard deviation,
#' minimum, and maximum for each numeric variable in `vars`.
#'
#' @param df A `data.frame` or tibble.
#' @param vars Character vector of variable names to summarise.
#' @param group_var Optional character string naming a grouping variable.
#'   Pass `NULL` (default) for no grouping.
#'
#' @return A `data.frame` (one row per variable, or per variable × group level)
#'   or `NULL` if there are no numeric variables in `vars`.
#'
#' @examples
#' df <- data.frame(x = rnorm(100), y = runif(100), g = rep(c("A", "B"), 50))
#' compute_numeric_summary(df, c("x", "y"))
#' compute_numeric_summary(df, c("x", "y"), group_var = "g")
#'
#' @export
compute_numeric_summary <- function(df, vars, group_var = NULL) {
  # BUG-09 fix: friendly error when a name in `vars` is not in df.
  missing_vars <- setdiff(vars, names(df))
  if (length(missing_vars) > 0L) {
    stop("compute_numeric_summary: variable(s) not found in df: ",
         paste(shQuote(missing_vars), collapse = ", "), call. = FALSE)
  }
  numeric_vars <- vars[vapply(df[vars], is.numeric, logical(1))]
  if (length(numeric_vars) == 0L) return(NULL)

  if (!is.null(group_var) && nzchar(group_var) && group_var %in% names(df)) {
    df_grouped <- dplyr::group_by(df, .data[[group_var]])
  } else {
    df_grouped <- df
  }

  results <- lapply(numeric_vars, function(v) {
    suppressWarnings(
      dplyr::summarise(df_grouped,
        Variable = v,
        N        = sum(!is.na(.data[[v]])),
        Missing  = sum(is.na(.data[[v]])),
        Mean     = ifelse(all(is.na(.data[[v]])), NA_real_,
                     round(mean(.data[[v]], na.rm = TRUE), 2)),
        Median   = ifelse(all(is.na(.data[[v]])), NA_real_,
                     round(stats::median(.data[[v]], na.rm = TRUE), 2)),
        SD       = ifelse(all(is.na(.data[[v]])), NA_real_,
                     round(stats::sd(.data[[v]], na.rm = TRUE), 2)),
        Min      = ifelse(all(is.na(.data[[v]])), NA_real_,
                     round(min(.data[[v]], na.rm = TRUE), 2)),
        # BUG-13 fix: include lower / upper quartiles for consistency with
        # the Variable-Details panel and with skimr / DataExplorer.
        Q1       = ifelse(all(is.na(.data[[v]])), NA_real_,
                     round(stats::quantile(.data[[v]], 0.25, na.rm = TRUE,
                                           names = FALSE), 2)),
        Q3       = ifelse(all(is.na(.data[[v]])), NA_real_,
                     round(stats::quantile(.data[[v]], 0.75, na.rm = TRUE,
                                           names = FALSE), 2)),
        Max      = ifelse(all(is.na(.data[[v]])), NA_real_,
                     round(max(.data[[v]], na.rm = TRUE), 2)),
        .groups  = "drop"
      )
    )
  })

  dplyr::bind_rows(results)
}


#' Compute frequency statistics for categorical variables
#'
#' Returns value frequencies and percentages for each non-numeric variable
#' in `vars`, optionally grouped by a second variable.
#'
#' @param df A `data.frame` or tibble.
#' @param vars Character vector of variable names to summarise.
#' @param group_var Optional character string naming a grouping variable.
#'   Pass `NULL` (default) for no grouping.
#'
#' @return A `data.frame` with columns for the grouping variable (if any),
#'   the value, its frequency count, percentage, and the variable name.
#'   Returns `NULL` if there are no categorical variables in `vars`.
#'
#' @examples
#' df <- data.frame(sex = c("M","F","M","F","M"), trt = c("A","A","B","B","A"))
#' compute_categorical_summary(df, c("sex", "trt"))
#'
#' @export
compute_categorical_summary <- function(df, vars, group_var = NULL) {
  # BUG-09 fix: friendly error when a name in `vars` is not in df.
  missing_vars <- setdiff(vars, names(df))
  if (length(missing_vars) > 0L) {
    stop("compute_categorical_summary: variable(s) not found in df: ",
         paste(shQuote(missing_vars), collapse = ", "), call. = FALSE)
  }
  cat_vars <- vars[!vapply(df[vars], is.numeric, logical(1))]
  if (length(cat_vars) == 0L) return(NULL)

  results <- lapply(cat_vars, function(v) {
    if (!is.null(group_var) && nzchar(group_var) && group_var %in% names(df)) {
      freq <- dplyr::count(df, .data[[group_var]], .data[[v]], name = "Frequency")
      freq <- dplyr::group_by(freq, .data[[group_var]])
      freq <- dplyr::mutate(freq,
        Percentage = round(Frequency / sum(Frequency) * 100, 1))
      freq <- dplyr::ungroup(freq)
    } else {
      freq <- dplyr::count(df, .data[[v]], name = "Frequency")
      freq <- dplyr::mutate(freq,
        Percentage = round(Frequency / sum(Frequency) * 100, 1))
    }
    freq$Variable <- v
    freq
  })

  dplyr::bind_rows(results)
}
utils::globalVariables(c("Frequency", "preview_text"))


#' Compute a cross-tabulation of two categorical variables
#'
#' Produces a wide-format contingency table of `row_var` (rows) by `col_var`
#' (columns), including row and column totals.  When a `strat_var` is supplied
#' the table is computed separately for each level of the stratification
#' variable and the results are stacked with a leading `Stratum` column.
#'
#' Missing values in any of the three variables are displayed as `"(Missing)"`
#' rather than being silently dropped, so analysts can spot incomplete records.
#'
#' @param df A `data.frame` or tibble.
#' @param row_var Character string. Name of the row variable (e.g. `"SEX"`).
#' @param col_var Character string. Name of the column variable (e.g. `"RACE"`).
#' @param strat_var Character string or `NULL`. Optional stratification
#'   variable (e.g. `"TRT01P"`).  Pass `NULL` or `""` for an unstratified
#'   table.
#'
#' @return A `data.frame` in wide format:
#'   \itemize{
#'     \item Column 1 (or 2 if stratified): `row_var` levels plus a `"Total"` row.
#'     \item Middle columns: one column per `col_var` level.
#'     \item Last column: `Total` (row sums).
#'     \item If `strat_var` is given, a leading `Stratum` column identifies
#'       each stratum.  A grand-total block across all strata is **not**
#'       appended automatically — compute the unstratified table for that.
#'   }
#'
#' @examples
#' df <- data.frame(
#'   SEX  = c("M","F","M","F","M","F"),
#'   RACE = c("White","White","Black","Asian","Black","White"),
#'   TRT  = c("A","A","B","B","A","B")
#' )
#' compute_crosstab(df, "SEX", "RACE")
#' compute_crosstab(df, "SEX", "RACE", strat_var = "TRT")
#'
#' @export
compute_crosstab <- function(df, row_var, col_var, strat_var = NULL) {
  # BUG-15 fix: validate inputs up-front for clear, actionable errors.
  needed  <- c(row_var, col_var,
               if (!is.null(strat_var) && nzchar(strat_var)) strat_var)
  missing <- setdiff(needed, names(df))
  if (length(missing) > 0L) {
    stop("compute_crosstab: variable(s) not found in df: ",
         paste(shQuote(missing), collapse = ", "), call. = FALSE)
  }
  if (identical(row_var, col_var)) {
    stop("compute_crosstab: row_var and col_var must be different.",
         call. = FALSE)
  }
  if (!is.null(strat_var) && nzchar(strat_var) &&
      (identical(strat_var, row_var) || identical(strat_var, col_var))) {
    stop("compute_crosstab: strat_var must differ from row_var and col_var.",
         call. = FALSE)
  }

  # BUG-14 fix: warn when source data carries literal "Total" or "(Missing)"
  # values that would collide with synthetic labels.
  combined_vals <- unique(c(as.character(df[[row_var]]),
                            as.character(df[[col_var]])))
  if ("Total" %in% combined_vals) {
    warning("compute_crosstab: data contains a value literally equal to 'Total'; ",
            "synthetic Total row/column may be indistinguishable.",
            call. = FALSE)
  }
  if ("(Missing)" %in% combined_vals) {
    warning("compute_crosstab: data contains a value literally equal to '(Missing)'; ",
            "real values will be indistinguishable from NA-relabelled cells.",
            call. = FALSE)
  }

  # ── helper: NA → "(Missing)" for display ──────────────────────────
  to_label <- function(x) ifelse(is.na(x), "(Missing)", as.character(x))

  # ── helper: build one contingency table for a sub-data.frame ──────
  make_one_ct <- function(sub_df, rv, cv) {
    row_lab <- to_label(sub_df[[rv]])
    col_lab <- to_label(sub_df[[cv]])

    ct      <- table(row_lab, col_lab)
    ct_wide <- as.data.frame.matrix(ct)          # rows = rv levels, cols = cv levels

    # Row totals column
    ct_wide[["Total"]] <- rowSums(ct_wide)

    # Column totals row
    col_totals           <- as.data.frame(t(colSums(ct_wide)))
    ct_wide              <- rbind(ct_wide, col_totals)

    # Promote rownames to a proper column (rv name)
    ct_wide[[rv]] <- c(rownames(ct_wide)[seq_len(nrow(ct_wide) - 1L)], "Total")
    rownames(ct_wide) <- NULL

    # Put rv column first
    ct_wide[, c(rv, setdiff(names(ct_wide), rv)), drop = FALSE]
  }

  # ── stratified path ───────────────────────────────────────────────
  if (!is.null(strat_var) && nzchar(strat_var) && strat_var %in% names(df)) {
    strat_labels <- sort(unique(to_label(df[[strat_var]])))
    parts <- lapply(strat_labels, function(lv) {
      sub_df <- df[to_label(df[[strat_var]]) == lv, , drop = FALSE]
      ct_df  <- make_one_ct(sub_df, row_var, col_var)
      ct_df[["Stratum"]] <- paste0(strat_var, " = ", lv)
      ct_df[, c("Stratum", names(ct_df)[names(ct_df) != "Stratum"]), drop = FALSE]
    })
    return(dplyr::bind_rows(parts))
  }

  # ── unstratified path ─────────────────────────────────────────────
  make_one_ct(df, row_var, col_var)
}
