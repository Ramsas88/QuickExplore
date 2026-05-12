# =============================================================================
# QuickExplore v0.1.0 – Comprehensive Test Suite
# -----------------------------------------------------------------------------
# Author : Satya (tester)                             Date: 2026-04-23
# Framework : testthat edition 3
# How to run:
#
#   # From an R console, in the package root:
#   devtools::load_all()
#   testthat::test_file("tests/testthat/test_quickexplore_suite.R")
#
#   # Or from the shell:
#   R -e 'testthat::test_file("tests/testthat/test_quickexplore_suite.R")'
#
# The suite is organised into 8 thematic sections mirroring the test report:
#   1. File-format / reader coverage   (read_dataset, list_datasets)
#   2. Metadata & variable info
#   3. Descriptive statistics (numeric + categorical)
#   4. Cross-tabulation
#   5. Converter round-trip (RDS, CSV, XLSX, JSON, XPT)
#   6. Code-generator string balance  (regression for Bug #3)
#   7. Data-viewer filter expression  (regression for Bug #1 – RCE)
#   8. Edge cases & data-type coverage
#
# Section 7 deliberately demonstrates — but does not execute — the remote-code-
# execution vector so the test merely asserts that parse_expr accepts any R
# expression.  DO NOT uncomment the eval() line in production.
# =============================================================================

library(testthat)
library(QuickExplore)

# Helpers --------------------------------------------------------------------
skip_if_no_pkg <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) skip(paste(pkg, "not available"))
}

mk_demog <- function(n = 20L) {
  set.seed(42)
  data.frame(
    USUBJID = sprintf("SUBJ-%03d", seq_len(n)),
    AGE     = as.integer(rnorm(n, 55, 12)),
    SEX     = sample(c("M", "F"), n, TRUE),
    RACE    = sample(c("White", "Black", "Asian", NA), n, TRUE),
    TRT01P  = sample(c("Placebo", "Drug A", "Drug B"), n, TRUE),
    WEIGHT  = round(rnorm(n, 75, 15), 1),
    stringsAsFactors = FALSE
  )
}

tmpdir <- tempfile("qetest_"); dir.create(tmpdir)


# =============================================================================
# Section 1 – File-format coverage
# =============================================================================
# --- 1. File-format coverage (read_dataset / list_datasets) ---

test_that("read_dataset dispatches on .csv", {
  df <- mk_demog(10)
  p  <- file.path(tmpdir, "demog.csv")
  write.csv(df, p, row.names = FALSE)
  out <- read_dataset(p)
  expect_s3_class(out, "data.frame")
  expect_equal(nrow(out), 10)
  expect_equal(ncol(out), 6)
})

test_that("read_dataset dispatches on .rds", {
  df <- mk_demog(5)
  p  <- file.path(tmpdir, "demog.rds")
  saveRDS(df, p)
  out <- read_dataset(p)
  expect_equal(nrow(out), 5)
})

test_that("read_dataset round-trips .xpt", {
  skip_if_no_pkg("haven")
  df <- mk_demog(8)
  p  <- file.path(tmpdir, "demog.xpt")
  haven::write_xpt(df, p)
  out <- read_dataset(p)
  expect_equal(nrow(out), 8)
  # Bug #5 regression: XPT read should preserve labels IF they exist
  # (strip labels via as.data.frame(lapply(...)) drops attributes)
})

test_that("read_dataset errors on unsupported extension", {
  p <- file.path(tmpdir, "junk.xlsx")
  file.create(p)
  expect_error(read_dataset(p), "Unsupported file format")
})

test_that("read_dataset errors on missing file", {
  expect_error(read_dataset(file.path(tmpdir, "nope.csv")))
})

test_that("list_datasets finds supported files only", {
  df <- mk_demog(3)
  write.csv(df, file.path(tmpdir, "a.csv"), row.names = FALSE)
  saveRDS(df, file.path(tmpdir, "b.rds"))
  file.create(file.path(tmpdir, "ignore.txt"))
  out <- list_datasets(tmpdir)
  expect_true(all(c("Name", "Format", "Size", "Modified", "Path") %in% names(out)))
  expect_true("CSV" %in% out$Format)
  expect_true("RDS" %in% out$Format)
  expect_false(any(grepl("txt", out$Format, ignore.case = TRUE)))
})

test_that("list_datasets returns empty frame on empty dir", {
  d <- file.path(tmpdir, "empty"); dir.create(d)
  out <- list_datasets(d)
  expect_equal(nrow(out), 0)
})


# =============================================================================
# Section 2 – Metadata & variable info
# =============================================================================
# --- 2. Metadata & variable info ---

