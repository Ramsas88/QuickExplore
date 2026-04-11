test_that("format_file_size handles bytes, KB, MB, GB", {
  expect_equal(format_file_size(512),        "512 B")
  expect_equal(format_file_size(1024),       "1 KB")
  expect_equal(format_file_size(1048576),    "1 MB")
  expect_equal(format_file_size(1073741824), "1 GB")
  expect_equal(format_file_size(NA),         "Unknown")
})

test_that("get_variable_info returns correct columns", {
  df  <- data.frame(x = 1:5, y = letters[1:5], stringsAsFactors = FALSE)
  out <- get_variable_info(df)

  expect_s3_class(out, "data.frame")
  expect_named(out, c("Variable", "Type", "Label", "Format",
    "Missing_Count", "Missing_Pct", "N_Unique"))
  expect_equal(out$Variable, c("x", "y"))
  expect_equal(out$Type,     c("Numeric", "Character"))
  expect_equal(out$Missing_Count, c(0L, 0L))
})

test_that("get_variable_info handles missing values", {
  df  <- data.frame(x = c(1, NA, 3), stringsAsFactors = FALSE)
  out <- get_variable_info(df)

  expect_equal(out$Missing_Count, 1L)
  expect_equal(out$Missing_Pct,   round(1 / 3 * 100, 1))
})

test_that("list_datasets returns empty data frame for empty dir", {
  tmp <- withr::local_tempdir()
  out <- list_datasets(tmp)

  expect_s3_class(out, "data.frame")
  expect_equal(nrow(out), 0L)
  expect_named(out, c("Name", "Format", "Size", "Modified", "Path"))
})

test_that("list_datasets finds CSV files", {
  tmp <- withr::local_tempdir()
  f   <- file.path(tmp, "demo.csv")
  utils::write.csv(data.frame(a = 1:3), f, row.names = FALSE)

  out <- list_datasets(tmp)
  expect_equal(nrow(out), 1L)
  expect_equal(out$Name,   "demo")
  expect_equal(out$Format, "CSV")
})

test_that("read_dataset reads a CSV file", {
  tmp <- withr::local_tempdir()
  f   <- file.path(tmp, "test.csv")
  df_in <- data.frame(x = 1:3, y = c("a", "b", "c"), stringsAsFactors = FALSE)
  utils::write.csv(df_in, f, row.names = FALSE)

  df_out <- read_dataset(f)
  expect_s3_class(df_out, "data.frame")
  expect_equal(nrow(df_out), 3L)
  expect_equal(ncol(df_out), 2L)
})

test_that("read_dataset reads an RDS file", {
  tmp   <- withr::local_tempdir()
  f     <- file.path(tmp, "test.rds")
  df_in <- data.frame(a = 1:4)
  saveRDS(df_in, f)

  df_out <- read_dataset(f)
  expect_equal(nrow(df_out), 4L)
})

test_that("read_dataset errors on unsupported extension", {
  expect_error(read_dataset("/tmp/fakefile.xyz"), "Unsupported")
})

test_that("compute_numeric_summary returns NULL for no numeric vars", {
  df  <- data.frame(a = letters[1:3], stringsAsFactors = FALSE)
  out <- compute_numeric_summary(df, "a")
  expect_null(out)
})

test_that("compute_numeric_summary returns correct columns", {
  df  <- data.frame(x = c(1, 2, 3, 4, 5))
  out <- compute_numeric_summary(df, "x")

  expect_s3_class(out, "data.frame")
  expect_true(all(c("Variable", "N", "Mean", "Median", "SD") %in% names(out)))
  expect_equal(out$Mean, 3)
})

test_that("compute_categorical_summary returns NULL for all-numeric vars", {
  df  <- data.frame(x = 1:3)
  out <- compute_categorical_summary(df, "x")
  expect_null(out)
})

test_that("compute_categorical_summary returns frequencies", {
  df  <- data.frame(sex = c("M", "F", "M", "F", "M"),
    stringsAsFactors = FALSE)
  out <- compute_categorical_summary(df, "sex")

  expect_s3_class(out, "data.frame")
  expect_true("Frequency" %in% names(out))
  expect_true("Percentage" %in% names(out))
  expect_equal(sum(out$Frequency), 5L)
})

test_that("get_dataset_metadata returns correct structure", {
  tmp <- withr::local_tempdir()
  f   <- file.path(tmp, "demo.csv")
  df  <- data.frame(a = 1:3)
  utils::write.csv(df, f, row.names = FALSE)
  df_loaded <- read_dataset(f)

  meta <- get_dataset_metadata(df_loaded, f)

  expect_equal(meta$filename, "demo.csv")
  expect_equal(meta$format,   "CSV")
  expect_equal(meta$n_rows,   3L)
  expect_equal(meta$n_cols,   1L)
})
