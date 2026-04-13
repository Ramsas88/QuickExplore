#' Data Viewer Module – UI
#'
#' Creates a tabbed panel with three sub-tabs: an interactive data table
#' (Data Viewer), a filter/subset interface (Explore Data), and a variable
#' metadata explorer (Variables).
#'
#' @param id Character string. The Shiny module namespace identifier.
#'
#' @return A [shiny::tagList()] with the viewer UI.
#'
#' @seealso [data_viewer_server()]
#'
#' @export
data_viewer_ui <- function(id) {
  ns <- shiny::NS(id)

  shiny::tagList(
    bslib::navset_card_tab(
      id = ns("viewer_tabs"),

      # Tab 1: Data Viewer ------------------------------------------------
      bslib::nav_panel(
        title = shiny::tagList(shiny::icon("table"), "Data Viewer"),
        value = "viewer",
        shiny::div(
          class = "mb-3 mt-2",
          shiny::fluidRow(
            shiny::column(6, shiny::uiOutput(ns("viewer_dataset_name"))),
            shiny::column(6,
              shiny::div(class = "text-end",
                shiny::downloadButton(ns("download_filtered"), "Export View",
                  class = "btn-outline-secondary btn-sm")
              )
            )
          )
        ),
        DT::dataTableOutput(ns("data_table"))
      ),

      # Tab 2: Explore Data -----------------------------------------------
      bslib::nav_panel(
        title = shiny::tagList(shiny::icon("filter"), "Explore Data"),
        value = "explore",
        shiny::div(
          class = "mt-2",
          shiny::fluidRow(
            shiny::column(4,
              shiny::selectizeInput(ns("explore_vars"), "Select Variables:",
                choices  = NULL,
                multiple = TRUE,
                options  = list(placeholder = "All variables")
              )
            ),
            shiny::column(5,
              shiny::textAreaInput(ns("filter_expr"), "Filter Expression:",
                placeholder = "e.g., AGE > 50 & SEX == 'F'",
                rows = 2
              )
            ),
            shiny::column(3,
              shiny::div(class = "mt-4",
                shiny::actionButton(ns("apply_filter"), "Apply Filter",
                  icon  = shiny::icon("play"),
                  class = "btn-primary btn-sm"
                ),
                shiny::actionButton(ns("clear_filter"), "Clear",
                  icon  = shiny::icon("eraser"),
                  class = "btn-outline-secondary btn-sm ms-1"
                )
              )
            )
          ),
          shiny::div(
            class = "mb-2",
            shiny::h6("Quick Filters:", class = "text-muted d-inline me-2"),
            shiny::uiOutput(ns("quick_filters"), inline = TRUE)
          ),
          shiny::uiOutput(ns("filter_info")),
          shiny::hr(),
          DT::dataTableOutput(ns("explore_table"))
        )
      ),

      # Tab 3: Variables --------------------------------------------------
      bslib::nav_panel(
        title = shiny::tagList(shiny::icon("list-alt"), "Variables"),
        value = "variables",
        shiny::div(
          class = "mt-2",
          shiny::fluidRow(
            shiny::column(8, shiny::h5("Variable Explorer")),
            shiny::column(4,
              shiny::div(class = "text-end",
                shiny::downloadButton(ns("download_var_info"),
                  "Export Variable Info",
                  class = "btn-outline-secondary btn-sm")
              )
            )
          ),
          DT::dataTableOutput(ns("var_table")),
          shiny::hr(),
          shiny::h6("Selected Variable Details", class = "text-muted"),
          shiny::uiOutput(ns("var_details"))
        )
      )
    )
  )
}


