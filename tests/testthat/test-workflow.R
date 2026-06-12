test_that("workflow annotation builder supports core dataset types", {
  metadata <- data.frame(
    Sample_ID = c("tip1", "tip2"),
    Country = c("Kenya", "Uganda"),
    AMR_Gene_A = c(1, 0),
    AMR_Gene_B = c(0, 1),
    AMR_Gene_C = c(1, 1)
  )
  ann <- list(type = "heatmap", columns = c("AMR_Gene_A", "AMR_Gene_B", "AMR_Gene_C"))
  dataset <- build_annotation(metadata, ann, "Sample_ID")
  expect_equal(dataset[[1]], "DATASET_HEATMAP")
})

test_that("build_annotation rejects invalid types", {
  metadata <- data.frame(Sample_ID = c("tip1", "tip2"))
  ann <- list(type = "invalid_type")
  expect_error(build_annotation(metadata, ann, "Sample_ID"), "Unsupported annotation type")
})

test_that("build_annotation rejects missing type", {
  metadata <- data.frame(Sample_ID = c("tip1", "tip2"))
  ann <- list()
  expect_error(build_annotation(metadata, ann, "Sample_ID"), "Annotation type not specified")
})

test_that("atlas_palette handles NA values with na_color", {
  values <- c("A", "B", "A", NA, "B")
  pal <- atlas_palette(values, na_color = "#CCCCCC")
  expect_true("NA" %in% names(pal))
  expect_equal(pal["NA"], "#CCCCCC")
})

test_that("atlas_palette handles all-NA input", {
  values <- c(NA, NA, NA)
  pal_without_na <- atlas_palette(values)
  expect_length(pal_without_na, 0)
  pal_with_na <- atlas_palette(values, na_color = "#CCCCCC")
  expect_length(pal_with_na, 1)
  expect_equal(pal_with_na["NA"], "#CCCCCC")
})
