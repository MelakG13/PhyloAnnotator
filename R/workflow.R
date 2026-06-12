#' Run a PhyloAnnotator YAML workflow
#'
#' Main entry point for the PhyloAnnotator pipeline. Reads a YAML configuration file,
#' processes metadata and tree files, and generates iTOL annotation datasets with
#' validation reports and preview images.
#'
#' @param config Path to a YAML configuration file.
#' @param output_dir Directory for exported datasets and reports.
#' @return A list describing generated files:
#'   - datasets: paths to iTOL annotation files
#'   - validation: validation results object
#'   - previews: paths to preview images
#' @export
phylo_run <- function(config, output_dir = "phylo_annotate-output") {
  cfg <- yaml::read_yaml(config)
  cfg_dir <- dirname(normalizePath(config, mustWork = TRUE))
  tree <- resolve_path(cfg$tree, cfg_dir, must_work = TRUE)
  metadata_path <- resolve_path(cfg$metadata, cfg_dir, must_work = TRUE)
  id_col <- cfg$id_col %||% "Sample_ID"
  output_dir <- resolve_path(output_dir, getwd(), must_work = FALSE)

  metadata <- atlas_read_metadata(metadata_path, id_col = id_col)
  validation <- atlas_validate(metadata, tree = tree, id_col = id_col)
  annotations <- cfg$annotations %||% list()
  if (!length(annotations)) {
    cli::cli_abort("Configuration must contain at least one annotation.")
  }

  dataset_dir <- file.path(output_dir, "itol")
  dir.create(dataset_dir, recursive = TRUE, showWarnings = FALSE)
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
  invisible(list(datasets = files, validation = validation, previews = preview))
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

#' Simplified wrapper for phylo_run
#'
#' Convenience function that wraps phylo_run() with simpler parameters.
#' Processes tree file directly instead of through YAML configuration.
#'
#' @param tree Path to Newick format tree file.
#' @param metadata Path to metadata file (CSV, TSV, XLSX, ODS).
#' @param output_dir Output directory for results.
#' @param id_col Sample identifier column name.
#' @param annotations List of annotation specifications.
#'
#' @return A list with datasets, validation, and previews paths.
#' @export
phylo_annotate <- function(tree, metadata, output_dir = "phylo_annotate-output", 
                            id_col = "Sample_ID", annotations = NULL) {
  if (is.null(annotations)) {
    cli::cli_abort("At least one annotation must be specified.")
  }
  
  # Create temporary YAML config
  config_lines <- c(
    sprintf('tree: "%s"', tree),
    sprintf('metadata: "%s"', metadata),
    sprintf('id_col: "%s"', id_col),
    "annotations:"
  )
  
  for (i in seq_along(annotations)) {
    ann <- annotations[[i]]
    type <- ann$type %||% ""
    if (type == "") cli::cli_abort("Each annotation must have a type field.")
    
    config_lines <- c(config_lines, sprintf('  - type: %s', type))
    if (!is.null(ann$column)) {
      config_lines <- c(config_lines, sprintf('    column: %s', ann$column))
    }
    if (!is.null(ann$columns)) {
      config_lines <- c(config_lines, '    columns:')
      for (col in ann$columns) {
        config_lines <- c(config_lines, sprintf('      - %s', col))
      }
    }
    if (!is.null(ann$label)) {
      config_lines <- c(config_lines, sprintf('    label: "%s"', ann$label))
    }
  }
  
  # Write config to temp file
  config_file <- tempfile(fileext = ".yaml")
  writeLines(config_lines, config_file)
  
  # Run pipeline
  result <- phylo_run(config_file, output_dir)
  
  # Clean up
  unlink(config_file)
  
  result
}
