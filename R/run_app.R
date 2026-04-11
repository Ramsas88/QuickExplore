#' Launch the Dataset Explorer Shiny Application
#'
#' Opens the interactive Dataset Explorer in your default web browser (or the
#' RStudio Viewer pane when called from within RStudio).  The application
#' provides a SAS Studio-style interface for browsing libraries, exploring
#' datasets, computing summary statistics, and converting between data formats.
#'
#' @param ... Additional arguments passed to [shiny::runApp()], such as
#'   `port`, `host`, or `launch.browser`.
#'
#' @return Called for its side effect of launching a Shiny application.
#'   Returns `NULL` invisibly.
#'
#' @examples
#' \dontrun{
#' # Launch with default settings
#' run_app()
#'
#' # Launch on a specific port without opening a browser
#' run_app(port = 4321, launch.browser = FALSE)
#' }
#'
#' @export
run_app <- function(...) {
  app_dir <- system.file("app", package = "dataexplorer")
  if (!nzchar(app_dir)) {
    stop(
      "Could not find the app directory. ",
      "Try re-installing dataexplorer with `install.packages('dataexplorer')`.",
      call. = FALSE
    )
  }
  shiny::runApp(app_dir, ...)
}
