\docType{package}
\name{PhyloAnnotator-package}
\alias{PhyloAnnotator-package}
\alias{atlas_detect_types}
\alias{atlas_generate_examples}
\alias{atlas_palette}
\alias{atlas_preview}
\alias{atlas_read_metadata}
\alias{atlas_run}
\alias{atlas_validate}
\alias{itol_binary}
\alias{itol_barchart}
\alias{itol_boxplot}
\alias{itol_branch_color}
\alias{itol_branch_label}
\alias{itol_colorstrip}
\alias{itol_connections}
\alias{itol_gradient}
\alias{itol_heatmap}
\alias{itol_piechart}
\alias{itol_symbols}
\alias{itol_write}
\alias{itol_api_request}
\title{PhyloAnnotator: iTOL Annotation Workflows for Biological Metadata}
\description{
PhyloAnnotator imports biological metadata, validates it against phylogenetic
trees, detects field types, exports iTOL annotation datasets, and generates
local quality-control artifacts.
}
\section{Core workflow}{
Use \code{atlas_read_metadata()} to import metadata, \code{atlas_validate()} to
check metadata quality, and \code{atlas_run()} to execute a YAML-driven workflow.
}
\section{iTOL exporters}{
Exporter functions return character vectors that can be written with
\code{itol_write()}. Supported exporters include color strips, heatmaps, binary
datasets, bar charts, gradients, symbols, pie charts, boxplots, connections,
branch colors, and branch labels.
}
\examples{
\dontrun{
library(PhyloAnnotator)
atlas_generate_examples("example")
atlas_run("example/config.yaml", output_dir = "atlas-output")
}
}
