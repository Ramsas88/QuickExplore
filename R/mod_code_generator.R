#' Code Generator Module - UI
#'
#' Renders a panel displaying auto-generated R code that reproduces the
#' current QuickExplore session (load dataset -> filter/select -> summarise
#' -> export).  Users can copy the code to the clipboard or download it as
#' a `.R` script.
#'
#' @param id Character string. The Shiny module namespace identifier.
#'
#' @return A [shiny::tagList()] with the code generator UI.
#'
#' @seealso [code_generator_server()]
#'
#' @export
code_generator_ui <- function(id) {
  ns <- shiny::NS(id)

  shiny::tagList(
    shiny::div(
      class = "mt-2",

      # -- Toolbar -----------------------------------------------------
      shiny::fluidRow(
        shiny::column(7,
          shiny::h5(
            shiny::icon("code"), " Generated R Code",
            class = "mb-0"
          ),
          shiny::tags$small(
            class = "text-muted",
            "Reproduces your session: load \u2192 filter \u2192 summarise \u2192 export"
          )
        ),
        shiny::column(5,
          shiny::div(
            class = "text-end mt-1",
            shiny::actionButton(
              ns("copy_code"), "Copy",
              icon  = shiny::icon("copy"),
              class = "btn-outline-primary btn-sm"
            ),
            shiny::downloadButton(
              ns("download_code"), "Download .R",
              class = "btn-outline-secondary btn-sm ms-1"
            )
          )
        )
      ),

      shiny::hr(class = "my-2"),

      # -- Section toggles ----------------------------------------------
      shiny::div(
        class = "d-flex flex-wrap align-items-center gap-3 mb-2 mt-1",
        shiny::tags$strong("Sections:", class = "text-muted me-1"),
        shiny::div(class = "form-check form-check-inline",
          shiny::checkboxInput(ns("inc_load"),     "Load data",       value = TRUE)
        ),
        shiny::div(class = "form-check form-check-inline",
          shiny::checkboxInput(ns("inc_explore"),  "Filter / Select", value = TRUE)
        ),
        shiny::div(class = "form-check form-check-inline",
          shiny::checkboxInput(ns("inc_summary"),  "Summary stats",   value = TRUE)
        ),
        shiny::div(class = "form-check form-check-inline",
          shiny::checkboxInput(ns("inc_crosstab"), "Cross-tab",       value = TRUE)
        ),
        shiny::div(class = "form-check form-check-inline",
          shiny::checkboxInput(ns("inc_export"),   "Export",          value = TRUE)
        )
      ),

      # -- Code display -------------------------------------------------
      shiny::div(
        class = "code-generator-container",
        shiny::verbatimTextOutput(ns("generated_code"))
      ),

      # -- Copy toast notification --------------------------------------
      shiny::tags$div(
        id    = ns("copy_toast"),
        style = "display: none; position: fixed; bottom: 20px; right: 20px; z-index: 9999;",
        shiny::div(
          class = "alert alert-success py-2 px-3 shadow-sm mb-0",
          shiny::icon("check-circle"), " Code copied to clipboard!"
        )
      ),

      # -- JavaScript: clipboard copy -----------------------------------
      shiny::tags$script(shiny::HTML(sprintf("
        $(document).on('click', '#%s', function() {
          var codeEl = document.getElementById('%s');
          if (!codeEl) return;
          var text = codeEl.innerText || codeEl.textContent;
          if (navigator.clipboard && window.isSecureContext) {
            navigator.clipboard.writeText(text).then(function() {
              showCopyToast('%s');
            });
          } else {
            var ta = document.createElement('textarea');
            ta.value = text;
            ta.style.position = 'fixed';
            ta.style.opacity  = '0';
            document.body.appendChild(ta);
            ta.select();
            document.execCommand('copy');
            document.body.removeChild(ta);
            showCopyToast('%s');
          }
        });

        function showCopyToast(toastId) {
          var toast = document.getElementById(toastId);
          if (!toast) return;
          toast.style.display = 'block';
          setTimeout(function() { toast.style.display = 'none'; }, 2200);
        }
      ",
        ns("copy_code"),
        ns("generated_code"),
        ns("copy_toast"),
        ns("copy_toast")
      )))
    )
  )
}


