# tests/testthat/test-new-datasets.R
# Tests for HOOGSTEOPLTAB, INPATAB, SECMBUS, INHATAB, BETAB, ZONNESTROOMINSTALLATIES,
# BURENNETWERKTAB, COLLEGANETWERKTAB, FAMILIENETWERKTAB

# ---- Helpers ----

check_tibble <- function(dt, min_rows = 1L, min_cols = 1L) {
  expect_s3_class(dt, "tbl_df")
  expect_gte(nrow(dt), min_rows)
  expect_gte(ncol(dt), min_cols)
}


# ---- File name parsing ----

test_that("new dataset file names parse correctly", {
  new_names <- list(
    "HOOGSTEOPL2023TABV1"  = list(file_key = "hoogsteopltab", dataset_id = "hoogsteopltab", year = 2023L),
    "INPA2023TABV1"        = list(file_key = "inpatab",       dataset_id = "inpatab",       year = 2023L),
    "SECMBUS2023V1"        = list(file_key = "secmbus",       dataset_id = "secmbus",       year = 2023L),
    "INHA2023TABV1"        = list(file_key = "inhatab",       dataset_id = "inhatab",       year = 2023L),
    "BE2023TABV1"          = list(file_key = "betab",         dataset_id = "betab",         year = 2023L),
    "Zonnnestroominstallaties2023V1" = list(file_key = "zonnestroominstallaties", dataset_id = "zonnestroominstallaties", year = 2023L),
    "BURENNETWERK2023TABV1"   = list(file_key = "burennetwerktab",  dataset_id = "burennetwerktab",  year = 2023L),
    "COLLEGANETWERK2023TABV1" = list(file_key = "colleganetwerktab", dataset_id = "colleganetwerktab", year = 2023L),
    "FAMILIENETWERK2023TABV1" = list(file_key = "familienetwerktab", dataset_id = "familienetwerktab", year = 2023L)
  )

  for (nm in names(new_names)) {
    parsed   <- simcbsradata:::.parse_file_registry(nm)
    expected <- new_names[[nm]]
    expect_false(is.null(parsed), label = paste("parsed is not NULL for", nm))
    expect_identical(parsed$file_key,   expected$file_key,   label = paste("file_key for", nm))
    expect_identical(parsed$dataset_id, expected$dataset_id, label = paste("dataset_id for", nm))
    expect_identical(parsed$year,       expected$year,       label = paste("year for", nm))
  }
})


# ---- HOOGSTEOPLTAB ----

test_that("HOOGSTEOPLTAB generates valid education data", {
  sim_reset()
  sim_init("hoogsteopltab", year = 2023L, n = 200L, seed = 42L)
  dt <- read_sav("HOOGSTEOPL2023TABV1")

  check_tibble(dt, min_rows = 200L, min_cols = 16L)

  # Required columns present
  expect_true("RINPERSOON" %in% names(dt))
  expect_true("RINPERSOONS" %in% names(dt))
  expect_true("OPLNRHB" %in% names(dt))
  expect_true("OPLNRHG" %in% names(dt))
  expect_true("GEWICHTHOOGSTEOPL" %in% names(dt))
  expect_true("OPLNIVSOI2021AGG4HBmetNIRWO" %in% names(dt))
  expect_true("OPLNIVSOI2021AGG4HGmetNIRWO" %in% names(dt))

  # SOI2021 variable is labelled
  expect_s3_class(dt$OPLNIVSOI2021AGG4HBmetNIRWO, "haven_labelled")

  # RINPERSOON is 9-char
  expect_true(all(nchar(dt$RINPERSOON) == 9L))

  # Deprecated variables are all "----"
  expect_true(all(dt$OPLNIVSOI2016AGG4HBMETNIRWO == "----"))
  expect_true(all(dt$OPLNIVSOI2016AGG4HGMETNIRWO == "----"))
})


# ---- INPATAB ----

test_that("INPATAB generates valid personal income data", {
  sim_reset()
  sim_init("inpatab", year = 2023L, n = 200L, seed = 42L)
  dt <- read_sav("INPA2023TABV1")

  check_tibble(dt, min_rows = 200L, min_cols = 25L)

  # Key columns
  expect_true("RINPERSOON" %in% names(dt))
  expect_true("RINPERSOONHKW" %in% names(dt))
  expect_true("INPPERSINK" %in% names(dt))
  expect_true("INPPERSPRIM" %in% names(dt))
  expect_true("INPPERSBESTINK" %in% names(dt))
  expect_true("INPSECJ" %in% names(dt))

  # Income is numeric
  expect_true(is.numeric(dt$INPPERSINK))

  # INPSECJ is labelled
  expect_s3_class(dt$INPSECJ, "haven_labelled")

  # HKW IDs are 9-char
  expect_true(all(nchar(dt$RINPERSOONHKW) == 9L))
})


