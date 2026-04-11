#' Dataset Browser Module – UI
#'
#' Renders the sidebar panel that lets users add/remove directory-based
#' libraries and select a dataset to load.
#'
#' @param id Character string. The Shiny module namespace identifier.
#'
#' @return A [shiny::tagList()] containing the sidebar UI elements.
#'
#' @seealso [dataset_browser_server()]
#'
#' @export
dataset_browser_ui <- function(id) {
  ns <- shiny::NS(id)

  shiny::tagList(
    # Add Library Button
    shiny::div(
      class = "d-flex align-items-center mb-3",
      shiny::actionButton(ns("add_library"), "Add Library",
        icon  = shiny::icon("folder-plus"),
        class = "btn-primary btn-sm w-100"
      )
    ),

    # Library Tree
    shiny::div(
      class = "library-tree",
      shiny::uiOutput(ns("library_tree"))
    ),

    # Dataset list for selected library
    shiny::hr(),
    shiny::h6("Datasets", class = "text-muted mb-2"),
    shiny::div(
      class = "dataset-list",
      style = "max-height: 400px; overflow-y: auto;",
      shiny::uiOutput(ns("dataset_list"))
    ),

    # Dataset info
    shiny::hr(),
    shiny::h6("Dataset Info", class = "text-muted mb-2"),
    shiny::uiOutput(ns("dataset_info"))
  )
}


