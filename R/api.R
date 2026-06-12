#' Build an iTOL API upload request
#'
#' Validates generated datasets and prepares an `httr2` multipart request for
#' iTOL API upload workflows.
#'
#' @param project_name Name of the remote iTOL project.
#' @param dataset_paths Paths to generated dataset files.
#' @param api_token iTOL API token.
#' @param endpoint API endpoint.
#' @return An httr2 request object.
#' @export
itol_api_request <- function(project_name, dataset_paths, api_token, endpoint = "https://itol.embl.de/api") {
  if (!length(dataset_paths) || any(!file.exists(dataset_paths))) {
    cli::cli_abort("All dataset paths must exist before upload.")
  }
  body <- c(
    list(project = project_name),
    stats::setNames(lapply(dataset_paths, httr2::upload_file), paste0("dataset_", seq_along(dataset_paths)))
  )
  req <- httr2::request(endpoint) |>
    httr2::req_headers(Authorization = paste("Bearer", api_token))
  do.call(httr2::req_body_multipart, c(list(req), body))
}