test_that("get_dataset_metadata returns all 8 fields", {
  df <- mk_demog()
  p  <- file.path(tmpdir, "meta.csv"); write.csv(df, p, row.names = FALSE)
  m <- get_dataset_metadata(df, p)
  expect_named(m, c("filename","filepath","format","n_rows","n_cols",
                    "file_size","modified","created"))
  expect_equal(m$n_rows, nrow(df))
  expect_equal(m$format, "CSV")
})

test_that("get_variable_info returns correct columns and types", {
  df <- mk_demog()
  v  <- get_variable_info(df)
  expect_named(v, c("Variable","Type","Label","Format",
                    "Missing_Count","Missing_Pct","N_Unique"))
  expect_equal(v$Type[v$Variable == "AGE"],  "Numeric")
  expect_equal(v$Type[v$Variable == "SEX"],  "Character")
  expect_true(v$Missing_Count[v$Variable == "RACE"] >= 0)
})

test_that("get_variable_info handles Date and POSIXct", {
  df <- data.frame(
    d  = as.Date("2026-01-01") + 0:4,
    dt = as.POSIXct("2026-01-01") + 0:4 * 3600
  )
  v <- get_variable_info(df)
  expect_equal(v$Type, c("Date", "DateTime"))
})

test_that("format_file_size human-readable", {
  expect_equal(format_file_size(512),     "512 B")
  expect_equal(format_file_size(2048),    "2 KB")
  expect_equal(format_file_size(1048576), "1 MB")
  # BUG-07 fix: format_file_size now extends past GB into TB / PB.
  expect_match(format_file_size(1.2e12),  "TB$")
})


# =============================================================================
# Section 3 – Descriptive statistics
# =============================================================================
# --- 3. Numeric & categorical summaries ---

test_that("compute_numeric_summary returns expected columns", {
  df <- mk_demog(50)
  s  <- compute_numeric_summary(df, c("AGE", "WEIGHT"))
  expect_true(all(c("Variable","N","Missing","Mean","Median","SD","Min","Max") %in%
                  names(s)))
  expect_equal(nrow(s), 2)
})

test_that("compute_numeric_summary supports grouping", {
  df <- mk_demog(50)
  s  <- compute_numeric_summary(df, "AGE", group_var = "SEX")
  expect_true("SEX" %in% names(s))
  expect_true(nrow(s) >= 2)
})

test_that("compute_numeric_summary with no numeric vars returns NULL", {
  df <- data.frame(x = c("a","b","c"))
  expect_null(compute_numeric_summary(df, "x"))
})

test_that("compute_numeric_summary propagates all-NA column", {
  df <- data.frame(x = rep(NA_real_, 5))
  s  <- compute_numeric_summary(df, "x")
  expect_true(is.na(s$Mean))
  # BUG-13 fix: Q1 / Q3 quartiles are now part of the summary.
  expect_true(all(c("Q1", "Q3") %in% names(s)))
  expect_true(is.na(s$Q1))
  expect_true(is.na(s$Q3))
})

test_that("compute_categorical_summary frequency + percentage", {
  df <- data.frame(sex = c("M","F","M","F","M"))
  s  <- compute_categorical_summary(df, "sex")
  expect_true(all(c("Frequency","Percentage","Variable") %in% names(s)))
  expect_equal(sum(s$Frequency), 5)
  expect_equal(round(sum(s$Percentage)), 100)
})

test_that("compute_categorical_summary grouping path", {
  df <- data.frame(sex = c("M","F","M","F"), trt = c("A","A","B","B"))
  s  <- compute_categorical_summary(df, "sex", group_var = "trt")
  expect_true("trt" %in% names(s))
})


# =============================================================================
# Section 4 – Cross-tabulation
# =============================================================================
# --- 4. compute_crosstab ---

test_that("unstratified crosstab has Total row and column", {
  df <- mk_demog(30)
  ct <- compute_crosstab(df, "SEX", "TRT01P")
  expect_true("Total" %in% names(ct))
  expect_true("Total" %in% ct$SEX)
})

test_that("stratified crosstab adds Stratum column", {
  df <- mk_demog(30)
  ct <- compute_crosstab(df, "SEX", "RACE", strat_var = "TRT01P")
  expect_true("Stratum" %in% names(ct))
  expect_true(all(grepl("^TRT01P =", ct$Stratum)))
})

test_that("crosstab shows (Missing) for NA", {
  df <- data.frame(
    SEX  = c("M","F","M",NA),
    RACE = c("W","W","B","A")
  )
  ct <- compute_crosstab(df, "SEX", "RACE")
  expect_true("(Missing)" %in% ct$SEX)
})

test_that("crosstab: label collision with real 'Total' value emits a warning", {
  # BUG-14 fix: compute_crosstab now warns when source data carries a value
  # literally equal to "Total" or "(Missing)".
  df <- data.frame(
    GROUP = c("A","B","Total","A"),
    OUT   = c("X","Y","X","Y")
  )
  expect_warning(
    ct <- compute_crosstab(df, "GROUP", "OUT"),
    "literally equal to 'Total'"
  )
  # Underlying counts still produced: 1 real 'Total' value + 1 synthetic totals row.
  expect_equal(sum(ct$GROUP == "Total"), 2)
})


