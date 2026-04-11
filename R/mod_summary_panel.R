#' Summary Panel Module – UI
#'
#' Renders the summary statistics panel with dataset overview cards plus
#' tables for numeric, categorical, and missing-value statistics.
#'
#' @param id Character string. The Shiny module namespace identifier.
#'
#' @return A [shiny::tagList()] with the summary UI elements.
#'
#' @seealso [summary_panel_server()]
#'
#' @export
summary_panel_ui <- function(id) {
  ns <- shiny::NS(id)

  shiny::tagList(
    shiny::div(
      class = "mt-2",
      shiny::fluidRow(
        shiny::column(4,
          shiny::selectizeInput(ns("summary_vars"), "Select Variables:",
            choices  = NULL,
            multiple = TRUE,
            options  = list(
              placeholder = "Select variables (or leave empty for all)")
          )
        ),
        shiny::column(3,
          shiny::selectInput(ns("group_var"), "Group By (optional):",
            choices = c("None" = ""))
        ),
        shiny::column(2,
          shiny::div(class = "mt-4",
            shiny::actionButton(ns("compute_summary"), "Compute",
              icon  = shiny::icon("calculator"),
              class = "btn-primary btn-sm")
          )
        ),
        shiny::column(3,
          shiny::div(class = "mt-4 text-end",
            shiny::downloadButton(ns("download_summary"), "Export Summary",
              class = "btn-outline-secondary btn-sm")
          )
        )
      ),

      shiny::div(class = "mb-3", shiny::uiOutput(ns("dataset_overview"))),

      shiny::h5(shiny::icon("hashtag"), " Numeric Variables",
        class = "text-primary mt-3"),
      DT::dataTableOutput(ns("numeric_summary")),

      shiny::h5(shiny::icon("tags"), " Categorical Variables",
        class = "text-success mt-4"),
      DT::dataTableOutput(ns("categorical_summary")),

      shiny::h5(shiny::icon("exclamation-circle"), " Missing Values",
        class = "text-warning mt-4"),
      DT::dataTableOutput(ns("missing_summary"))
    )
  )
}


