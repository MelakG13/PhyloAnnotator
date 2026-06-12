# Contributing to PhyloAnnotator

Thank you for helping improve PhyloAnnotator.

## Development workflow

1. Fork the repository and create a feature branch.
2. Install development dependencies with `pak::pak()` or `devtools::install_dev_deps()`.
3. Run `devtools::document()` after editing exported functions.
4. Run `devtools::test()` and aim to keep coverage above 90%.
5. Open a pull request with a concise description, test notes, and example output when relevant.

## Coding standards

PhyloAnnotator follows the tidyverse style guide. Prefer small, testable functions,
informative `cli` errors, vectorized data operations, and stable output formats.

## Reporting issues

Please include the package version, operating system, R version, input file type,
minimal metadata/tree examples, and the full error message.
