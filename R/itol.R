itol_header <- function(dataset, label, extra = character()) {
  c(
    paste0("DATASET_", dataset),
    "SEPARATOR TAB",
    paste0("DATASET_LABEL\t", label),
    extra,
    "DATA"
  )
}

#' Write an iTOL dataset
#'
#' @param dataset Character vector containing an iTOL dataset.
#' @param path Output path.
#' @return The output path, invisibly.
#' @export
itol_write <- function(dataset, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  writeLines(dataset, path, useBytes = TRUE)
  invisible(path)
}

#' Create an iTOL color strip dataset
#' @param metadata Metadata data frame.
#' @param column Column to map.
#' @param id_col Identifier column.
#' @param label Dataset label.
#' @export
itol_colorstrip <- function(metadata, column, id_col = "Sample_ID", label = column) {
  require_columns(metadata, c(id_col, column))
  pal <- atlas_palette(metadata[[column]])
  rows <- sprintf("%s\t%s\t%s", metadata[[id_col]], pal[as.character(metadata[[column]])], metadata[[column]])
  c(itol_header("COLORSTRIP", label), rows)
}

#' Create an iTOL heatmap dataset
#' @param metadata Metadata data frame.
#' @param columns Numeric columns to export.
#' @param id_col Identifier column.
#' @param label Dataset label.
#' @export
itol_heatmap <- function(metadata, columns, id_col = "Sample_ID", label = "Heatmap") {
  require_columns(metadata, c(id_col, columns))
  header <- itol_header("HEATMAP", label, paste0("FIELD_LABELS\t", paste(columns, collapse = "\t")))
  values <- apply(metadata[columns], 2, as.numeric)
  rows <- apply(cbind(metadata[[id_col]], values), 1, paste, collapse = "\t")
  c(header, rows)
}

#' Create an iTOL binary dataset
#' @param metadata Metadata data frame.
#' @param columns Binary columns to export.
#' @param id_col Identifier column.
#' @param label Dataset label.
#' @export
itol_binary <- function(metadata, columns, id_col = "Sample_ID", label = "Binary") {
  require_columns(metadata, c(id_col, columns))
  vals <- lapply(metadata[columns], normalize_binary)
  rows <- apply(cbind(metadata[[id_col]], as.data.frame(vals)), 1, paste, collapse = "\t")
  c(itol_header("BINARY", label, paste0("FIELD_LABELS\t", paste(columns, collapse = "\t"))), rows)
}

#' Create an iTOL bar chart dataset
#' @param metadata Metadata data frame.
#' @param columns Numeric value columns.
#' @param id_col Identifier column.
#' @param label Dataset label.
#' @export
itol_barchart <- function(metadata, columns, id_col = "Sample_ID", label = "Bar chart") {
  require_columns(metadata, c(id_col, columns))
  rows <- apply(cbind(metadata[[id_col]], metadata[columns]), 1, paste, collapse = "\t")
  c(itol_header("BARCHART", label, paste0("FIELD_LABELS\t", paste(columns, collapse = "\t"))), rows)
}

#' Create an iTOL gradient dataset
#' @param metadata Metadata data frame.
#' @param column Numeric column.
#' @param id_col Identifier column.
#' @param label Dataset label.
#' @export
itol_gradient <- function(metadata, column, id_col = "Sample_ID", label = column) {
  require_columns(metadata, c(id_col, column))
  rows <- sprintf("%s\t%s", metadata[[id_col]], as.numeric(metadata[[column]]))
  c(itol_header("GRADIENT", label), rows)
}

#' Create an iTOL symbols dataset
#' @param metadata Metadata data frame.
#' @param column Column controlling symbol color.
#' @param id_col Identifier column.
#' @param label Dataset label.
#' @export
itol_symbols <- function(metadata, column, id_col = "Sample_ID", label = column) {
  require_columns(metadata, c(id_col, column))
  pal <- atlas_palette(metadata[[column]])
  rows <- sprintf("%s\t2\t10\t%s\t1\t%s", metadata[[id_col]], pal[as.character(metadata[[column]])], metadata[[column]])
  c(itol_header("SYMBOL", label), rows)
}

#' Create an iTOL pie chart dataset
#' @param metadata Metadata data frame.
#' @param columns Numeric slice columns.
#' @param id_col Identifier column.
#' @param label Dataset label.
#' @export
itol_piechart <- function(metadata, columns, id_col = "Sample_ID", label = "Pie chart") {
  require_columns(metadata, c(id_col, columns))
  rows <- apply(cbind(metadata[[id_col]], metadata[columns]), 1, paste, collapse = "\t")
  c(itol_header("PIECHART", label, paste0("FIELD_LABELS\t", paste(columns, collapse = "\t"))), rows)
}

#' Create an iTOL boxplot dataset
#' @param metadata Metadata data frame.
#' @param columns Numeric value columns.
#' @param id_col Identifier column.
#' @param label Dataset label.
#' @export
itol_boxplot <- function(metadata, columns, id_col = "Sample_ID", label = "Boxplot") {
  require_columns(metadata, c(id_col, columns))
  rows <- apply(cbind(metadata[[id_col]], metadata[columns]), 1, paste, collapse = "\t")
  c(itol_header("BOXPLOT", label), rows)
}

#' Create an iTOL connections dataset
#' @param from Source labels.
#' @param to Target labels.
#' @param label Dataset label.
#' @param color Connection color.
#' @export
itol_connections <- function(from, to, label = "Connections", color = "#666666") {
  rows <- sprintf("%s\t%s\t%s\tnormal\t1", from, to, color)
  c(itol_header("CONNECTION", label), rows)
}

#' Create an iTOL branch color dataset
#' @param metadata Metadata data frame.
#' @param column Column controlling branch color.
#' @param id_col Identifier column.
#' @param label Dataset label.
#' @export
itol_branch_color <- function(metadata, column, id_col = "Sample_ID", label = column) {
  require_columns(metadata, c(id_col, column))
  pal <- atlas_palette(metadata[[column]])
  rows <- sprintf("%s\tbranch\t%s\tnormal\t2", metadata[[id_col]], pal[as.character(metadata[[column]])])
  c(itol_header("STYLE", paste0(label, " branch colors")), rows)
}

#' Create an iTOL branch label dataset
#' @param metadata Metadata data frame.
#' @param column Column to display as branch labels.
#' @param id_col Identifier column.
#' @param label Dataset label.
#' @export
itol_branch_label <- function(metadata, column, id_col = "Sample_ID", label = column) {
  require_columns(metadata, c(id_col, column))
  rows <- sprintf("%s\tlabel\t%s", metadata[[id_col]], metadata[[column]])
  c(itol_header("TEXT", paste0(label, " branch labels")), rows)
}

require_columns <- function(data, cols) {
  missing <- setdiff(cols, names(data))
  if (length(missing)) {
    cli::cli_abort("Missing required columns: {.field {missing}}")
  }
}

normalize_binary <- function(x) {
  x <- tolower(as.character(x))
  ifelse(x %in% c("1", "true", "yes", "present"), 1, 0)
}