# ---- SECMBUS ----

test_that("SECMBUS generates valid period-expanded data", {
  sim_reset()
  sim_init("secmbus", year = 2023L, n = 200L, seed = 42L)
  dt <- read_sav("SECMBUS2023V1")

  # Should have more rows than persons due to multi-period expansion
  check_tibble(dt, min_rows = 200L, min_cols = 10L)

  # Required columns
  expect_true("RINPERSOON" %in% names(dt))
  expect_true("AANVSECM" %in% names(dt))
  expect_true("EINDSECM" %in% names(dt))
  expect_true("SECM" %in% names(dt))

  # SECM is labelled
  expect_s3_class(dt$SECM, "haven_labelled")

  # Period dates are valid YYYYMMDD strings
  expect_true(all(nchar(dt$AANVSECM) == 8L))
  expect_true(all(nchar(dt$EINDSECM) == 8L))
  expect_true(all(grepl("^2023", dt$AANVSECM)))
  expect_true(all(grepl("^2023", dt$EINDSECM)))

  # Start <= end for each row
  expect_true(all(dt$AANVSECM <= dt$EINDSECM))

  # Multiple persons have > 1 period row (multi-period expansion)
  dt2 <- data.table::as.data.table(dt)
  n_per_person <- dt2[, .N, by = RINPERSOON]
  expect_true(any(n_per_person$N > 1L))
})


# ---- INHATAB ----

test_that("INHATAB generates valid household income data", {
  sim_reset()
  sim_init("inhatab", year = 2023L, n = 200L, seed = 42L)
  dt <- read_sav("INHA2023TABV1")

  check_tibble(dt, min_rows = 200L, min_cols = 25L)

  # Key columns
  expect_true("RINPERSOONSHKW" %in% names(dt))
  expect_true("RINPERSOONHKW" %in% names(dt))
  expect_true("INHBESTINKH" %in% names(dt))
  expect_true("INHGESTINKH" %in% names(dt))
  expect_true("INHP100HBEST" %in% names(dt))

  # Income is numeric
  expect_true(is.numeric(dt$INHBESTINKH))

  # All HKW prefixes are "R"
  hkw_vals <- as.integer(dt$RINPERSOONSHKW)
  expect_true(all(hkw_vals == 1L, na.rm = TRUE))
})


# ---- BETAB ----

test_that("BETAB generates valid business register data", {
  sim_reset()
  sim_init("betab", year = 2023L, n = 200L, seed = 42L)
  dt <- read_sav("BE2023TABV1")

  check_tibble(dt, min_rows = 200L, min_cols = 7L)

  # Key columns
  expect_true("BEID" %in% names(dt))
  expect_true("SBI2008VJJJJ" %in% names(dt))
  expect_true("SBI2025VJJJJ" %in% names(dt))
  expect_true("GKSBS" %in% names(dt))
  expect_true("GEMHVJJJJ" %in% names(dt))

  # SBI2008 is labelled
  expect_s3_class(dt$SBI2008VJJJJ, "haven_labelled")

  # GKSBS is labelled
  expect_s3_class(dt$GKSBS, "haven_labelled")

  # Legacy SBI1993 is constant
  expect_true(all(dt$SBI1993VJJJJ == "-----"))
})


# ---- col_select works for new datasets ----

test_that("col_select works for new datasets", {
  sim_reset()
  sim_init("inpatab", year = 2023L, n = 100L, seed = 42L)

  dt_sel <- read_sav("INPA2023TABV1",
                     col_select = c("RINPERSOON", "INPPERSINK"))
  expect_equal(ncol(dt_sel), 2L)
  expect_true("RINPERSOON" %in% names(dt_sel))
  expect_true("INPPERSINK" %in% names(dt_sel))
})


# ---- Reproducibility ----

test_that("new datasets are reproducible with same seed", {
  sim_reset()
  sim_init("hoogsteopltab", year = 2023L, n = 100L, seed = 42L)
  dt1 <- read_sav("HOOGSTEOPL2023TABV1")

  sim_reset()
  sim_init("hoogsteopltab", year = 2023L, n = 100L, seed = 42L)
  dt2 <- read_sav("HOOGSTEOPL2023TABV1")

  expect_identical(dt1$RINPERSOON, dt2$RINPERSOON)
})


# ---- HKW consistency across INPATAB and INHATAB ----

