# PhyloAnnotator

[![R-CMD-check](https://github.com/phyloannotator/PhyloAnnotator/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/phyloannotator/PhyloAnnotator/actions)
[![Codecov](https://codecov.io/gh/phyloannotator/PhyloAnnotator/branch/main/graph/badge.svg)](https://codecov.io/gh/phyloannotator/PhyloAnnotator)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

**A modern framework for transforming biological metadata into publication-ready iTOL annotations and interactive phylogenetic visualizations.**

PhyloAnnotator turns isolate metadata, Newick trees, and reproducible YAML
workflows into iTOL annotation files, QC reports, color maps, and local preview
figures. It is inspired by the practical needs served by table2itol, but the
implementation is redesigned from scratch around testable R functions,
configuration-driven workflows, and modern package engineering.

## Key Features

* Import CSV, TSV, TXT, XLSX, and ODS metadata tables.
* Detect categorical, continuous, date, binary, and empty metadata fields.
* Validate duplicate IDs, missing IDs, missing metadata, and labels not present in the tree.
* Export color strips, heatmaps, binary datasets, gradients, symbols, pie charts, boxplots, and connections.
* Export bar charts, branch coloring, and branch labels for common iTOL styling workflows.
* Build multiple annotation layers from a single YAML configuration.
* Generate colorblind-friendly palettes, local previews, QC reports, validation JSON, and color mapping tables.
* Provide a clean R API for package users and a scriptable workflow for command-line execution.

## Installation

```r
install.packages("devtools")
devtools::install_github("phyloannotator/PhyloAnnotator")
```

For local development:

```r
devtools::load_all()
devtools::test()
devtools::document()
```

## Quick Start

```r
library(PhyloAnnotator)

atlas_generate_examples("example")
atlas_run("example/config.yaml", output_dir = "atlas-output")
```

## YAML Workflow

```yaml
tree: tree.nwk
metadata: metadata.csv
id_col: Sample_ID
annotations:
  - type: colorstrip
    column: Country
  - type: heatmap
    columns:
      - AMR_Gene_A
      - AMR_Gene_B
      - AMR_Gene_C
  - type: gradient
    column: MIC
```

Command line usage from a source checkout:

```sh
Rscript inst/cli/phyloatlasr.R run example/config.yaml --output atlas-output
```

Installed executable:

```sh
phyloforger run config.yaml
```

## R API Examples

```r
metadata <- atlas_read_metadata("example/metadata.csv")
types <- atlas_detect_types(metadata)
validation <- atlas_validate(metadata, "example/tree.nwk")

dataset <- itol_colorstrip(metadata, column = "Country")
itol_write(dataset, "atlas-output/itol/country.txt")
```

## Validation Example

```r
validation <- atlas_validate(metadata, tree = "example/tree.nwk")
print(validation)
```

Validation reports include:

* duplicate sample IDs
* missing sample IDs
* metadata rows not found in the tree
* tree tips without metadata
* per-column missingness
* metadata quality score

## Supported iTOL Datasets

| Dataset | Function | Status |
| --- | --- | --- |
| Color strip | `itol_colorstrip()` | Implemented |
| Heatmap | `itol_heatmap()` | Implemented |
| Binary | `itol_binary()` | Implemented |
| Bar chart | `itol_barchart()` | Implemented |
| Gradient | `itol_gradient()` | Implemented |
| Symbols | `itol_symbols()` | Implemented |
| Pie chart | `itol_piechart()` | Implemented |
| Boxplot | `itol_boxplot()` | Implemented |
| Connections | `itol_connections()` | Implemented |
| Branch coloring | `itol_branch_color()` | Implemented |
| Branch labeling | `itol_branch_label()` | Implemented |

## Screenshots

Preview images are generated into `atlas-output/previews/`.

![Preview placeholder](man/figures/preview-placeholder.svg)

## Test Dataset

The example dataset contains a 100-isolate bacterial phylogeny, metadata with
country/date/host/species/MLST fields, and three AMR gene columns. Validation
fixtures cover missing IDs, duplicate IDs, invalid labels, missing metadata, and
mixed data types.

## Architecture

```mermaid
flowchart LR
  A["Metadata files"] --> B["atlas_read_metadata"]
  C["Newick tree"] --> D["atlas_validate"]
  B --> E["atlas_detect_types"]
  B --> D
  B --> F["iTOL exporters"]
  E --> F
  D --> G["QC reports"]
  F --> H["Dataset files"]
  F --> I["Preview images"]
  J["YAML config"] --> K["atlas_run"]
  K --> B
  K --> F
  K --> G
```

## Roadmap

* Harden branch coloring and branch labeling exports.
* Add direct iTOL upload execution once API authentication patterns are finalized.
* Add parallelized chunked exporters for metadata tables above 100,000 rows.
* Add richer ggtree-backed previews and pkgdown articles.
* Publish benchmark reports for large bacterial surveillance datasets.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Contributions should include focused
tests, roxygen2 documentation, and example output for new dataset formats.

## Citation

If you use PhyloAnnotator, please cite the repository and the iTOL platform used
for final tree rendering. A formal citation file will be added before the first
archival release.

## License

MIT. See [LICENSE](LICENSE).

## Acknowledgments

PhyloAnnotator acknowledges the iTOL ecosystem and the bioinformatics community
that has shaped practical metadata-to-tree annotation workflows.
