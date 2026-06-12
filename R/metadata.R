#' Read biological metadata
#'
#' Imports delimited metadata tables. XLSX, ODS, and Google Sheets CSV exports
#' are detected and reported with actionable guidance when optional readers are
#' unavailable.
#'
#' @param path Path to a metadata file.
#' @param id_col Sample identifier column.
#' @return A data frame with normalized character identifiers.
#' @export
atlas_read_metadata <- function(path, id_col = "Sample_ID") {
  is_url <- grepl("^https?://", path)
  if (!is_url && !file.exists(path)) {
    cli::cli_abort("Metadata file does not exist: {.path {path}}")
  }

  ext <- tolower(tools::file_ext(sub("\\?.*$", "", path)))
  data <- switch(
    ext,
    csv = readr::read_csv(path, show_col_types = FALSE, progress = FALSE),
    tsv = readr::read_tsv(path, show_col_types = FALSE, progress = FALSE),
    txt = readr::read_tsv(path, show_col_types = FALSE, progress = FALSE),
    xlsx = read_tabular_optional(path, "readxl", "read_excel"),
    ods = read_tabular_optional(path, "readODS", "read_ods"),
    cli::cli_abort("Unsupported metadata extension {.val {ext}}. Use CSV, TSV, TXT, XLSX, ODS, or Google Sheets CSV/TSV exports.")
  )

  data <- as.data.frame(data, stringsAsFactors = FALSE)
  if (!id_col %in% names(data)) {
    cli::cli_abort("Identifier column {.field {id_col}} was not found.")
  }
  data[[id_col]] <- trimws(as.character(data[[id_col]]))
  data
}

read_tabular_optional <- function(path, package, fun) {
  if (!requireNamespace(package, quietly = TRUE)) {
    cli::cli_abort(
      c(
        "Package {.pkg {package}} is required to read {.path {path}}.",
        "i" = "Install it or export the sheet as CSV/TSV."
      )
    )
  }
  getExportedValue(package, fun)(path)
}

#' Detect metadata column types
#'
#' @param metadata A data frame.
#' @param id_col Identifier column to ignore.
#' @return A named character vector with detected types.
#' @export
atlas_detect_types <- function(metadata, id_col = "Sample_ID") {
  stopifnot(is.data.frame(metadata))
  cols <- setdiff(names(metadata), id_col)
  stats::setNames(vapply(metadata[cols], detect_one_type, character(1)), cols)
}

detect_one_type <- function(x) {
  original_x <- x
  x <- x[!is.na(x) & trimws(as.character(x)) != ""]
  if (!length(x)) {
    return("empty")
  }

  lx <- tolower(as.character(x))
  if (all(lx %in% c("0", "1", "true", "false", "yes", "no", "present", "absent"))) {
    return("binary")
  }
  
  # Attempt numeric conversion
  num <- suppressWarnings(as.numeric(as.character(x)))
  na_prop <- sum(is.na(num)) / length(num)
  if (na_prop < 0.1 && length(unique(num[!is.na(num)])) > 2) {
    return("continuous")
  }
  
  # Attempt date conversion
  dates <- suppressWarnings(as.Date(as.character(x)))
  if (mean(!is.na(dates)) >= 0.8) {
    return("date")
  }
  
  "categorical"
}

#' Validate metadata against a tree
#'
#' @param metadata Metadata data frame.
#' @param tree Path to a Newick tree or an `ape::phylo` object.
#' @param id_col Identifier column.
#' @return A `phyloatlas_validation` object.
#' @export
atlas_validate <- function(metadata, tree = NULL, id_col = "Sample_ID") {
  if (!is.data.frame(metadata)) {
    cli::cli_abort("metadata must be a data frame")
  }
  if (nrow(metadata) == 0) {
    cli::cli_warn("metadata has 0 rows")
  }
  if (!id_col %in% names(metadata)) {
    cli::cli_abort("Identifier column {.field {id_col}} was not found.")
  }
  ids <- as.character(metadata[[id_col]])
  missing_ids <- which(is.na(ids) | trimws(ids) == "")
  duplicate_ids <- unique(ids[duplicated(ids) & !is.na(ids) & ids != ""])
  missing_by_col <- vapply(metadata, function(x) sum(is.na(x) | trimws(as.character(x)) == ""), integer(1))

  invalid_labels <- character()
  missing_metadata <- character()
  if (!is.null(tree)) {
    phy <- if (inherits(tree, "phylo")) tree else ape::read.tree(tree)
    tip_labels <- phy$tip.label
    invalid_labels <- setdiff(ids[!is.na(ids) & ids != ""], tip_labels)
    missing_metadata <- setdiff(tip_labels, ids[!is.na(ids) & ids != ""])
  }

  penalties <- length(missing_ids) * 2 + length(duplicate_ids) * 3 +
    length(invalid_labels) * 2 + length(missing_metadata) * 2 +
    sum(missing_by_col) / max(1, nrow(metadata))
  score <- max(0, round(100 - penalties, 1))

  out <- list(
    n_rows = nrow(metadata),
    n_columns = ncol(metadata),
    types = atlas_detect_types(metadata, id_col),
    missing_ids = missing_ids,
    duplicate_ids = duplicate_ids,
    invalid_labels = invalid_labels,
    missing_metadata = missing_metadata,
    missing_by_col = missing_by_col,
    score = score
  )
  class(out) <- "phyloatlas_validation"
  out
}

#' @export
print.phyloatlas_validation <- function(x, ...) {
  cli::cli_h1("PhyloAnnotator validation"
  cli::cli_li("Rows: {x$n_rows}")
  cli::cli_li("Columns: {x$n_columns}")
  cli::cli_li("Quality score: {x$score}/100")
  cli::cli_li("Duplicate IDs: {length(x$duplicate_ids)}")
  cli::cli_li("Invalid tree labels: {length(x$invalid_labels)}")
  invisible(x)
}

#' Generate color palettes
#'
#' @param values Values to map.
#' @param option Viridis option for continuous scales.
#' @param na_color Color to assign to NA values. If NULL, NAs are omitted.
#' @return A named vector of colors.
#' @export
atlas_palette <- function(values, option = "D", na_color = NULL) {
  has_na <- any(is.na(values))
  values <- unique(stats::na.omit(as.character(values)))
  if (!length(values)) {
    if (has_na && !is.null(na_color)) {
      return(stats::setNames(na_color, "NA"))
    }
    return(character())
  }
  cols <- viridis::viridis(length(values), option = option)
  pal <- stats::setNames(cols, values)
  if (has_na && !is.null(na_color)) {
    pal <- c(pal, stats::setNames(na_color, "NA"))
  }
  pal
}
