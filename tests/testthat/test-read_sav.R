# tests/testthat/test-read_sav.R
# Ported from scripts/test_read_sav_woonbase.R

test_that("spine initialisation works", {
  sim_reset()
  woonbase_init(year = 2023L, n = 5000L, seed = 42L)

  expect_false(is.null(.wb$spine))
  expect_type(.wb$spine, "list")
  expect_gt(nrow(.wb$spine$pers), 0L)
  expect_gt(nrow(.wb$spine$hh),   0L)
  expect_gt(nrow(.wb$spine$obj),  0L)
  expect_equal(.wb$year, 2023L)

  n_pers <- nrow(.wb$spine$pers)
  n_hh   <- nrow(.wb$spine$hh)
  n_obj  <- nrow(.wb$spine$obj)

  expect_gte(n_pers, 4500L)
  expect_gte(n_hh,   1500L)
  expect_equal(n_obj, n_hh)
})


test_that("file name parsing matches exact CBS names", {
  names_should_match <- list(
    "WoonbaseSleutelbestand2023V1"                  = list(file_key = "sleutel",        year = 2023L),
    "WoonbaseSleutelbestand"                        = list(file_key = "sleutel",        year = NULL),
    "WoonbaseKenmerkenPersonen2023V1"               = list(file_key = "kenmerken_pers", year = 2023L),
    "WoonbaseKenmerkenPersonen"                     = list(file_key = "kenmerken_pers", year = NULL),
    "WoonbaseKenmerkenHuishoudens2022V2.sav"        = list(file_key = "kenmerken_hh",   year = 2022L),
    "WoonbaseKenmerkenHuishoudens"                  = list(file_key = "kenmerken_hh",   year = NULL),
    "WoonbaseKenmerkenWoonruimten2023V1"            = list(file_key = "kenmerken_obj",  year = 2023L),
    "WoonbasePopulatiePersonen2023V1"               = list(file_key = "populatie_pers", year = 2023L),
    "WoonbasePopulatieHuishoudens2024V1"            = list(file_key = "populatie_hh",   year = 2024L),
    "WoonbasePopulatieWoonruimten2023V1.sav"        = list(file_key = "populatie_obj",  year = 2023L),
    "G:/BOUWENENWONEN/WOONBASEPOPULATIEPERSONEN/WoonbasePopulatiePersonen2023V1.sav" =
      list(file_key = "populatie_pers", year = 2023L),
    "GBAPERSOONKTAB2023TABV1"                       = list(file_key = "persoonktab",    year = 2023L),
    "RDWNPACT2023TABV1"                             = list(file_key = "kentekens",      year = 2023L),
    "SPOLISBUS2023V1"                               = list(file_key = "spolisbus",      year = 2023L)
  )

  for (nm in names(names_should_match)) {
    parsed   <- simcbsradata:::.parse_file_registry(nm)
    expected <- names_should_match[[nm]]
    expect_identical(parsed$file_key, expected$file_key, label = paste("file_key for", basename(nm)))
    expect_identical(parsed$year, expected$year, label = paste("year for", basename(nm)))
  }
})


test_that("unregistered files return NULL", {
  expect_null(simcbsradata:::.parse_file_registry("some_other_file.sav"))
  expect_null(simcbsradata:::.parse_file_registry("woonbasepopulatieperso"))
  expect_null(simcbsradata:::.parse_file_registry("woonbasekenmerkenhuis"))
})


test_that("all seven file assemblers return non-empty tibbles", {
  woonbase_init(year = 2023L, n = 5000L, seed = 42L)

  file_keys <- c("WoonbaseSleutelbestand2023V1",
                 "WoonbaseKenmerkenPersonen2023V1",
                 "WoonbaseKenmerkenHuishoudens2023V1",
                 "WoonbaseKenmerkenWoonruimten2023V1",
                 "WoonbasePopulatiePersonen2023V1",
                 "WoonbasePopulatieHuishoudens2023V1",
                 "WoonbasePopulatieWoonruimten2023V1")

  for (f in file_keys) {
    dt <- read_sav(f)
    expect_s3_class(dt, "tbl_df")
    expect_gt(nrow(dt), 0L)
    expect_gt(ncol(dt), 0L)
  }
})


test_that("categorical columns are haven::labelled integers", {
  woonbase_init(year = 2023L, n = 5000L, seed = 42L)

  check_labelled <- function(dt, col, file_key) {
    expect_true(col %in% names(dt))
    expect_s3_class(dt[[col]], "haven_labelled")
    expect_type(unclass(dt[[col]]), "integer")
    expect_gt(length(attr(dt[[col]], "labels")), 0L)
  }

  sleutel       <- read_sav("WoonbaseSleutelbestand2023V1")
  kenmerken_pers <- read_sav("WoonbaseKenmerkenPersonen2023V1")
  kenmerken_hh   <- read_sav("WoonbaseKenmerkenHuishoudens2023V1")
  kenmerken_obj  <- read_sav("WoonbaseKenmerkenWoonruimten2023V1")
  populatie_pers <- read_sav("WoonbasePopulatiePersonen2023V1")
  populatie_hh   <- read_sav("WoonbasePopulatieHuishoudens2023V1")
  populatie_obj  <- read_sav("WoonbasePopulatieWoonruimten2023V1")

  check_labelled(sleutel,        "TYPHH",          "sleutel")
  check_labelled(sleutel,        "PLHH",           "sleutel")
  check_labelled(kenmerken_pers, "PLHH1Jan",       "kenmerken_pers")
  check_labelled(kenmerken_hh,   "TYPHH1Jan",      "kenmerken_hh")
  check_labelled(kenmerken_obj,  "VSLSoort1Jan",   "kenmerken_obj")
  check_labelled(populatie_pers, "TYPHH1Jan",      "populatie_pers")
  check_labelled(populatie_hh,   "TYPHH1Jan",      "populatie_hh")
  check_labelled(populatie_obj,  "VSLSoort1Jan",   "populatie_obj")
})


