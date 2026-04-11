# dataexplorer – embedded Shiny application
# This file is run by shiny::runApp() via dataexplorer::run_app().
# All helper functions are provided by the dataexplorer package, which is
# guaranteed to be on the search path when run_app() is called.

library(shiny)
library(bslib)
library(DT)
library(dataexplorer)

# ── UI ─────────────────────────────────────────────────────────────────────────

ui <- bslib::page_fluid(
  theme = bslib::bs_theme(
    version      = 5,
    bootswatch   = "flatly",
    primary      = "#0d47a1",
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
      h4(icon("chart-bar"), " Data Explorer"),
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

  dataset_browser_server("browser", selected_dataset, loaded_data)
  filtered_data <- data_viewer_server("viewer", loaded_data, selected_dataset)
  summary_panel_server("summary", loaded_data)
  converter_server("converter", loaded_data, selected_dataset)
}

# ── Launch ─────────────────────────────────────────────────────────────────────

shinyApp(ui = ui, server = server)
