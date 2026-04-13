# QuickExplore – embedded Shiny application
# This file is run by shiny::runApp() via QuickExplore::run_app().
# All helper functions are provided by the QuickExplore package, which is
# guaranteed to be on the search path when run_app() is called.

library(shiny)
library(bslib)
library(DT)
library(QuickExplore)

# ── UI ─────────────────────────────────────────────────────────────────────────

ui <- bslib::page_fluid(
  theme = bslib::bs_theme(
    version      = 5,
    bootswatch   = "flatly",
    primary      = "#556B2F",   # olive green
    "font-size-base" = "0.9rem"
  ),

  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "styles.css"),
    tags$style(HTML(".main-container { min-height: calc(100vh - 60px); }"))
  ),

  # Header
  div(
    class = "app-header",
    div(
      h4(icon("chart-bar"), " Quick Explorer"),
      span(class = "header-subtitle", "R Shiny | Dataset Browser & Analysis")
    ),
    div(
      span(class = "header-subtitle",
        icon("clock"), " ", textOutput("current_time", inline = TRUE)
      )
    )
  ),

  # Main layout
  div(
    class = "main-container",
    bslib::layout_sidebar(
      fillable = TRUE,

      sidebar = bslib::sidebar(
        width = 320,
        title = tagList(icon("folder-open"), " Libraries"),
        dataset_browser_ui("browser")
      ),

      bslib::navset_card_pill(
        id = "main_tabs",

        # ── Data tab ────────────────────────────────────────────────────
        bslib::nav_panel(
          title = tagList(icon("table"), " Data"),
          value = "data_tab",
          conditionalPanel(
            condition = "output.has_data === true",
            data_viewer_ui("viewer")
          ),
          conditionalPanel(
            condition = "output.has_data !== true",
            div(
              class = "empty-state",
              icon("database"),
              h4("No Dataset Loaded"),
              p("Add a library and select a dataset to begin exploring."),
              tags$ol(
                class = "text-start d-inline-block",
                style = "max-width: 400px;",
                tags$li("Click ", strong("Add Library"), " in the sidebar"),
                tags$li("Enter a name and directory path"),
                tags$li("Select a dataset from the list")
              )
            )
          )
        ),

        # ── Summary tab ─────────────────────────────────────────────────
        bslib::nav_panel(
          title = tagList(icon("chart-pie"), " Summary"),
          value = "summary_tab",
          conditionalPanel(
            condition = "output.has_data === true",
            summary_panel_ui("summary")
          ),
          conditionalPanel(
            condition = "output.has_data !== true",
            div(
              class = "empty-state",
              icon("calculator"),
              h4("No Data to Summarize"),
              p("Load a dataset first to view summary statistics.")
            )
          )
        ),

        # ── Convert tab ─────────────────────────────────────────────────
        bslib::nav_panel(
          title = tagList(icon("exchange-alt"), " Convert"),
          value = "convert_tab",
          conditionalPanel(
            condition = "output.has_data === true",
            converter_ui("converter")
          ),
          conditionalPanel(
            condition = "output.has_data !== true",
            div(
              class = "empty-state",
              icon("file-export"),
              h4("No Dataset to Convert"),
              p("Load a dataset first to convert it to another format.")
            )
          )
        ),

        # ── Code tab ────────────────────────────────────────────────────
        bslib::nav_panel(
          title = tagList(icon("code"), " Code"),
          value = "code_tab",
          conditionalPanel(
            condition = "output.has_data === true",
            code_generator_ui("codegen")
          ),
          conditionalPanel(
            condition = "output.has_data !== true",
            div(
              class = "empty-state",
              icon("scroll"),
              h4("No Code Yet"),
              p("Load a dataset to auto-generate reproducible R code for your session.")
            )
          )
        )
      )
    )
  )
)

# ── Server ─────────────────────────────────────────────────────────────────────

server <- function(input, output, session) {

  selected_dataset <- reactiveVal(NULL)
  loaded_data      <- reactiveVal(NULL)

  output$current_time <- renderText({
    invalidateLater(60000, session)
    format(Sys.time(), "%Y-%m-%d %H:%M")
  })

  output$has_data <- reactive({ !is.null(loaded_data()) })
  outputOptions(output, "has_data", suspendWhenHidden = FALSE)

  # ── Module wiring ──────────────────────────────────────────────────────
  dataset_browser_server("browser", selected_dataset, loaded_data)

  viewer_state   <- data_viewer_server("viewer",    loaded_data,  selected_dataset)
  summary_state  <- summary_panel_server("summary", loaded_data)
  converter_state <- converter_server("converter",  loaded_data,  selected_dataset)

  # ── Code generator ─────────────────────────────────────────────────────
  code_generator_server(
    id               = "codegen",
    selected_dataset = selected_dataset,
    filter_expr      = viewer_state$filter_expr,
    selected_vars    = viewer_state$selected_vars,
    group_var        = summary_state$group_var,
    summary_vars     = summary_state$summary_vars,
    output_format    = converter_state$output_format,
    csv_delim        = converter_state$csv_delim,
    json_pretty      = converter_state$json_pretty,
    crosstab_row     = summary_state$crosstab_row,
    crosstab_col     = summary_state$crosstab_col,
    crosstab_strat   = summary_state$crosstab_strat
  )
}

# ── Launch ─────────────────────────────────────────────────────────────────────

shinyApp(ui = ui, server = server)