#' Data Viewer Module – Server
#'
#' Handles data display, filtering, variable inspection, and download for the
#' Data Viewer tab.
#'
#' @param id Character string. The Shiny module namespace identifier.
#' @param loaded_data A [shiny::reactiveVal()] containing the current
#'   `data.frame`.
#' @param selected_dataset A [shiny::reactiveVal()] with the file path of the
#'   active dataset.
#'
#' @return A named list with three elements:
#'   \describe{
#'     \item{`filtered_data`}{A [shiny::reactiveVal()] with the current filtered `data.frame`.}
#'     \item{`filter_expr`}{A [shiny::reactive()] returning the raw filter expression string.}
#'     \item{`selected_vars`}{A [shiny::reactive()] returning the selected variable names.}
#'   }
#'
#' @seealso [data_viewer_ui()]
#'
#' @export
data_viewer_server <- function(id, loaded_data, selected_dataset) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Internal helpers --------------------------------------------------
    value_or_zero <- function(x) if (is.null(x)) 0L else x

    apply_filter_to_data <- function(df, expr_text, selected_vars = NULL) {
      result     <- df
      expr_text  <- trimws(expr_text)
      if (nzchar(expr_text)) {
        expr   <- rlang::parse_expr(expr_text)
        result <- dplyr::filter(result, !!expr)
      }
      if (!is.null(selected_vars) && length(selected_vars) > 0L) {
        result <- result[, selected_vars, drop = FALSE]
      }
      result
    }

    # State -------------------------------------------------------------
    filtered_data           <- shiny::reactiveVal(NULL)
    quick_filter_map        <- shiny::reactiveVal(list())
    last_quick_filter_clicks <- shiny::reactiveVal(list())

    # Dataset name -------------------------------------------------------
    output$viewer_dataset_name <- shiny::renderUI({
      shiny::req(selected_dataset())
      shiny::h5(shiny::icon("database"), " ",
        tools::file_path_sans_ext(basename(selected_dataset())),
        class = "mb-0")
    })

    # Reset on new data -------------------------------------------------
    shiny::observeEvent(loaded_data(), {
      df <- loaded_data()
      shiny::req(df)
      shiny::updateSelectizeInput(session, "explore_vars",
        choices = names(df), selected = NULL)
      filtered_data(df)
      quick_filter_map(list())
      last_quick_filter_clicks(list())
    })

    # Main data table ---------------------------------------------------
    output$data_table <- DT::renderDataTable({
      shiny::req(loaded_data())
      df <- loaded_data()
      df <- as.data.frame(lapply(df, function(x) {
        if (inherits(x, "haven_labelled")) haven::as_factor(x) else x
      }))
      DT::datatable(df,
        options = list(
          pageLength  = 25,
          scrollX     = TRUE,
          scrollY     = "calc(100vh - 295px)",
          dom         = "Bfrtip",
          buttons     = list("copy", "csv"),
          columnDefs  = list(list(className = "dt-center", targets = "_all")),
          language    = list(
            info = "Showing _START_ to _END_ of _TOTAL_ observations")
        ),
        filter    = "top",
        rownames  = FALSE,
        class     = "table-striped table-hover table-sm",
        selection = "none"
      )
    })

    # Quick filters -----------------------------------------------------
    output$quick_filters <- shiny::renderUI({
      shiny::req(loaded_data())
      df <- loaded_data()

      numeric_vars <- names(df)[vapply(df, is.numeric, logical(1))]
      char_vars    <- names(df)[vapply(df,
        function(x) is.character(x) || is.factor(x), logical(1))]

      filter_examples <- list()
      if (length(numeric_vars) > 0L) {
        v   <- numeric_vars[[1L]]
        med <- round(stats::median(df[[v]], na.rm = TRUE), 1)
        if (is.finite(med))
          filter_examples[[paste0(v, " > ", med)]] <- paste0(v, " > ", med)
      }
      if (length(char_vars) > 0L) {
        v    <- char_vars[[1L]]
        vals <- unique(stats::na.omit(df[[v]]))
        if (length(vals) > 0L)
          filter_examples[[paste0(v, " == '", vals[[1L]], "'")]] <-
            paste0(v, " == '", vals[[1L]], "'")
      }
      if (length(filter_examples) == 0L) return(NULL)

      ids <- vapply(names(filter_examples),
        function(lbl) paste0("qf_", digest::digest(lbl)), character(1))
      quick_filter_map(stats::setNames(as.list(filter_examples), ids))

      lapply(seq_along(filter_examples), function(i) {
        shiny::actionLink(ns(ids[[i]]),
          label = names(filter_examples)[[i]],
          class = "badge bg-light text-dark me-1",
          style = "cursor: pointer; text-decoration: none;"
        )
      })
    })

    # Quick filter click observer ---------------------------------------
    shiny::observe({
      qf_map <- quick_filter_map()
      if (length(qf_map) == 0L) { last_quick_filter_clicks(list()); return() }

      prev_clicks <- last_quick_filter_clicks()[names(qf_map)]

      for (input_id in names(qf_map)) {
        cur_clk  <- value_or_zero(input[[input_id]])
        prev_clk <- value_or_zero(prev_clicks[[input_id]])
        if (cur_clk > prev_clk) {
          expr_text <- qf_map[[input_id]]
          shiny::updateTextAreaInput(session, "filter_expr", value = expr_text)
          tryCatch({
            filtered_data(
              apply_filter_to_data(loaded_data(), expr_text, input$explore_vars))
          }, error = function(e) {
            shiny::showNotification(
              paste("Invalid filter expression:", e$message), type = "error")
          })
        }
        prev_clicks[[input_id]] <- cur_clk
      }
      last_quick_filter_clicks(prev_clicks)
    })

    # Apply / clear filter ----------------------------------------------
    shiny::observeEvent(input$apply_filter, {
      shiny::req(loaded_data())
      tryCatch({
        filtered_data(
          apply_filter_to_data(loaded_data(), input$filter_expr,
            input$explore_vars))
      }, error = function(e) {
        shiny::showNotification(
          paste("Invalid filter expression:", e$message), type = "error")
      })
    })

    shiny::observeEvent(input$clear_filter, {
      shiny::updateTextAreaInput(session, "filter_expr", value = "")
      shiny::updateSelectizeInput(session, "explore_vars",
        selected = character(0))
      filtered_data(loaded_data())
    })

    # Filter info banner ------------------------------------------------
    output$filter_info <- shiny::renderUI({
      shiny::req(loaded_data(), filtered_data())
      total   <- nrow(loaded_data())
      current <- nrow(filtered_data())
      if (current < total) {
        shiny::div(class = "alert alert-info py-1 px-2 mb-2",
          shiny::icon("filter"), " ",
          format(current, big.mark = ","), " of ",
          format(total,   big.mark = ","), " observations",
          paste0(" (", round(current / total * 100, 1), "%)")
        )
      }
    })

    # Explore table -----------------------------------------------------
    output$explore_table <- DT::renderDataTable({
      shiny::req(filtered_data())
      df <- filtered_data()
      df <- as.data.frame(lapply(df, function(x) {
        if (inherits(x, "haven_labelled")) haven::as_factor(x) else x
      }))
      DT::datatable(df,
        options = list(
          pageLength = 25, scrollX = TRUE, scrollY = "calc(100vh - 410px)",
          dom      = "frtip",
          language = list(
            info = "Showing _START_ to _END_ of _TOTAL_ filtered observations")
        ),
        filter = "top", rownames = FALSE,
        class = "table-striped table-hover table-sm", selection = "none"
      )
    })

    # Download filtered -------------------------------------------------
    output$download_filtered <- shiny::downloadHandler(
      filename = function() {
        base <- tools::file_path_sans_ext(basename(selected_dataset()))
        paste0(base, "_filtered_", Sys.Date(), ".csv")
      },
      content = function(file) {
        df <- if (!is.null(filtered_data())) filtered_data() else loaded_data()
        readr::write_csv(df, file)
      }
    )

    # Variable table ----------------------------------------------------
    output$var_table <- DT::renderDataTable({
      shiny::req(loaded_data())
      var_info <- get_variable_info(loaded_data())
      DT::datatable(var_info,
        options = list(
          pageLength = 50, scrollX = TRUE, dom = "ft",
          columnDefs = list(
            list(className = "dt-center", targets = c(1L, 4L, 5L, 6L)))
        ),
        rownames = FALSE,
        class    = "table-striped table-hover table-sm",
        selection = "single"
      ) |>
        DT::formatStyle("Missing_Pct",
          background         = DT::styleColorBar(c(0, 100), "salmon"),
          backgroundSize     = "100% 90%",
          backgroundRepeat   = "no-repeat",
          backgroundPosition = "center"
        ) |>
        DT::formatStyle("Type",
          color = DT::styleEqual(
            c("Numeric", "Character", "Factor", "Date", "DateTime"),
            c("#0d6efd", "#198754", "#6f42c1", "#fd7e14", "#dc3545")
          ),
          fontWeight = "bold"
        )
    })

    # Variable details panel --------------------------------------------
    output$var_details <- shiny::renderUI({
      shiny::req(loaded_data())
      sel <- input$var_table_rows_selected
      if (is.null(sel) || length(sel) == 0L)
        return(shiny::div(class = "text-muted",
          "Click a variable above to see details."))

      df       <- loaded_data()
      var_info <- get_variable_info(df)
      var_name <- var_info$Variable[[sel]]
      col_data <- df[[var_name]]

      if (is.numeric(col_data)) {
        shiny::tagList(
          shiny::h6(paste("Variable:", var_name), class = "fw-bold"),
          shiny::tags$table(class = "table table-sm",
            shiny::tags$tr(
              shiny::tags$td("Type:"),
              shiny::tags$td(class(col_data)[[1L]])),
            shiny::tags$tr(
              shiny::tags$td("N:"),
              shiny::tags$td(sum(!is.na(col_data)))),
            shiny::tags$tr(
              shiny::tags$td("Missing:"),
              shiny::tags$td(sum(is.na(col_data)))),
            shiny::tags$tr(
              shiny::tags$td("Mean:"),
              shiny::tags$td(round(mean(col_data, na.rm = TRUE), 4))),
            shiny::tags$tr(
              shiny::tags$td("Median:"),
              shiny::tags$td(round(stats::median(col_data, na.rm = TRUE), 4))),
            shiny::tags$tr(
              shiny::tags$td("Std Dev:"),
              shiny::tags$td(round(stats::sd(col_data, na.rm = TRUE), 4))),
            shiny::tags$tr(
              shiny::tags$td("Min:"),
              shiny::tags$td(round(min(col_data, na.rm = TRUE), 4))),
            shiny::tags$tr(
              shiny::tags$td("Max:"),
              shiny::tags$td(round(max(col_data, na.rm = TRUE), 4))),
            shiny::tags$tr(
              shiny::tags$td("Q1:"),
              shiny::tags$td(
                round(stats::quantile(col_data, 0.25, na.rm = TRUE), 4))),
            shiny::tags$tr(
              shiny::tags$td("Q3:"),
              shiny::tags$td(
                round(stats::quantile(col_data, 0.75, na.rm = TRUE), 4)))
          )
        )
      } else {
        freq    <- sort(table(col_data), decreasing = TRUE)
        top_n   <- min(10L, length(freq))
        top_vals <- utils::head(freq, top_n)

        freq_rows <- lapply(seq_along(top_vals), function(i) {
          shiny::tags$tr(
            shiny::tags$td(names(top_vals)[[i]]),
            shiny::tags$td(as.integer(top_vals[[i]])),
            shiny::tags$td(
              paste0(round(top_vals[[i]] / length(col_data) * 100, 1), "%"))
          )
        })

        shiny::tagList(
          shiny::h6(paste("Variable:", var_name), class = "fw-bold"),
          shiny::tags$table(class = "table table-sm mb-2",
            shiny::tags$tr(
              shiny::tags$td("Type:"),
              shiny::tags$td(class(col_data)[[1L]])),
            shiny::tags$tr(
              shiny::tags$td("N:"),
              shiny::tags$td(sum(!is.na(col_data)))),
            shiny::tags$tr(
              shiny::tags$td("Missing:"),
              shiny::tags$td(sum(is.na(col_data)))),
            shiny::tags$tr(
              shiny::tags$td("Unique:"),
              shiny::tags$td(length(unique(col_data))))
          ),
          shiny::h6(paste0("Top ", top_n, " Values:"), class = "text-muted"),
          shiny::tags$table(class = "table table-sm table-striped",
            shiny::tags$thead(shiny::tags$tr(
              shiny::tags$th("Value"),
              shiny::tags$th("Count"),
              shiny::tags$th("Pct")
            )),
            shiny::tags$tbody(freq_rows)
          )
        )
      }
    })

    # Download variable info --------------------------------------------
    output$download_var_info <- shiny::downloadHandler(
      filename = function() {
        base <- tools::file_path_sans_ext(basename(selected_dataset()))
        paste0(base, "_variables_", Sys.Date(), ".csv")
      },
      content = function(file) {
        readr::write_csv(get_variable_info(loaded_data()), file)
      }
    )

    list(
      filtered_data = filtered_data,
      filter_expr   = shiny::reactive(input$filter_expr),
      selected_vars = shiny::reactive(input$explore_vars)
    )
  })
}
