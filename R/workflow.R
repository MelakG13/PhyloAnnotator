#' Run a PhyloAnnotator YAML workflow
#'
#' @param config Path to a YAML configuration file.
#' @param output_dir Directory for exported datasets and reports.
#' @return A list describing generated files.
#' @export
atlas_run <- function(config, output_dir = "phyloatlas-output") {
  cfg <- yaml::read_yaml(config)
  cfg_dir <- dirname(normalizePath(config, mustWork = TRUE))
  tree <- resolve_path(cfg$tree, cfg_dir)
  metadata_path <- resolve_path(cfg$metadata, cfg_dir)
  id_col <- cfg$id_col %||% "Sample_ID"
  output_dir <- resolve_path(output_dir, getwd(), must_work = FALSE)

  metadata <- atlas_read_metadata(metadata_path, id_col = id_col)
  validation <- atlas_validate(metadata, tree = tree, id_col = id_col)
  annotations <- cfg$annotations %||% list()
  if (!length(annotations)) {
    cli::cli_abort("Configuration must contain at least one annotation.")
  }

  dataset_dir <- file.path(output_dir, "itol")
  files <- character()
  for (i in seq_along(annotations)) {
    ann <- annotations[[i]]
    dataset <- build_annotation(metadata, ann, id_col)
    name <- ann$name %||% sprintf("%02d_%s", i, ann$type)
    path <- file.path(dataset_dir, paste0(sanitize_file(name), ".txt"))
    itol_write(dataset, path)
    files <- c(files, path)
  }

  report_dir <- file.path(output_dir, "reports")
  dir.create(report_dir, recursive = TRUE, showWarnings = FALSE)
  write_validation_report(validation, file.path(report_dir, "metadata_validation.json"))
  write_qc_report(validation, file.path(report_dir, "qc_report.md"))
  write_color_tables(metadata, annotations, id_col, file.path(output_dir, "color-maps"))

  preview <- atlas_preview(metadata, annotations, id_col = id_col, output_dir = file.path(output_dir, "previews"))

  cli::cli_alert_success("Generated {length(files)} iTOL dataset{?s} in {.path {dataset_dir}}")
  list(datasets = files, validation = validation, previews = preview)
}

build_annotation <- function(metadata, ann, id_col) {
  if (is.null(ann) || !is.list(ann)) {
    cli::cli_abort("Annotation must be a non-null list")
  }
  type <- tolower(ann$type %||% "")
  if (type == "") {
    cli::cli_abort("Annotation type not specified")
  }
  switch(
    type,
    colorstrip = itol_colorstrip(metadata, ann$column, id_col, ann$label %||% ann$column),
    heatmap = itol_heatmap(metadata, unlist(ann$columns), id_col, ann$label %||% "Heatmap"),
    binary = itol_binary(metadata, unlist(ann$columns), id_col, ann$label %||% "Binary"),
    barchart = itol_barchart(metadata, unlist(ann$columns), id_col, ann$label %||% "Bar chart"),
    gradient = itol_gradient(metadata, ann$column, id_col, ann$label %||% ann$column),
    symbols = itol_symbols(metadata, ann$column, id_col, ann$label %||% ann$column),
    piechart = itol_piechart(metadata, unlist(ann$columns), id_col, ann$label %||% "Pie chart"),
    boxplot = itol_boxplot(metadata, unlist(ann$columns), id_col, ann$label %||% "Boxplot"),
    branch_color = itol_branch_color(metadata, ann$column, id_col, ann$label %||% ann$column),
    branch_label = itol_branch_label(metadata, ann$column, id_col, ann$label %||% ann$column),
    cli::cli_abort("Unsupported annotation type {.val {type}}.")
  )
}

#' Generate local annotation previews
#'
#' @param metadata Metadata data frame.
#' @param annotations Annotation list from a workflow config.
#' @param id_col Identifier column.
#' @param output_dir Preview output directory.
#' @return Paths to preview images.
#' @export
atlas_preview <- function(metadata, annotations, id_col = "Sample_ID", output_dir = "previews") {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  paths <- character()
  for (i in seq_along(annotations)) {
    ann <- annotations[[i]]
    type <- tolower(ann$type %||% "")
    column <- ann$column %||% unlist(ann$columns)[1]
    if (is.null(column)) {
      cli::cli_warn("Annotation {i} ({type}) has no valid column specified")
      next
    }
    if (!column %in% names(metadata)) {
      cli::cli_warn("Annotation {i} ({type}) column {.field {column}} not found in metadata")
      next
    }
    plot_data <- data.frame(tip_index = seq_len(nrow(metadata)), value = metadata[[column]])
    p <- ggplot2::ggplot(plot_data, ggplot2::aes(x = tip_index, y = value)) +
      ggplot2::geom_point(ggplot2::aes(color = value), size = 2) +
      ggplot2::theme_minimal(base_size = 11) +
      ggplot2::theme(axis.text.x = ggplot2::element_blank(), axis.ticks.x = ggplot2::element_blank()) +
      ggplot2::labs(x = "Tree tips", y = column, title = paste("Preview:", type))
    path <- file.path(output_dir, paste0(sprintf("%02d_", i), sanitize_file(type), ".png"))
    tryCatch(
      ggplot2::ggsave(path, p, width = 8, height = 4.5, dpi = 160),
      error = function(e) {
        cli::cli_warn("Failed to save preview for annotation {i}: {e$message}")
      }
    )
    if (file.exists(path)) {
      paths <- c(paths, path)
    }
  }
  paths
}

write_validation_report <- function(validation, path) {
  jsonlite::write_json(validation, path, pretty = TRUE, auto_unbox = TRUE)
}

write_qc_report <- function(validation, path) {
  lines <- c(
    "# PhyloAnnotator QC Report",
    "",
    paste0("* Rows: ", validation$n_rows),
    paste0("* Columns: ", validation$n_columns),
    paste0("* Quality score: ", validation$score, "/100"),
    paste0("* Duplicate IDs: ", length(validation$duplicate_ids)),
    paste0("* Missing IDs: ", length(validation$missing_ids)),
    paste0("* Invalid labels: ", length(validation$invalid_labels)),
    paste0("* Tree tips without metadata: ", length(validation$missing_metadata))
  )
  writeLines(lines, path)
}

write_color_tables <- function(metadata, annotations, id_col, output_dir) {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  for (ann in annotations) {
    if (!identical(tolower(ann$type %||% ""), "colorstrip")) {
      next
    }
    pal <- atlas_palette(metadata[[ann$column]])
    readr::write_csv(data.frame(value = names(pal), color = unname(pal)), file.path(output_dir, paste0(sanitize_file(ann$column), ".csv")))
  }
}

resolve_path <- function(path, base, must_work = TRUE) {
  if (is.null(path)) {
    cli::cli_abort("A required path is missing from the configuration.")
  }
  candidate <- if (grepl("^([A-Za-z]:|/|\\\\)", path)) path else file.path(base, path)
  normalizePath(candidate, mustWork = must_work)
}

sanitize_file <- function(x) {
  gsub("[^A-Za-z0-9_.-]+", "_", x)
}

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}
