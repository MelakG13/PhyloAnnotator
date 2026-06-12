#' Null-coalescing operator
#'
#' Returns the left-hand side if it is not NULL, otherwise returns the right-hand side.
#' Useful for providing default values.
#'
#' @param x Left-hand side value.
#' @param y Right-hand side default value.
#' @return x if not NULL, otherwise y.
#' @keywords internal
`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

#' Resolve file paths with optional existence checking
#'
#' @param path Input file path (relative or absolute).
#' @param base Base directory for relative paths.
#' @param must_work Whether to enforce file existence.
#' @return Normalized absolute path.
#' @keywords internal
resolve_path <- function(path, base, must_work = TRUE) {
  if (is.null(path)) {
    cli::cli_abort("A required path is missing from the configuration.")
  }
  candidate <- if (grepl("^([A-Za-z]:|/|\\\\)", path)) path else file.path(base, path)
  normalizePath(candidate, mustWork = must_work)
}

#' Sanitize file names for iTOL output
#'
#' Replaces special characters with underscores.
#'
#' @param x Character string to sanitize.
#' @return Sanitized file name safe for output.
#' @keywords internal
sanitize_file <- function(x) {
  gsub("[^A-Za-z0-9_.-]+", "_", x)
}