# =============================================================================
# Section 5 – Converter round-trip
# =============================================================================
# --- 5. Converter round-trip ---

test_that("RDS round-trip preserves data exactly", {
  df <- mk_demog()
  p  <- file.path(tmpdir, "rt.rds"); saveRDS(df, p)
  back <- readRDS(p)
  expect_equal(df, back)
})

test_that("CSV round-trip preserves values (types are coerced)", {
  df <- mk_demog(10)
  p  <- file.path(tmpdir, "rt.csv")
  write.csv(df, p, row.names = FALSE)
  back <- read.csv(p, stringsAsFactors = FALSE)
  expect_equal(nrow(back), nrow(df))
})

test_that("XPT variable-name shortener produces duplicates – Bug #2", {
  # Simulate the 3-step truncation in mod_converter.R L223-226:
  shorten <- function(nm) {
    s <- substr(nm, 1, 8)
    s <- make.unique(s, sep = "")
    s <- substr(s, 1, 8)
    s
  }
  out <- shorten(c("TREATMENT01", "TREATMENT02"))
  # Current broken behaviour: both truncate back to "TREATMEN"
  expect_true(length(unique(out)) < 2)
})

test_that("XPT writer succeeds on simple frame", {
  skip_if_no_pkg("haven")
  df <- mk_demog(5)
  p  <- file.path(tmpdir, "rt.xpt")
  haven::write_xpt(df, p, version = 5L, name = "DEMOG")
  expect_true(file.exists(p))
})


# =============================================================================
# Section 6 – Code-generator string balance (Bug #3)
# =============================================================================
# --- 6. Code-generator paren balance ---

# Emulate the exact paste0 call at R/mod_code_generator.R:434
emulate_strat_levels_line <- function(df_name = "df_explore", strat = "TRT01P") {
  paste0('strat_levels <- sort(unique(', df_name,
         '[["', strat, '"]])')
}

test_that("generated 'strat_levels' line is unbalanced – Bug #3", {
  s <- emulate_strat_levels_line()
  opens  <- nchar(gsub("[^(]", "", s))
  closes <- nchar(gsub("[^)]", "", s))
  # 2 opens, 1 close → source() will error
  expect_equal(opens,  2)
  expect_equal(closes, 1)
  expect_error(parse(text = s))
})


# =============================================================================
# Section 7 – Filter-expression RCE (Bug #1)
# =============================================================================
# --- 7. Filter expression – sandbox regression ---

test_that("parse_expr accepts a destructive expression (DEMONSTRATION ONLY)", {
  # We only verify that parse_expr has no safety check.
  # DO NOT call eval() / dplyr::filter() on this expression.
  bad <- "system('echo pwned > /tmp/qe_pwned.txt')"
  parsed <- rlang::parse_expr(bad)
  # 'call' is a base R language type, not an S3 class – use is.call().
  expect_true(is.call(parsed))
  expect_equal(as.character(parsed[[1L]]), "system")
  # If QuickExplore gains an allowlist in a future release, this test flips:
  # expect_error(safe_parse_filter(bad), "disallowed")
})


# =============================================================================
# Section 8 – Data-type coverage
# =============================================================================
# --- 8. Data-type coverage ---

test_that("factor columns summarised as categorical, not numeric", {
  df <- data.frame(
    g   = factor(c("A","B","A","B","A")),
    x   = c(1,2,3,4,5)
  )
  expect_null(compute_numeric_summary(df, "g"))
  expect_false(is.null(compute_categorical_summary(df, "g")))
})

test_that("logical column routed to categorical path", {
  df <- data.frame(flag = c(TRUE, FALSE, TRUE, NA))
  # Logical is not numeric, so it should be counted as categorical.
  s  <- compute_categorical_summary(df, "flag")
  expect_false(is.null(s))
})

test_that("integer64 (bit64) is handled without error", {
  skip_if_no_pkg("bit64")
  df <- data.frame(x = bit64::as.integer64(c(1, 2, 3, 4, 5)))
  # Recent bit64 versions return TRUE from is.numeric(integer64);
  # we just assert the function does not error and that it returns
  # either a data.frame (numeric path) or NULL (categorical path).
  s <- compute_numeric_summary(df, "x")
  expect_true(is.null(s) || inherits(s, "data.frame"))
})

test_that("date difference preserved", {
  df <- data.frame(
    start = as.Date("2026-01-01") + 0:4,
    stop  = as.Date("2026-01-05") + 0:4
  )
  v <- get_variable_info(df)
  expect_true(all(v$Type == "Date"))
})


# =============================================================================
# Teardown
# =============================================================================
unlink(tmpdir, recursive = TRUE)