#' Summary Panel Module – Server
#'
#' Computes and renders descriptive statistics for numeric and categorical
#' variables, plus a missing-value summary table.
#'
#' @param id Character string. The Shiny module namespace identifier.
#' @param loaded_data A [shiny::reactiveVal()] containing the current
#'   `data.frame`.
#'
#' @return `NULL` (invisibly).  Called for side effects.
#'
#' @seealso [summary_panel_ui()]
#'
#' @export
summary_panel_server <- function(id, loaded_data) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns

    summary_results <- shiny::reactiveValues(numeric = NULL, categorical = NULL)

    # Update variable choices -------------------------------------------
    shiny::observeEvent(loaded_data(), {
      df <- loaded_data()
      shiny::req(df)
      shiny::updateSelectizeInput(session, "summary_vars",
        choices = names(df), selected = NULL)
      shiny::updateSelectInput(session, "group_var",
        choices = c("None" = "", names(df)))
    })

    # Dataset overview cards --------------------------------------------
    output$dataset_overview <- shiny::renderUI({
      shiny::req(loaded_data())
      df            <- loaded_data()
      n_numeric     <- sum(vapply(df, is.numeric, logical(1)))
      n_character   <- sum(vapply(df,
        function(x) is.character(x) || is.factor(x), logical(1)))
      total_missing <- sum(is.na(df))
      total_cells   <- nrow(df) * ncol(df)
      missing_pct   <- round(total_missing / total_cells * 100, 2)

      shiny::div(
        class = "row g-2",
        lapply(
          list(
            list(val = format(nrow(df), big.mark = ","),
              lbl = "Observations", cls = "text-primary"),
            list(val = ncol(df), lbl = "Variables", cls = "text-info"),
            list(val = n_numeric, lbl = "Numeric", cls = "text-success"),
            list(val = n_character, lbl = "Character", cls = "text-warning"),
            list(val = paste0(missing_pct, "%"), lbl = "Missing",
              cls = "text-danger")
          ),
          function(x) {
            shiny::div(class = "col",
              shiny::div(class = "card bg-light",
                shiny::div(class = "card-body p-2 text-center",
                  shiny::h4(x$val, class = paste("mb-0", x$cls)),
                  shiny::tags$small(class = "text-muted", x$lbl)
                )
              )
            )
          }
        )
      )
    })

    # Compute summary on demand / on data load --------------------------
    compute <- function(df, vars) {
      summary_results$numeric     <- compute_numeric_summary(df, vars)
      summary_results$categorical <- compute_categorical_summary(df, vars)
    }

    shiny::observeEvent(input$compute_summary, {
      shiny::req(loaded_data())
      df   <- loaded_data()
      vars <- input$summary_vars
      if (is.null(vars) || length(vars) == 0L) vars <- names(df)
      group_var <- if (input$group_var == "") NULL else input$group_var
      shiny::withProgress(message = "Computing summary statistics...", {
        summary_results$numeric     <-
          compute_numeric_summary(df, vars, group_var)
        summary_results$categorical <-
          compute_categorical_summary(df, vars, group_var)
      })
    })

    shiny::observeEvent(loaded_data(), {
      shiny::req(loaded_data())
      compute(loaded_data(), names(loaded_data()))
    })

    # Numeric summary table ---------------------------------------------
    output$numeric_summary <- DT::renderDataTable({
      shiny::req(summary_results$numeric)
      DT::datatable(summary_results$numeric,
        options = list(pageLength = 20, scrollX = TRUE, dom = "ft",
          columnDefs = list(list(className = "dt-center", targets = "_all"))),
        rownames = FALSE,
        class    = "table-striped table-hover table-sm",
        selection = "none"
      ) |> DT::formatRound(c("Mean", "Median", "SD", "Min", "Max"), digits = 2)
    })

    # Categorical summary table -----------------------------------------
    output$categorical_summary <- DT::renderDataTable({
      shiny::req(summary_results$categorical)
      DT::datatable(summary_results$categorical,
        options = list(pageLength = 20, scrollX = TRUE, dom = "ft",
          columnDefs = list(list(className = "dt-center", targets = "_all"))),
        rownames  = FALSE,
        class     = "table-striped table-hover table-sm",
        selection = "none"
      )
    })

    # Missing value summary table ---------------------------------------
    output$missing_summary <- DT::renderDataTable({
      shiny::req(loaded_data())
      df <- loaded_data()
      missing_df <- data.frame(
        Variable    = names(df),
        Total       = nrow(df),
        Missing     = vapply(df, function(x) sum(is.na(x)), integer(1)),
        Non_Missing = vapply(df, function(x) sum(!is.na(x)), integer(1)),
        Missing_Pct = vapply(df,
          function(x) round(sum(is.na(x)) / length(x) * 100, 1), numeric(1)),
        stringsAsFactors = FALSE
      )
      missing_df <- missing_df[order(-missing_df$Missing_Pct), ]
      rownames(missing_df) <- NULL

      DT::datatable(missing_df,
        options = list(pageLength = 50, scrollX = TRUE, dom = "ft",
          columnDefs = list(list(className = "dt-center", targets = "_all"))),
        rownames  = FALSE,
        class     = "table-striped table-hover table-sm",
        selection = "none"
      ) |>
        DT::formatStyle("Missing_Pct",
          background         = DT::styleColorBar(c(0, 100), "#ffc107"),
          backgroundSize     = "100% 90%",
          backgroundRepeat   = "no-repeat",
          backgroundPosition = "center"
        )
    })

    # Download summary --------------------------------------------------
    output$download_summary <- shiny::downloadHandler(
      filename = function() paste0("summary_statistics_", Sys.Date(), ".csv"),
      content  = function(file) {
        results <- list()
        if (!is.null(summary_results$numeric))
          results[["numeric"]] <- summary_results$numeric
        if (!is.null(summary_results$categorical))
          results[["categorical"]] <- summary_results$categorical
        if (length(results) > 0L) {
          combined <- dplyr::bind_rows(results, .id = "Type")
          readr::write_csv(combined, file)
        }
      }
    )

    invisible(NULL)
  })
}
