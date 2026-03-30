# tests/testthat/test-col-select-export.R
# Tests for sim_export() col_select parameter

test_that("sim_export with col_select produces subset of columns", {
  skip_if_not_installed("arrow")

  tmp <- tempdir()
  out <- file.path(tmp, "col_select_test")
  unlink(out, recursive = TRUE)

  sim_reset()
  sim_export(
    output_dir = out,
    dataset = "rdw",
    year = 2023L,
    n = 100L,
    seed = 42L,
    col_select = list(
      RDWNPACT = c("BRANDSTCODECORVRTG")
    )
  )

  # Read the exported file
  pq <- arrow::read_parquet(
    file.path(out, "RDWNPACTTAB", "RDWNPACT2023TABV1.parquet"))

  # Should have key columns (RINPERSOONS, RINPERSOON, RINKENTEKEN) + requested
  expect_true("RINPERSOON" %in% names(pq))
  expect_true("RINPERSOONS" %in% names(pq))
  expect_true("RINKENTEKEN" %in% names(pq))
  expect_true("BRANDSTCODECORVRTG" %in% names(pq))

  # Should NOT have other columns that the full file would have
  expect_lt(ncol(pq), 13L)  # full RDWNPACT has 13 columns

  # VERKEERSPRESTATIE was not in col_select -> should NOT be exported
  expect_false(dir.exists(file.path(out, "VERKEERSPRESTATIETAB")))

  unlink(out, recursive = TRUE)
})


test_that("sim_export col_select=NULL exports all columns (backward compat)", {
  skip_if_not_installed("arrow")

  tmp <- tempdir()
  out_full <- file.path(tmp, "col_select_full")
  unlink(out_full, recursive = TRUE)

  sim_reset()
  sim_export(
    output_dir = out_full,
    dataset = "rdw",
    year = 2023L,
    n = 100L,
    seed = 42L,
    col_select = NULL
  )

  pq <- arrow::read_parquet(
    file.path(out_full, "RDWNPACTTAB", "RDWNPACT2023TABV1.parquet"))
  expect_equal(ncol(pq), 13L)

  unlink(out_full, recursive = TRUE)
})


test_that("sim_export col_select with file key (lowercase) works", {
  skip_if_not_installed("arrow")

  tmp <- tempdir()
  out <- file.path(tmp, "col_select_fkey")
  unlink(out, recursive = TRUE)

  sim_reset()
  sim_export(
    output_dir = out,
    dataset = "rdw",
    year = 2023L,
    n = 100L,
    seed = 42L,
    col_select = list(
      kentekens = c("BRANDSTCODECORVRTG")
    )
  )

  pq <- arrow::read_parquet(
    file.path(out, "RDWNPACTTAB", "RDWNPACT2023TABV1.parquet"))
  expect_true("BRANDSTCODECORVRTG" %in% names(pq))
  expect_true("RINPERSOON" %in% names(pq))
  expect_lt(ncol(pq), 13L)

  unlink(out, recursive = TRUE)
})


test_that("sim_export col_select: unlisted files are skipped", {
  skip_if_not_installed("arrow")

  tmp <- tempdir()
  out <- file.path(tmp, "col_select_partial")
  unlink(out, recursive = TRUE)

  sim_reset()
  sim_export(
    output_dir = out,
    dataset = "rdw",
    year = 2023L,
    n = 100L,
    seed = 42L,
    col_select = list(
      RDWNPACT = c("BRANDSTCODECORVRTG")
    )
  )

  # VERKEERSPRESTATIE was not in col_select -> should NOT be exported
  expect_false(dir.exists(file.path(out, "VERKEERSPRESTATIETAB")))

  # Only RDWNPACT should exist
  expect_true(dir.exists(file.path(out, "RDWNPACTTAB")))

  unlink(out, recursive = TRUE)
})


test_that("sim_export skips already-simulated files via .sim_meta.yaml", {
  skip_if_not_installed("arrow")

  tmp <- tempdir()
  out <- file.path(tmp, "meta_skip_test")
  unlink(out, recursive = TRUE)

  sim_reset()

  # First export: generates the file and writes meta
  sim_export(
    output_dir = out, dataset = "rdw", year = 2023L, n = 100L, seed = 42L,
    col_select = list(RDWNPACT = c("BRANDSTCODECORVRTG"))
  )
  pq_path <- file.path(out, "RDWNPACTTAB", "RDWNPACT2023TABV1.parquet")
  expect_true(file.exists(pq_path))
  mtime1 <- file.mtime(pq_path)

  # Meta file should exist
  expect_true(file.exists(file.path(out, ".sim_meta.yaml")))

  # Second export with same col_select: should skip (file not rewritten)
  Sys.sleep(1)
  sim_export(
    output_dir = out, dataset = "rdw", year = 2023L, n = 100L, seed = 42L,
    col_select = list(RDWNPACT = c("BRANDSTCODECORVRTG"))
  )
  mtime2 <- file.mtime(pq_path)
  expect_equal(mtime1, mtime2)

  # Third export with additional column: should regenerate
  sim_export(
    output_dir = out, dataset = "rdw", year = 2023L, n = 100L, seed = 42L,
    col_select = list(RDWNPACT = c("BRANDSTCODECORVRTG", "VRTGSOORT"))
  )
  pq <- arrow::read_parquet(pq_path)
  expect_true("VRTGSOORT" %in% names(pq))

  # Fourth export with force_resim: should regenerate even if same
  # (use a fresh directory to avoid Windows file locks from arrow)
  out2 <- file.path(tmp, "meta_force_test")
  unlink(out2, recursive = TRUE)
  sim_reset()
  sim_export(
    output_dir = out2, dataset = "rdw", year = 2023L, n = 100L, seed = 42L,
    col_select = list(RDWNPACT = c("BRANDSTCODECORVRTG"))
  )
  pq_path2 <- file.path(out2, "RDWNPACTTAB", "RDWNPACT2023TABV1.parquet")
  Sys.sleep(1)
  mtime_pre <- file.mtime(pq_path2)
  sim_export(
    output_dir = out2, dataset = "rdw", year = 2023L, n = 100L, seed = 42L,
    col_select = list(RDWNPACT = c("BRANDSTCODECORVRTG")),
    force_resim = TRUE
  )
  mtime_post <- file.mtime(pq_path2)
  expect_true(mtime_post > mtime_pre)

  unlink(out, recursive = TRUE)
  unlink(out2, recursive = TRUE)
})


test_that("sim_scan_columns extracts columns from R scripts", {
  # Create a temp script with read_sav calls
  tmp_script <- tempfile(fileext = ".R")
  writeLines(c(
    'dt <- read_sav("SPOLISBUS2023V1", col_select = c("RINPERSOON", "IKVID", "SBASISUREN"))',
    'rdw <- read_sav("RDWNPACT2023TABV1", col_select = c("RINPERSOON", "RINKENTEKEN"))'
  ), tmp_script)

  cols <- sim_scan_columns(tmp_script)

  expect_true("SPOLISBUS" %in% names(cols))
  expect_true("RDWNPACT" %in% names(cols))
  expect_equal(sort(cols[["SPOLISBUS"]]),
               sort(c("RINPERSOON", "IKVID", "SBASISUREN")))
  expect_equal(sort(cols[["RDWNPACT"]]),
               sort(c("RINPERSOON", "RINKENTEKEN")))

  unlink(tmp_script)
})