#' Code Generator Module - Server
#'
#' Generates reproducible R code that mirrors the current QuickExplore session
#' and provides clipboard-copy (via JS) and download-as-`.R` handlers.
#'
#' @param id Character string. The Shiny module namespace identifier.
#' @param selected_dataset A [shiny::reactiveVal()] holding the file path of
#'   the active dataset, or `NULL` when none is loaded.
#' @param filter_expr A reactive expression returning the dplyr filter string
#'   typed in the Explore Data tab (may be `""` or `NULL`).
#' @param selected_vars A reactive expression returning a character vector of
#'   variable names chosen in the Explore Data tab (may be `NULL` / empty).
#' @param group_var A reactive expression returning the grouping variable name
#'   selected in the Summary panel (`""` means no grouping).
#' @param summary_vars A reactive expression returning variable names used for
#'   summary statistics (`NULL` / empty means all variables).
#' @param output_format A reactive expression returning the converter output
#'   format: `"csv"`, `"rds"`, `"xlsx"`, `"json"`, or `"xpt"`.
#' @param csv_delim A reactive returning the CSV delimiter character
#'   (default `","`).
#' @param json_pretty A reactive returning `TRUE` to pretty-print JSON.
#' @param crosstab_row A reactive returning the cross-tab row variable name
#'   (`""` = none selected).
#' @param crosstab_col A reactive returning the cross-tab column variable name
#'   (`""` = none selected).
#' @param crosstab_strat A reactive returning the stratification variable name
#'   (`""` = unstratified).
#'
#' @return `NULL` (invisibly).  Called for side effects.
#'
#' @seealso [code_generator_ui()]
#'
#' @export
#' @keywords internal
code_generator_server <- function(
  id,
  selected_dataset,
  filter_expr,
  selected_vars,
  group_var,
  summary_vars,
  output_format,
  csv_delim,
  json_pretty,
  crosstab_row   = shiny::reactive(""),
  crosstab_col   = shiny::reactive(""),
  crosstab_strat = shiny::reactive("")
) {
  shiny::moduleServer(id, function(input, output, session) {

    # -- Internal: build a dplyr pipe chain -----------------------------
    # steps: list of character vectors (each step may span multiple lines).
    # Appends " |>" after the last line of every step except the final one.
    build_pipe <- function(base, steps) {
      if (length(steps) == 0L) return(base)
      all_parts <- c(list(base), steps)
      out <- character(0)
      for (i in seq_along(all_parts)) {
        part <- all_parts[[i]]
        if (i < length(all_parts)) {
          part[length(part)] <- paste0(part[length(part)], " |>")
        }
        out <- c(out, part)
      }
      out
    }

    # -- Core code-generation function ----------------------------------
    generate_r_code <- function(
      filepath,
      filter_expr_val,
      selected_vars_val,
      group_var_val,
      summary_vars_val,
      output_format_val,
      csv_delim_val,
      json_pretty_val,
      crosstab_row_val,
      crosstab_col_val,
      crosstab_strat_val,
      inc_load, inc_explore, inc_summary, inc_crosstab, inc_export
    ) {

      # No dataset loaded yet
      if (is.null(filepath) || !nzchar(filepath)) {
        return(paste(
          "# \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500",
          "# QuickExplore \u2013 R Code Generator",
          "#",
          "# No dataset loaded.",
          "# Load a dataset in QuickExplore to generate reproducible R code.",
          "# \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500",
          sep = "\n"
        ))
      }

      ext     <- tolower(tools::file_ext(filepath))
      ds_name <- tools::file_path_sans_ext(base::basename(filepath))
      lines   <- character(0)
      df_name <- "df"   # current data-frame variable name in generated code

      # -- Header ------------------------------------------------------
      lines <- c(lines,
        "# ============================================================",
        "# QuickExplore \u2013 Generated R Script",
        paste0("# Dataset  : ", base::basename(filepath)),
        paste0("# Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
        "# ============================================================",
        ""
      )

      # -- Section 1: Load libraries ---------------------------------
      if (inc_load) {
        pkgs <- "library(dplyr)"
        if (ext %in% c("sas7bdat", "xpt")) pkgs <- c("library(haven)",  pkgs)
        if (ext == "csv")                   pkgs <- c("library(readr)",  pkgs)
        if (inc_export && !is.null(output_format_val)) {
          if (output_format_val == "xlsx" && !("library(writexl)" %in% pkgs))
            pkgs <- c(pkgs, "library(writexl)")
          if (output_format_val == "json" && !("library(jsonlite)" %in% pkgs))
            pkgs <- c(pkgs, "library(jsonlite)")
          if (output_format_val == "csv"  && !("library(readr)"   %in% pkgs))
            pkgs <- c(pkgs, "library(readr)")
        }
        lines <- c(lines,
          "# \u2500\u2500 1. Load libraries \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500",
          pkgs,
          ""
        )
      }

      # -- Section 2: Read dataset ----------------------------------
      if (inc_load) {
        read_call <- switch(ext,
          "sas7bdat" = paste0('df <- haven::read_sas("', filepath, '")'),
          "xpt"      = paste0('df <- haven::read_xpt("', filepath, '")'),
          "csv"      = paste0(
            'df <- readr::read_csv("', filepath, '", show_col_types = FALSE)'
          ),
          "rds"      = paste0('df <- readRDS("', filepath, '")'),
          paste0('df <- read.table("', filepath, '", header = TRUE)  # adjust as needed')
        )
        lines <- c(lines,
          "# \u2500\u2500 2. Load dataset \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500",
          read_call
        )

        # SAS blank-to-NA: add conversion step for SAS source files
        if (ext %in% c("sas7bdat", "xpt")) {
          lines <- c(lines,
            "",
            "# SAS blank\u2192NA: SAS stores missing character values as blank spaces.",
            "# Convert all-whitespace strings to NA for consistent missing-value handling.",
            "df <- as.data.frame(",
            "  lapply(df, function(x) {",
            "    if (is.character(x)) replace(x, trimws(x) == \"\", NA_character_) else x",
            "  }),",
            "  stringsAsFactors = FALSE, check.names = FALSE",
            ")"
          )
        }
        lines <- c(lines, "")
      }

      # -- Section 3: Filter / Select --------------------------------
      if (inc_explore) {
        has_filter <- !is.null(filter_expr_val) && nzchar(trimws(filter_expr_val))
        has_select <- !is.null(selected_vars_val) && length(selected_vars_val) > 0L

        lines <- c(lines,
          "# \u2500\u2500 3. Filter and select \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500"
        )

        if (has_filter || has_select) {
          steps <- list()
          if (has_filter) {
            lines <- c(lines, paste0("# Filter: ", filter_expr_val))
            steps <- c(steps, list(
              paste0("  dplyr::filter(", filter_expr_val, ")")
            ))
          }
          if (has_select) {
            vars_str <- paste(selected_vars_val, collapse = ", ")
            steps    <- c(steps, list(
              paste0("  dplyr::select(", vars_str, ")")
            ))
          }
          explore_lines       <- build_pipe(paste0("df_explore <- df"), steps)
          explore_lines[1L]   <- explore_lines[1L]   # keep assignment on first line
          lines   <- c(lines, explore_lines)
          df_name <- "df_explore"
        } else {
          lines <- c(lines, "# (No filters or variable selection applied)")
        }
        lines <- c(lines, "")
      }

      # -- Section 4: Summary statistics -----------------------------
      if (inc_summary) {
        has_group    <- !is.null(group_var_val)    && nzchar(group_var_val)
        has_sum_vars <- !is.null(summary_vars_val) && length(summary_vars_val) > 0L

        lines <- c(lines,
          "# \u2500\u2500 4. Summary statistics \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500"
        )
        if (has_group)
          lines <- c(lines, paste0("# Grouped by: ", group_var_val))
        lines <- c(lines, "")

        # Build shared select step (if summary_vars specified)
        select_step <- if (has_sum_vars) {
          vars_q <- paste(paste0('"', summary_vars_val, '"'), collapse = ", ")
          list(paste0("  dplyr::select(dplyr::any_of(c(", vars_q, ")))"))
        } else {
          list()
        }

        # -- Numeric summary --------------------------------------
        summarise_body <- c(
          "  dplyr::summarise(",
          "    dplyr::across(dplyr::where(is.numeric), list(",
          "      n      = \\(x) sum(!is.na(x)),",
          "      mean   = \\(x) round(mean(x, na.rm = TRUE), 2),",
          "      median = \\(x) round(median(x, na.rm = TRUE), 2),",
          "      sd     = \\(x) round(sd(x, na.rm = TRUE), 2),",
          "      min    = \\(x) round(min(x, na.rm = TRUE), 2),",
          "      max    = \\(x) round(max(x, na.rm = TRUE), 2)",
          if (has_group) "    ))," else "    ))",
          if (has_group) '    .groups = "drop"' else NULL,
          "  )"
        )
        summarise_body <- summarise_body[
          !vapply(summarise_body, is.null, logical(1))
        ]

        num_steps <- c(
          select_step,
          list(c("  dplyr::select(dplyr::where(is.numeric))")),
          if (has_group)
            list(paste0("  dplyr::group_by(", group_var_val, ")")) else list(),
          list(summarise_body)
        )
        num_lines <- c(
          "# Numeric summary",
          build_pipe(paste0(df_name), num_steps),
          ""
        )
        lines <- c(lines, num_lines)

        # -- Categorical frequency table ---------------------------
        cat_steps <- c(
          select_step,
          list(c("  dplyr::select(dplyr::where(\\(x) !is.numeric(x)))")),
          if (has_group)
            list(paste0("  dplyr::group_by(", group_var_val, ")")) else list(),
          list(c(
            "  dplyr::reframe(",
            "    dplyr::across(dplyr::everything(),",
            "      \\(x) as.data.frame(sort(table(x), decreasing = TRUE)))",
            "  )"
          ))
        )
        cat_lines <- c(
          "# Categorical frequencies",
          build_pipe(paste0(df_name), cat_steps),
          ""
        )
        lines <- c(lines, cat_lines)
      }

      # -- Section 4b: Cross-tabulation ----------------------------
      if (inc_crosstab) {
        has_ct_row <- !is.null(crosstab_row_val)   && nzchar(crosstab_row_val)   &&
                       crosstab_row_val   != "(select)"
        has_ct_col <- !is.null(crosstab_col_val)   && nzchar(crosstab_col_val)   &&
                       crosstab_col_val   != "(select)"

        lines <- c(lines,
          "# \u2500\u2500 4b. Cross-tabulation \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500"
        )

        if (has_ct_row && has_ct_col) {
          has_strat <- !is.null(crosstab_strat_val) && nzchar(crosstab_strat_val)
          rv    <- crosstab_row_val
          cv    <- crosstab_col_val
          strat <- crosstab_strat_val

          label <- if (has_strat)
            paste0("# ", rv, " \u00d7 ", cv, "  stratified by  ", strat)
          else
            paste0("# ", rv, " \u00d7 ", cv)

          lines <- c(lines, label, "")

          if (has_strat) {
            # Stratified: one table per stratum level using dplyr::count
            lines <- c(lines,
              "# Long-format counts (all strata combined)",
              paste0(df_name, " |>"),
              paste0("  dplyr::count(", strat, ", ", rv, ", ", cv, ', name = "N") |>'),
              "  dplyr::arrange(",
              paste0("    ", strat, ", ", rv, ", ", cv),
              "  )",
              "",
              "# Wide-format contingency table per stratum (base R)",
              paste0("strat_levels <- sort(unique(", df_name, "[[\"", strat, "\"]])"),
              "lapply(strat_levels, function(lv) {",
              paste0("  sub <- ", df_name, "[", df_name, "[[\"", strat, "\"]] == lv, ]"),
              paste0("  ct  <- table(sub[[\"", rv, "\"]], sub[[\"", cv, "\"]])"),
              paste0("  cat(\"\\n\", \"", strat, " =\", lv, \"\\n\")"),
              "  print(addmargins(ct))",
              "})"
            )
          } else {
            # Unstratified
            lines <- c(lines,
              "# Contingency table (base R)",
              paste0("ct <- with(", df_name, ", table(", rv, ", ", cv, "))"),
              "print(addmargins(ct))",
              "",
              "# As a data.frame",
              paste0(df_name, " |>"),
              paste0("  dplyr::count(", rv, ", ", cv, ', name = "N")'),
              "# Hint: use tidyr::pivot_wider() to reshape to wide format if needed"
            )
          }
          lines <- c(lines, "")
        } else {
          lines <- c(lines,
            "# (No cross-tabulation variables selected in Summary tab)",
            ""
          )
        }
      }

      # -- Section 5: Export ----------------------------------------
      if (inc_export && !is.null(output_format_val) && nzchar(output_format_val)) {
        outfile     <- paste0(ds_name, "_converted.", output_format_val)
        export_line <- switch(output_format_val,
          "csv" = {
            if (!is.null(csv_delim_val) && nzchar(csv_delim_val) &&
                csv_delim_val != ",") {
              paste0('readr::write_delim(', df_name, ', "', outfile,
                     '", delim = "', csv_delim_val, '")')
            } else {
              paste0('readr::write_csv(', df_name, ', "', outfile, '")')
            }
          },
          "rds"  = paste0('saveRDS(', df_name, ', "', outfile, '")'),
          "xlsx" = paste0(
            'writexl::write_xlsx(list(Data = as.data.frame(', df_name, ')), "',
            outfile, '")'
          ),
          "json" = {
            pretty_arg <- if (isTRUE(json_pretty_val)) "pretty = TRUE, " else ""
            paste0(
              'jsonlite::toJSON(', df_name, ', ', pretty_arg,
              'auto_unbox = TRUE) |>\n  writeLines("', outfile, '")'
            )
          },
          "xpt"  = paste0(
            'haven::write_xpt(', df_name, ', "', outfile, '", version = 5L)'
          )
        )
        lines <- c(lines,
          "# \u2500\u2500 5. Export dataset \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500",
          paste0("# Output: ", outfile),
          export_line,
          ""
        )
      }

      # Drop NULL entries and collapse
      lines <- lines[!vapply(lines, is.null, logical(1))]
      paste(lines, collapse = "\n")
    }   # end generate_r_code()

    # -- Reactive code string --------------------------------------------
    r_code <- shiny::reactive({
      # Safely retrieve each reactive (some may not exist until data is loaded)
      safe_get <- function(r, default = NULL) {
        tryCatch(r(), error = function(e) default)
      }

      generate_r_code(
        filepath            = safe_get(selected_dataset),
        filter_expr_val     = safe_get(filter_expr,    ""),
        selected_vars_val   = safe_get(selected_vars,  NULL),
        group_var_val       = safe_get(group_var,      ""),
        summary_vars_val    = safe_get(summary_vars,   NULL),
        output_format_val   = safe_get(output_format,  "csv"),
        csv_delim_val       = safe_get(csv_delim,      ","),
        json_pretty_val     = safe_get(json_pretty,    TRUE),
        crosstab_row_val    = safe_get(crosstab_row,   ""),
        crosstab_col_val    = safe_get(crosstab_col,   ""),
        crosstab_strat_val  = safe_get(crosstab_strat, ""),
        inc_load            = isTRUE(input$inc_load),
        inc_explore         = isTRUE(input$inc_explore),
        inc_summary         = isTRUE(input$inc_summary),
        inc_crosstab        = isTRUE(input$inc_crosstab),
        inc_export          = isTRUE(input$inc_export)
      )
    })

    # -- Render code -----------------------------------------------------
    output$generated_code <- shiny::renderText({
      r_code()
    })

    # -- Download handler ------------------------------------------------
    output$download_code <- shiny::downloadHandler(
      filename = function() {
        fp   <- tryCatch(selected_dataset(), error = function(e) NULL)
        base <- if (!is.null(fp) && nzchar(fp))
          tools::file_path_sans_ext(base::basename(fp))
        else
          "quickexplore_script"
        paste0(base, "_analysis_", Sys.Date(), ".R")
      },
      content = function(file) {
        writeLines(r_code(), file)
      }
    )

    invisible(NULL)
  })
}
