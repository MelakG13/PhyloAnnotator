test_that("iTOL exporters create valid headers and rows", {
  metadata <- data.frame(
    Sample_ID = c("tip1", "tip2"),
    Country = c("Kenya", "Uganda"),
    AMR_A = c(1, 0),
    AMR_B = c(0, 1),
    MIC = c(1.2, 2.5)
  )
  colorstrip <- itol_colorstrip(metadata, "Country")
  heatmap <- itol_heatmap(metadata, c("AMR_A", "AMR_B"))
  binary <- itol_binary(metadata, c("AMR_A", "AMR_B"))
  barchart <- itol_barchart(metadata, c("AMR_A", "AMR_B"))
  gradient <- itol_gradient(metadata, "MIC")
  branch_color <- itol_branch_color(metadata, "Country")

  expect_equal(colorstrip[[1]], "DATASET_COLORSTRIP")
  expect_true(any(grepl("^tip1\t#", colorstrip)))
  expect_equal(heatmap[[1]], "DATASET_HEATMAP")
  expect_equal(binary[[1]], "DATASET_BINARY")
  expect_equal(barchart[[1]], "DATASET_BARCHART")
  expect_equal(gradient[[1]], "DATASET_GRADIENT")
  expect_equal(branch_color[[1]], "DATASET_STYLE")
})

test_that("itol_write writes dataset files", {
  path <- tempfile(fileext = ".txt")
  itol_write(c("DATASET_COLORSTRIP", "DATA"), path)
  expect_true(file.exists(path))
})

test_that("iTOL exporters reject missing columns", {
  metadata <- data.frame(Sample_ID = c("tip1", "tip2"), Country = c("Kenya", "Uganda"))
  expect_error(itol_colorstrip(metadata, "Missing_Col"), "Missing required columns")
  expect_error(itol_heatmap(metadata, "Missing_Col"), "Missing required columns")
})
