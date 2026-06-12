#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)

usage <- function() {
  cat("Usage: Rscript inst/cli/phyloatlasr.R run config.yaml [--output DIR]\n")
  quit(status = 1)
}

if (length(args) < 2 || args[[1]] != "run") {
  usage()
}

config <- args[[2]]
output <- "phyloatlas-output"
if ("--output" %in% args) {
  idx <- match("--output", args)
  output <- args[[idx + 1]]
}

suppressPackageStartupMessages(library(PhyloAnnotator))
atlas_run(config, output_dir = output)