#' Dataset Browser Module – Server
#'
#' Handles library registration, dataset listing, and dataset loading for the
#' sidebar browser panel.
#'
#' @param id Character string. The Shiny module namespace identifier.
#' @param selected_dataset A [shiny::reactiveVal()] that stores the full file
#'   path of the currently selected dataset.
#' @param loaded_data A [shiny::reactiveVal()] that stores the loaded
#'   `data.frame`.
#'
#' @return A list of reactive values: `libraries` (named list of
#'   library-path pairs) and `selected_library` (the currently active library
#'   name).
#'
#' @seealso [dataset_browser_ui()]
#'
#' @export
dataset_browser_server <- function(id, selected_dataset, loaded_data) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Internal helpers ---------------------------------------------------
    value_or_zero <- function(x) if (is.null(x)) 0L else x

    # Reactive state ----------------------------------------------------
    libraries                <- shiny::reactiveVal(list())
    selected_library         <- shiny::reactiveVal(NULL)
    dataset_index            <- shiny::reactiveVal(list())
    last_lib_select_clicks   <- shiny::reactiveVal(list())
    last_lib_remove_clicks   <- shiny::reactiveVal(list())
    last_dataset_load_clicks <- shiny::reactiveVal(list())

    # Add Library dialog ------------------------------------------------
    shiny::observeEvent(input$add_library, {
      shiny::showModal(shiny::modalDialog(
        title = "Add Library",
        shiny::textInput(ns("lib_name"), "Library Name (libref):",
          placeholder = "e.g., MYLIB"
        ),
        shiny::textInput(ns("lib_path"), "Directory Path:",
          value       = path.expand("~"),
          placeholder = "/path/to/datasets"
        ),
        footer = shiny::tagList(
          shiny::modalButton("Cancel"),
          shiny::actionButton(ns("confirm_add"), "Add", class = "btn-primary")
        )
      ))
    })

    shiny::observeEvent(input$confirm_add, {
      shiny::req(input$lib_name, input$lib_path)

      lib_name <- toupper(trimws(input$lib_name))
      lib_path <- trimws(input$lib_path)

      if (!nzchar(lib_name)) {
        shiny::showNotification("Library name cannot be empty.", type = "error")
        return()
      }
      if (!dir.exists(lib_path)) {
        shiny::showNotification("Directory does not exist.", type = "error")
        return()
      }

      current_libs <- libraries()
      current_libs[[lib_name]] <- lib_path
      libraries(current_libs)
      selected_library(lib_name)
      shiny::removeModal()
      shiny::showNotification(paste("Library", lib_name, "added."),
        type = "message")
    })

    # Library tree UI ---------------------------------------------------
    output$library_tree <- shiny::renderUI({
      libs <- libraries()
      if (length(libs) == 0) {
        return(shiny::div(
          class = "text-muted text-center p-3",
          shiny::icon("info-circle"), " No libraries added.",
          shiny::br(), "Click 'Add Library' to begin."
        ))
      }

      lib_buttons <- lapply(names(libs), function(lib_name) {
        is_selected <- identical(selected_library(), lib_name)
        n_datasets  <- nrow(list_datasets(libs[[lib_name]]))

        shiny::div(
          class = paste(
            "library-item p-2 mb-1 rounded cursor-pointer",
            if (is_selected) "bg-primary text-white" else "bg-light"
          ),
          style = "cursor: pointer;",
          shiny::actionLink(ns(paste0("select_lib_", lib_name)),
            label = shiny::tagList(
              shiny::icon("database"),
              shiny::strong(lib_name),
              shiny::span(class = "badge bg-secondary ms-2", n_datasets),
              shiny::br(),
              shiny::tags$small(
                class = if (is_selected) "text-white-50" else "text-muted",
                libs[[lib_name]]
              )
            )
          ),
          shiny::actionLink(ns(paste0("remove_lib_", lib_name)),
            label = shiny::icon("times"),
            class = "float-end text-danger",
            style = "position: absolute; right: 10px; top: 5px;"
          )
        )
      })

      shiny::tagList(lib_buttons)
    })

    # Dynamic library selection / removal observer ----------------------
    shiny::observe({
      libs      <- libraries()
      lib_names <- names(libs)

      prev_select <- last_lib_select_clicks()[lib_names]
      prev_remove <- last_lib_remove_clicks()[lib_names]

      for (lib_name in lib_names) {
        select_id <- paste0("select_lib_", lib_name)
        remove_id <- paste0("remove_lib_", lib_name)

        cur_sel  <- value_or_zero(input[[select_id]])
        cur_rem  <- value_or_zero(input[[remove_id]])
        prev_sel <- value_or_zero(prev_select[[lib_name]])
        prev_rem <- value_or_zero(prev_remove[[lib_name]])

        if (cur_sel > prev_sel) selected_library(lib_name)

        if (cur_rem > prev_rem) {
          cl <- libraries()
          cl[[lib_name]] <- NULL
          libraries(cl)
          if (identical(selected_library(), lib_name)) selected_library(NULL)
          shiny::showNotification(paste("Library", lib_name, "removed."),
            type = "warning")
        }

        prev_select[[lib_name]] <- cur_sel
        prev_remove[[lib_name]] <- cur_rem
      }

      last_lib_select_clicks(prev_select)
      last_lib_remove_clicks(prev_remove)
    })

    # Dataset list UI ---------------------------------------------------
    output$dataset_list <- shiny::renderUI({
      shiny::req(selected_library())
      lib_path <- libraries()[[selected_library()]]
      shiny::req(lib_path)

      datasets <- list_datasets(lib_path)

      if (nrow(datasets) == 0) {
        return(shiny::div(
          class = "text-muted text-center p-3",
          shiny::icon("exclamation-triangle"),
          " No supported datasets found."
        ))
      }

      dataset_items <- lapply(seq_len(nrow(datasets)), function(i) {
        ds          <- datasets[i, ]
        is_selected <- identical(selected_dataset(), ds$Path)

        format_icon <- switch(ds$Format,
          "SAS7BDAT" = shiny::icon("file-alt",    class = "text-info"),
          "XPT"      = shiny::icon("file-export", class = "text-warning"),
          "CSV"      = shiny::icon("file-csv",    class = "text-success"),
          "RDS"      = shiny::icon("file-code",   class = "text-primary"),
          shiny::icon("file")
        )

        shiny::div(
          class = paste(
            "dataset-item p-2 mb-1 rounded",
            if (is_selected) "border border-primary bg-light" else ""
          ),
          style = "cursor: pointer;",
          shiny::actionLink(ns(paste0("load_ds_", i)),
            label = shiny::tagList(
              format_icon, " ",
              shiny::strong(ds$Name),
              shiny::span(class = "badge bg-info ms-1", ds$Format),
              shiny::br(),
              shiny::tags$small(class = "text-muted",
                ds$Size, " | ", ds$Modified)
            )
          )
        )
      })

      ids <- paste0("load_ds_", seq_len(nrow(datasets)))
      dataset_index(stats::setNames(as.list(datasets$Path), ids))

      shiny::tagList(dataset_items)
    })

    # Dynamic dataset loading observer ----------------------------------
    shiny::observe({
      current_index <- dataset_index()
      if (length(current_index) == 0L) {
        last_dataset_load_clicks(list())
        return()
      }

      prev_load <- last_dataset_load_clicks()[names(current_index)]

      for (input_id in names(current_index)) {
        cur_clk  <- value_or_zero(input[[input_id]])
        prev_clk <- value_or_zero(prev_load[[input_id]])

        if (cur_clk > prev_clk) {
          filepath <- current_index[[input_id]]
          selected_dataset(filepath)

          tryCatch({
            shiny::showNotification("Loading dataset...",
              type = "message", duration = 2)
            df <- read_dataset(filepath)
            loaded_data(df)
            shiny::showNotification(
              paste("Loaded:", basename(filepath),
                "-", nrow(df), "obs,", ncol(df), "vars"),
              type = "message"
            )
          }, error = function(e) {
            shiny::showNotification(paste("Error:", e$message), type = "error")
            loaded_data(NULL)
          })
        }

        prev_load[[input_id]] <- cur_clk
      }

      last_dataset_load_clicks(prev_load)
    })

    # Dataset info panel ------------------------------------------------
    output$dataset_info <- shiny::renderUI({
      shiny::req(loaded_data(), selected_dataset())

      meta <- get_dataset_metadata(loaded_data(), selected_dataset())

      shiny::div(
        class = "small",
        shiny::tags$table(
          class = "table table-sm table-borderless mb-0",
          shiny::tags$tr(
            shiny::tags$td(class = "text-muted", "File:"),
            shiny::tags$td(meta$filename)),
          shiny::tags$tr(
            shiny::tags$td(class = "text-muted", "Format:"),
            shiny::tags$td(meta$format)),
          shiny::tags$tr(
            shiny::tags$td(class = "text-muted", "Obs:"),
            shiny::tags$td(format(meta$n_rows, big.mark = ","))),
          shiny::tags$tr(
            shiny::tags$td(class = "text-muted", "Vars:"),
            shiny::tags$td(meta$n_cols)),
          shiny::tags$tr(
            shiny::tags$td(class = "text-muted", "Size:"),
            shiny::tags$td(meta$file_size)),
          shiny::tags$tr(
            shiny::tags$td(class = "text-muted", "Modified:"),
            shiny::tags$td(substr(meta$modified, 1L, 16L)))
        )
      )
    })

    list(
      libraries        = libraries,
      selected_library = selected_library
    )
  })
}
