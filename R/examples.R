#' Generate bundled example data
#'
#' @param path Directory where example files should be written.
#' @param n Number of isolates.
#' @return Paths to generated files.
#' @export
atlas_generate_examples <- function(path = "example", n = 100) {
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  ids <- sprintf("ISO_%03d", seq_len(n))
  tree <- ape::rtree(n)
  tree$tip.label <- ids
  tree_path <- file.path(path, "tree.nwk")
  ape::write.tree(tree, tree_path)

  set.seed(42)
  metadata <- data.frame(
    Sample_ID = ids,
    Country = sample(c("Kenya", "Uganda", "Tanzania", "Rwanda", "Ethiopia"), n, TRUE),
    Collection_Date = as.character(as.Date("2020-01-01") + sample(0:1800, n, TRUE)),
    Host = sample(c("Human", "Cattle", "Poultry", "Environment"), n, TRUE),
    Species = sample(c("Escherichia coli", "Klebsiella pneumoniae", "Salmonella enterica"), n, TRUE),
    MLST = sample(paste0("ST", 1:40), n, TRUE),
    AMR_Gene_A = sample(0:1, n, TRUE),
    AMR_Gene_B = sample(0:1, n, TRUE),
    AMR_Gene_C = sample(0:1, n, TRUE),
    stringsAsFactors = FALSE
  )
  metadata_path <- file.path(path, "metadata.csv")
  readr::write_csv(metadata, metadata_path)

  config <- c(
    "tree: tree.nwk",
    "metadata: metadata.csv",
    "annotations:",
    "  - type: colorstrip",
    "    column: Country",
    "  - type: heatmap",
    "    columns:",
    "      - AMR_Gene_A",
    "      - AMR_Gene_B",
    "      - AMR_Gene_C"
  )
  config_path <- file.path(path, "config.yaml")
  writeLines(config, config_path)
  list(tree = tree_path, metadata = metadata_path, config = config_path)
}