test_that("HKW IDs are consistent across INPATAB and INHATAB", {
  sim_reset()
  sim_init("inpatab", year = 2023L, n = 200L, seed = 42L)
  dt_inpa <- read_sav("INPA2023TABV1",
                      col_select = c("RINPERSOON", "RINPERSOONHKW"))

  sim_init("inhatab", year = 2023L, n = 200L, seed = 42L)
  dt_inha <- read_sav("INHA2023TABV1",
                      col_select = c("RINPERSOONHKW", "INHBESTINKH"))

  # HKW IDs from INPATAB should link to INHATAB
  common_hkw <- intersect(dt_inpa$RINPERSOONHKW, dt_inha$RINPERSOONHKW)
  expect_gt(length(common_hkw), 0L)
})


# ---- ZONNESTROOMINSTALLATIES ----

test_that("zonnestroominstallaties generates correct structure", {
  sim_reset()
  sim_init("zonnestroominstallaties", year = 2023L, n = 200L, seed = 42L)
  dt <- read_sav("Zonnnestroominstallaties2023V1")

  check_tibble(dt, min_rows = 1L, min_cols = 28L)
  expect_equal(ncol(dt), 28L)

  # Identifiers
  expect_true("EAN_installatie_crypt" %in% names(dt))
  expect_true("RINObjectnummer" %in% names(dt))
  expect_true("SOORTOBJECTNUMMER" %in% names(dt))

  # Capacity
  expect_true(is.numeric(dt[["Vermogen_panelen"]]))
  expect_true(all(dt[["Vermogen_panelen"]] >= 0.5))

  # Production
  expect_true(is.numeric(dt[["Jaarproductie"]]))
  expect_true(all(dt[["Jaarproductie"]] >= 0))

  # Monthly columns present
  months <- c("januari", "februari", "maart", "april", "mei", "juni",
              "juli", "augustus", "september", "oktober", "november", "december")
  for (m in months) {
    expect_true(paste0("Productie_", m) %in% names(dt))
  }

  # Labelled categoricals
  expect_s3_class(dt[["Type"]], "haven_labelled")
  expect_true(all(as.integer(dt[["Type"]]) %in% 1:3))
  expect_s3_class(dt[["Actief_op_31_12"]], "haven_labelled")
})

test_that("zonnestroominstallaties links to energieverbruik objects", {
  sim_reset()
  sim_init("zonnestroominstallaties", year = 2023L, n = 200L, seed = 42L)
  sim_init("energieverbruik", year = 2023L, seed = 42L)

  dt_solar <- read_sav("Zonnnestroominstallaties2023V1",
                        col_select = c(RINObjectnummer))
  dt_ev <- read_sav("ENERGIEVERBRUIK2023TABV1",
                     col_select = c(RINOBJECTNUMMER))

  common <- intersect(dt_solar$RINObjectnummer, dt_ev$RINOBJECTNUMMER)
  match_rate <- length(common) / nrow(dt_solar)
  expect_gt(match_rate, 0.95)
})

test_that("zonnestroominstallaties seasonal pattern is correct", {
  sim_reset()
  sim_init("zonnestroominstallaties", year = 2023L, n = 200L, seed = 42L)
  dt <- read_sav("Zonnnestroominstallaties2023V1")

  summer <- mean(dt[["Productie_juni"]])
  winter <- mean(dt[["Productie_januari"]])
  expect_gt(summer, winter)
})


# ---- ENERGIEVERBRUIKMAANDTAB ----

test_that("energieverbruikmaand generates correct structure", {
  sim_reset()
  sim_init("energieverbruik", year = 2023L, n = 200L, seed = 42L)
  dt <- read_sav("ENERGIEVERBRUIKMAAND2023TABV1")

  check_tibble(dt, min_rows = 1L, min_cols = 62L)
  expect_equal(ncol(dt), 62L)

  # All monthly columns present
  for (prefix in c("GASLEV", "ELKLEV", "ELKTLV", "ELKLEVLAAG", "ELKTLVLAAG")) {
    for (m in sprintf("%02d", 1:12)) {
      expect_true(paste0(prefix, m) %in% names(dt))
    }
  }

  # Numeric values
  expect_true(is.numeric(dt[["GASLEV01"]]))
  expect_true(all(dt[["GASLEV01"]] >= 0))
})

test_that("energieverbruikmaand gas has seasonal pattern", {
  sim_reset()
  sim_init("energieverbruik", year = 2023L, n = 200L, seed = 42L)
  dt <- read_sav("ENERGIEVERBRUIKMAAND2023TABV1")

  jan <- mean(dt[["GASLEV01"]])
  jul <- mean(dt[["GASLEV07"]])
  expect_gt(jan, jul)
})

