#' Dataset Converter Module – UI
#'
#' Renders a two-column card layout: a conversion form on the left and a
#' format-reference table plus output preview on the right.
#'
#' @param id Character string. The Shiny module namespace identifier.
#'
#' @return A [shiny::tagList()] with the converter UI.
#'
#' @seealso [converter_server()]
#'
#' @export
converter_ui <- function(id) {
  ns <- shiny::NS(id)

  shiny::tagList(
    shiny::div(
      class = "mt-2",
      style = "min-height: calc(100vh - 120px);",
      shiny::fluidRow(
        style = "align-items: stretch;",

        # Left card: conversion controls --------------------------------
        shiny::column(6,
          shiny::div(
            class = "card h-100",
            shiny::div(
              class = "card-body d-flex flex-column",
              shiny::h5(shiny::icon("exchange-alt"), " Convert Dataset",
                class = "card-title"),
              shiny::p(class = "text-muted",
                "Convert the currently loaded dataset to a different format."),

              shiny::uiOutput(ns("current_dataset_info")),
              shiny::hr(),

              shiny::radioButtons(ns("output_format"), "Output Format:",
                choices = c(
                  "R Data (.rds)"        = "rds",
                  "Excel (.xlsx)"        = "xlsx",
                  "CSV (.csv)"           = "csv",
                  "JSON (.json)"         = "json",
                  "SAS Transport (.xpt)" = "xpt"
                ),
                selected = "csv"
              ),

              shiny::conditionalPanel(
                condition = paste0("input['", ns("output_format"), "'] == 'csv'"),
                shiny::div(
                  class = "border rounded p-2 bg-light mb-2",
                  shiny::checkboxInput(ns("csv_header",
                    "Include header row", value = TRUE),
                  shiny::selectInput(ns("csv_delim"), "Delimiter:",
                    choices  = c("Comma" = ",", "Semicolon" = ";",
                      "Tab" = "\t", "Pipe" = "|"),
                    selected = ","
                  )
                )
              ),

              shiny::conditionalPanel(
                condition = paste0("input['",
                  ns("output_format"), "'] == 'json'"),
                shiny::div(
                  class = "border rounded p-2 bg-light mb-2",
                  shiny::checkboxInput(ns("json_pretty",
                    "Pretty print JSON", value = TRUE)
                )
              ),

              # Download status badge
              shiny::uiOutput(ns("download_status")),

              shiny::div(class = "d-grid mt-auto pt-3",
                shiny::downloadButton(ns("download_converted",
                  label = tagList(shiny::icon("download"), " Download Converted File"),
                  class = "btn-primary btn-lg")
              )
            )
          )
        ),

        # Right card: format details + preview --------------------------
        shiny::column(6,
          shiny::div(
            class = "card h-100",
            shiny::div(
              class = "card-body d-flex flex-column",
              shiny::h5(shiny::icon("info-circle"), " Format Details",
                class = "card-title"),
              shiny::div(class = "format-info",
                shiny::h6("Supported Output Formats:", class = "text-muted"),
                shiny::tags$table(class = "table table-sm table-hover",
                  shiny::tags$thead(shiny::tags$tr(
                    shiny::tags$th("Format"),
                    shiny::tags$th("Extension"),
                    shiny::tags$th("Package"),
                    shiny::tags$th("Notes")
                  )),
                  shiny::tags$tbody(
                    shiny::tags$tr(
                      shiny::tags$td("R Data"),
                      shiny::tags$td(shiny::tags$code(".rds")),
                      shiny::tags$td(shiny::tags$code("base R")),
                      shiny::tags$td("Preserves R data types")),
                    shiny::tags$tr(
                      shiny::tags$td("Excel"),
                      shiny::tags$td(shiny::tags$code(".xlsx")),
                      shiny::tags$td(shiny::tags$code("writexl")),
                      shiny::tags$td("Excel/LibreOffice compatible")),
                    shiny::tags$tr(
                      shiny::tags$td("CSV"),
                      shiny::tags$td(shiny::tags$code(".csv")),
                      shiny::tags$td(shiny::tags$code("readr")),
                      shiny::tags$td("Universal text format")),
                    shiny::tags$tr(
                      shiny::tags$td("JSON"),
                      shiny::tags$td(shiny::tags$code(".json")),
                      shiny::tags$td(shiny::tags$code("jsonlite")),
                      shiny::tags$td("Web/API compatible")),
                    shiny::tags$tr(
                      shiny::tags$td("SAS Transport"),
                      shiny::tags$td(shiny::tags$code(".xpt")),
                      shiny::tags$td(shiny::tags$code("haven")),
                      shiny::tags$td("SAS V5 transport format"))
                  )
                )
              ),
              shiny::hr(),
              shiny::h6("Output Preview (first 3 rows):", class = "text-muted"),
              shiny::div(
                class = "flex-grow-1",
                shiny::verbatimTextOutput(ns("output_preview"))
              )
            )
          )
        )
      )
    )
  )
}

#' Dataset Converter Module – Server
#'
#' Handles the dataset-conversion download for all supported output formats:
#' `.rds`, `.xlsx`, `.csv`, `.json`, and SAS transport `.xpt`.
#'
#' @param id Character string. The Shiny module namespace identifier.
#' @param loaded_data A [shiny::reactiveVal()] containing the current
#'   `data.frame`.
#' @param selected_dataset A [shiny::reactiveVal()] with the file path of the
#'   active dataset.
#'
#' @return `NULL` (invisibly).  Called for side effects.
#'
#' @seealso [converter_ui()]
#'
#' @export
converter_server <- function(id, loaded_data, selected_dataset) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Track number of successful downloads
    download_count <- shiny::reactiveVal(0L)

    # Dataset info card -------------------------------------------------
    output$current_dataset_info <- shiny::renderUI({
      shiny::req(loaded_data(), selected_dataset())
      meta <- get_dataset_metadata(loaded_data(), selected_dataset())
      shiny::div(class = "alert alert-info py-2",
        shiny::strong("Current Dataset: "), meta$filename, shiny::br(),
        shiny::strong("Observations: "),
          format(meta$n_rows, big.mark = ","), " | ",
        shiny::strong("Variables: "), meta$n_cols, " | ",
        shiny::strong("Size: "), meta$file_size
      )
    })

    # Download status badge ---------------------------------------------
    output$download_status <- shiny::renderUI({
      n <- download_count()
      if (n == 0L) return(NULL)
      shiny::div(
        class = "mt-2",
        shiny::span(
          class = "badge bg-success",
          shiny::icon("check-circle"),
          sprintf(" %d file%s converted this session", n, if (n == 1L) "" else "s")
        )
      )
    })

    # Output preview ----------------------------------------------------
    output$output_preview <- shiny::renderText({
      shiny::req(loaded_data())
      df <- utils::head(loaded_data(), 3L)

      switch(input$output_format,
        "csv" = {
          con <- textConnection("preview_text", "w")
          on.exit({
            if (isOpen(con)) close(con)
          }, add = TRUE)
          utils::write.csv(df, con, row.names = FALSE)
          close(con)
          paste(utils::head(preview_text, 5L), collapse = "\n")
        },
        "json" = {
          substr(jsonlite::toJSON(df, pretty = input$json_pretty,
            auto_unbox = TRUE), 1L, 500L)
        },
        "rds"  = paste(
          "Binary R format",
          "Preserves all data types, labels, and attributes.",
          "Read with: readRDS('filename.rds')",
          sep = "\n"),
        "xlsx" = paste(
          "Excel workbook format",
          "Opens in Microsoft Excel, LibreOffice Calc, Google Sheets.",
          "Sheet name: 'Data'",
          sep = "\n"),
        "xpt"  = paste(
          "SAS V5 Transport format",
          "Compatible with SAS, FDA submissions.",
          "Note: Variable names limited to 8 characters.",
          sep = "\n")
      )
    })

    # Download handler --------------------------------------------------
    output$download_converted <- shiny::downloadHandler(
      filename = function() {
        shiny::req(selected_dataset())
        base <- tools::file_path_sans_ext(basename(selected_dataset()))
        paste0(base, "_converted.", input$output_format)
      },
      content = function(file) {
        shiny::req(loaded_data())
        df <- loaded_data()

        shiny::withProgress(message = "Converting dataset...", value = 0, {
          shiny::incProgress(0.2, detail = "Preparing data...");

          switch(input$output_format,
            "rds"  = saveRDS(df, file),
            "xlsx" = writexl::write_xlsx(list(Data = as.data.frame(df)), file),
            "csv"  = {
              if (input$csv_delim == ",") {
                readr::write_csv(df, file, col_names = input$csv_header)
              } else {
                readr::write_delim(df, file,
                  delim     = input$csv_delim,
                  col_names = input$csv_header)
              }
            },
            "json" = {
              json_str <- jsonlite::toJSON(df,
                pretty      = input$json_pretty,
                auto_unbox  = TRUE)
              writeLines(json_str, file)
            },
            "xpt"  = {
              df_xpt      <- df
              short_names <- substr(names(df_xpt), 1L, 8L)
              short_names <- make.unique(short_names, sep = "")
              short_names <- substr(short_names, 1L, 8L)
              names(df_xpt) <- short_names
              ds_name <- substr(
                tools::file_path_sans_ext(basename(selected_dataset())),
                1L, 8L);
              haven::write_xpt(df_xpt, file, version = 5L, name = ds_name)
            }
          )

          shiny::incProgress(0.8, detail = "Done.")
        })

        download_count(download_count() + 1L)

        shiny::showNotification(
          shiny::tagList(shiny::icon("check"), " Dataset converted successfully!"),
          type     = "message",
          duration = 4
        )
      }
    )

    invisible(NULL)
  })
}