test_that("atlas_validate reports duplicates and missing ids", {
  metadata <- data.frame(
    Sample_ID = c("tip1", "tip1", "", NA),
    Country = c("Kenya", NA, "Uganda", "Rwanda")
  )
  validation <- atlas_validate(metadata)
  expect_s3_class(validation, "phyloatlas_validation")
  expect_equal(validation$duplicate_ids, "tip1")
  expect_equal(length(validation$missing_ids), 2)
  expect_lt(validation$score, 100)
})

test_that("atlas_validate checks tree labels", {
  tree <- ape::read.tree(text = "(tip1:0.1,tip2:0.2,tip3:0.3);")
  metadata <- data.frame(Sample_ID = c("tip1", "extra"), Country = c("Kenya", "Uganda"))
  validation <- atlas_validate(metadata, tree = tree)
  expect_equal(validation$invalid_labels, "extra")
  expect_equal(setdiff(c("tip2", "tip3"), validation$missing_metadata), character())
})

test_that("atlas_validate rejects non-data.frame input", {
  expect_error(atlas_validate(list()), "metadata must be a data frame")
})

test_that("atlas_validate handles empty metadata", {
  metadata <- data.frame(Sample_ID = character())
  expect_warning(atlas_validate(metadata), "metadata has 0 rows")
})