test_that("n_max and skip work correctly", {
  woonbase_init(year = 2023L, n = 5000L, seed = 42L)

  dt_100  <- read_sav("WoonbasePopulatiePersonen2023V1", n_max = 100L)
  dt_skip <- read_sav("WoonbasePopulatiePersonen2023V1", n_max = 100L, skip = 50L)

  expect_equal(nrow(dt_100),  100L)
  expect_equal(nrow(dt_skip), 100L)
  expect_false(identical(dt_100$RINPERSOON[1], dt_skip$RINPERSOON[1]))
})


test_that("col_select works with tidyselect and character vector", {
  woonbase_init(year = 2023L, n = 5000L, seed = 42L)

  dt_sel <- read_sav("WoonbasePopulatiePersonen2023V1",
                     n_max = 200L,
                     col_select = c(RINPERSOON, TYPHH1Jan, GBAGeboorteJaar1Jan))

  expect_equal(ncol(dt_sel), 3L)
  expect_true("RINPERSOON"          %in% names(dt_sel))
  expect_true("TYPHH1Jan"           %in% names(dt_sel))
  expect_true("GBAGeboorteJaar1Jan" %in% names(dt_sel))

  # Character vector selection
  dt_chr <- read_sav("WoonbaseKenmerkenHuishoudens2023V1",
                     n_max = 100L,
                     col_select = c("HUISHOUDNR1Jan", "TYPHH1Jan"))
  expect_equal(ncol(dt_chr), 2L)
})


test_that("cross-file join consistency works", {
  woonbase_init(year = 2023L, n = 5000L, seed = 42L)

  pers_ids <- read_sav("WoonbasePopulatiePersonen2023V1",
                       col_select = c(RINPERSOON, HUISHOUDNR1Jan))
  hh_ids   <- read_sav("WoonbasePopulatieHuishoudens2023V1",
                       col_select = c(HUISHOUDNR1Jan, TYPHH1Jan))

  expect_gt(nrow(pers_ids), 0L)
  expect_gt(nrow(hh_ids),   0L)

  joined <- merge(pers_ids, hh_ids, by = "HUISHOUDNR1Jan")
  expect_gt(nrow(joined), 0L)

  match_rate <- nrow(joined) / nrow(pers_ids)
  expect_gt(match_rate, 0.95)

  # Persons and sleutel share RINPERSOON
  sleutel_ids <- read_sav("WoonbaseSleutelbestand2023V1",
                          col_select = c(RINPERSOON, HUISHOUDNR))
  pers_ids2   <- read_sav("WoonbasePopulatiePersonen2023V1",
                          col_select = c(RINPERSOON, HUISHOUDNR1Jan))

  joined2 <- merge(sleutel_ids, pers_ids2, by = "RINPERSOON")
  expect_gt(nrow(joined2), 0L)
})


test_that("key IDs are unique in spine", {
  woonbase_init(year = 2023L, n = 5000L, seed = 42L)

  expect_equal(anyDuplicated(.wb$spine$pers$RINPERSOON),     0L)
  expect_equal(anyDuplicated(.wb$spine$hh$HUISHOUDNR),       0L)
  expect_equal(anyDuplicated(.wb$spine$obj$RINOBJECTNUMMER), 0L)
})


test_that("value distributions are plausible", {
  woonbase_init(year = 2023L, n = 5000L, seed = 42L)

  pp <- read_sav("WoonbasePopulatiePersonen2023V1")
  typhh_vals <- as.integer(pp$TYPHH1Jan)
  expect_true(all(typhh_vals %in% 1L:9L, na.rm = TRUE))

  hh <- read_sav("WoonbasePopulatieHuishoudens2023V1")
  lft <- hh$LeeftijdRefPersoon1Jan
  expect_true(is.numeric(lft) || is.integer(lft))
  expect_true(all(lft >= 0L & lft <= 120L, na.rm = TRUE))

  obj <- read_sav("WoonbaseKenmerkenWoonruimten2023V1")
  woz <- obj$WOZWaardeObjectBAG1Jan
  expect_true(is.numeric(woz))
  expect_gt(median(woz, na.rm = TRUE), 50000)
})


test_that("woonbase_reset clears cache and auto-rebuilds", {
  woonbase_init(year = 2023L, n = 5000L, seed = 42L)
  woonbase_reset()
  expect_null(.wb$spine)

  # Auto-init on next read_sav call
  dt_auto <- read_sav("WoonbaseKenmerkenHuishoudens2023V1", n_max = 50L)
  expect_false(is.null(.wb$spine))
  expect_equal(nrow(dt_auto), 50L)
})
