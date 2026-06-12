test_that("atlas_detect_types classifies common metadata columns", {
  metadata <- data.frame(
    Sample_ID = c("a", "b", "c"),
    Country = c("Kenya", "Uganda", "Kenya"),
    Collection_Date = c("2024-01-01", "2024-01-02", "2024-01-03"),
    MIC = c("1.2", "2.4", "3.1"),
    AMR = c(1, 0, 1)
  )
  types <- atlas_detect_types(metadata)
  expect_equal(types[["Country"]], "categorical")
  expect_equal(types[["Collection_Date"]], "date")
  expect_equal(types[["MIC"]], "continuous")
  expect_equal(types[["AMR"]], "binary")
})

test_that("atlas_detect_types handles all-NA columns", {
  metadata <- data.frame(
    Sample_ID = c("a", "b", "c"),
    Empty_Col = c(NA, NA, NA)
  )
  types <- atlas_detect_types(metadata)
  expect_equal(types[["Empty_Col"]], "empty")
})

test_that("atlas_detect_types handles mixed NA numeric columns", {
  metadata <- data.frame(
    Sample_ID = c("a", "b", "c", "d", "e"),
    Mixed = c("1.2", "2.4", NA, "3.1", "4.5")
  )
  types <- atlas_detect_types(metadata)
  expect_equal(types[["Mixed"]], "continuous")
})
