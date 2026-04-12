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
      shiny::fluidRow(

        # Left card: conversion controls --------------------------------
        shiny::column(6,
          shiny::div(class = "card",
            shiny::div(class = "card-body",
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
                shiny::checkboxInput(ns("csv_header",
                  "Include header row", value = TRUE),
                shiny::selectInput(ns("csv_delim"), "Delimiter:",
                  choices  = c("Comma" = ",", "Semicolon" = ";",
                    "Tab" = "\t", "Pipe" = "|"),
                  selected = ","
                )
              ),

              shiny::conditionalPanel(
                condition = paste0("input['",
                  ns("output_format"), "'] == 'json'"),
                shiny::checkboxInput(ns("json_pretty", 
                  "Pretty print JSON", value = TRUE)
              ),

              shiny::hr(),
              shiny::div(class = "d-grid",
                shiny::downloadButton(ns("download_converted",
                  "Download Converted File", class = "btn-primary")
              )
            )
          )
        ),

        # Right card: format details + preview --------------------------
        shiny::column(6,
          shiny::div(class = "card",
            shiny::div(class = "card-body",
              shiny::h5(shiny::icon("info-circle"), " Format Details",
                class = "card-title"),
              shiny::div(class = "format-info",
                shiny::h6("Supported Output Formats:", class = "text-muted"),
                shiny::tags$table(class = "table table-sm",
                  shiny::tags$thead(shiny::tags$tr(
                    shiny::tags$th("Format"),
                    shiny::tags$th("Extension"),
                    shiny::tags$th("Package"),
                    shiny::tags$th("Notes")
                  )),
                  shiny::tags$tbody(
                    shiny::tags$tr(
                      shiny::tags$td("R Data"), shiny::tags$td(".rds"),
                      shiny::tags$td("base R"),
                      shiny::tags$td("Preserves R data types")),
                    shiny::tags$tr(
                      shiny::tags$td("Excel"), shiny::tags$td(".xlsx"),
                      shiny::tags$td("writexl"),
                      shiny::tags$td("Excel/LibreOffice compatible")),
                    shiny::tags$tr(
                      shiny::tags$td("CSV"), shiny::tags$td(".csv"),
                      shiny::tags$td("readr"),
                      shiny::tags$td("Universal text format")),
                    shiny::tags$tr(
                      shiny::tags$td("JSON"), shiny::tags$td(".json"),
                      shiny::tags$td("jsonlite"),
                      shiny::tags$td("Web/API compatible")),
                    shiny::tags$tr(
                      shiny::tags$td("SAS Transport"), shiny::tags$td(".xpt"),
                      shiny::tags$td("haven"),
                      shiny::tags$td("SAS V5 transport format"))
                  )
                )
              ),
              shiny::hr(),
              shiny::h6("Output Preview:", class = "text-muted"),
              shiny::verbatimTextOutput(ns("output_preview"))
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

    # Output preview ----------------------------------------------------
    output$output_preview <- shiny::renderText({
      shiny::req(loaded_data())
      df <- utils::head(loaded_data(), 3L)

      switch(input$output_format,
        "csv" = {
          con          <- textConnection("preview_text", "w")
          utils::write.csv(df, con, row.names = FALSE)
          close(con)
          paste(utils::head(preview_text, 5L), collapse = "\n")
        },
        "json" = {
          substr(jsonlite::toJSON(df, pretty = input$json_pretty,
            auto_unbox = TRUE), 1L, 500L)
        },
        "rds"  = paste(
          "Binary R format\n",
          "Preserves all data types, labels, and attributes.\n",
          "Read with: readRDS('filename.rds')"),
        "xlsx" = paste(
          "Excel workbook format\n",
          "Opens in Microsoft Excel, LibreOffice Calc, Google Sheets.\n",
          "Sheet name: 'Data'"),
        "xpt"  = paste(
          "SAS V5 Transport format\n",
          "Compatible with SAS, FDA submissions.\n",
          "Note: Variable names limited to 8 characters.")
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

        shiny::withProgress(message = "Converting dataset...", {
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
                1L, 8L)
              haven::write_xpt(df_xpt, file, version = 5L, name = ds_name)
            }
          )
        })

        shiny::showNotification("Dataset converted successfully!",
          type = "message")
      }
    )

    invisible(NULL)
  })
}