test_that("energieverbruikmaand shares objects with annual", {
  sim_reset()
  sim_init("energieverbruik", year = 2023L, n = 200L, seed = 42L)

  dt_month <- read_sav("ENERGIEVERBRUIKMAAND2023TABV1",
                         col_select = c(RINOBJECTNUMMER))
  dt_annual <- read_sav("ENERGIEVERBRUIK2023TABV1",
                          col_select = c(RINOBJECTNUMMER))

  expect_equal(sort(dt_month$RINOBJECTNUMMER), sort(dt_annual$RINOBJECTNUMMER))
})


# ---- BURENNETWERKTAB ----

test_that("BURENNETWERKTAB generates valid neighbour network", {
  sim_reset()
  sim_init("burennetwerktab", year = 2023L, n = 100L, seed = 42L)
  dt <- read_sav("BURENNETWERK2023TABV1")

  check_tibble(dt, min_rows = 100L, min_cols = 5L)
  expect_equal(ncol(dt), 5L)

  # Required columns present
  expect_true("RINPERSOONS" %in% names(dt))
  expect_true("RINPERSOON" %in% names(dt))
  expect_true("RINPERSOONSRELATIE" %in% names(dt))
  expect_true("RINPERSOONRELATIE" %in% names(dt))
  expect_true("RELATIE" %in% names(dt))

  # RELATIE is labelled with codes 101 and 102
  expect_s3_class(dt$RELATIE, "haven_labelled")
  expect_true(all(as.integer(dt$RELATIE) %in% c(101L, 102L)))

  # RINPERSOON is 9-char
  expect_true(all(nchar(dt$RINPERSOON) == 9L))
  expect_true(all(nchar(dt$RINPERSOONRELATIE) == 9L))

  # Multiple relations per person (dyadic expansion)
  dt2 <- data.table::as.data.table(dt)
  n_per_person <- dt2[, .N, by = RINPERSOON]
  expect_true(all(n_per_person$N >= 1L))
  expect_gt(mean(n_per_person$N), 5)

  # No self-relations
  expect_true(all(dt$RINPERSOON != dt$RINPERSOONRELATIE))
})


# ---- COLLEGANETWERKTAB ----

test_that("COLLEGANETWERKTAB generates valid colleague network", {
  sim_reset()
  sim_init("colleganetwerktab", year = 2023L, n = 100L, seed = 42L)
  dt <- read_sav("COLLEGANETWERK2023TABV1")

  check_tibble(dt, min_rows = 100L, min_cols = 5L)
  expect_equal(ncol(dt), 5L)

  # All RELATIE codes are 201 (Collega)
  expect_s3_class(dt$RELATIE, "haven_labelled")
  expect_true(all(as.integer(dt$RELATIE) == 201L))

  # No self-relations
  expect_true(all(dt$RINPERSOON != dt$RINPERSOONRELATIE))
})


# ---- FAMILIENETWERKTAB ----

test_that("FAMILIENETWERKTAB generates valid family network", {
  sim_reset()
  sim_init("familienetwerktab", year = 2023L, n = 100L, seed = 42L)
  dt <- read_sav("FAMILIENETWERK2023TABV1")

  check_tibble(dt, min_rows = 100L, min_cols = 5L)
  expect_equal(ncol(dt), 5L)

  # RELATIE codes in 301-322 range
  expect_s3_class(dt$RELATIE, "haven_labelled")
  rel_codes <- as.integer(dt$RELATIE)
  expect_true(all(rel_codes >= 301L & rel_codes <= 322L))

  # Multiple distinct family relationship types
  expect_gt(length(unique(rel_codes)), 5L)

  # No self-relations
  expect_true(all(dt$RINPERSOON != dt$RINPERSOONRELATIE))
})


# ---- Netwerk datasets share persons with woonbase ----

test_that("netwerk persons come from shared spine", {
  sim_reset()
  sim_init("woonbase", year = 2023L, n = 200L, seed = 42L)
  dt_pers <- read_sav("WoonbasePopulatiePersonen2023V1",
                       col_select = c(RINPERSOON))

  sim_init("burennetwerktab", year = 2023L, seed = 42L)
  dt_buren <- read_sav("BURENNETWERK2023TABV1",
                         col_select = c(RINPERSOON))

  # All ego persons in buren should come from spine
  common <- intersect(unique(dt_buren$RINPERSOON), dt_pers$RINPERSOON)
  match_rate <- length(common) / length(unique(dt_buren$RINPERSOON))
  expect_equal(match_rate, 1.0)
})
