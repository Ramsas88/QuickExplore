test_that("run_app() errors gracefully when package is not installed", {
  # When called from within the package source tree (devtools::test()),
  # system.file() finds the bundled app directory, so skip this check
  # in that context.
  skip_if(nzchar(system.file("app", package = "QuickExplore")),
    "Package is installed – app dir found, skip error path test")

  expect_error(run_app(), regexp = "Could not find the app directory")
})
