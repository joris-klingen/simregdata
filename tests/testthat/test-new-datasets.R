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
    "WoonbaseEKPersonenWV2023V1" = list(file_key = "ek_pers_welvaart", dataset_id = "woonbase", year = 2023L),
    "WOONBASEEKPERSONENOP2023V1" = list(file_key = "ek_pers_opleiding", dataset_id = "woonbase", year = 2023L),
    "WOONBASEEKHuishoudensWL2023V1" = list(file_key = "ek_hh_woonlasten", dataset_id = "woonbase", year = 2023L),
    "WoonbaseEKWoonruimtenWV2023V1" = list(file_key = "ek_obj_welvaart", dataset_id = "woonbase", year = 2023L),
    "BURENNETWERK2023TABV1"   = list(file_key = "burennetwerktab",  dataset_id = "burennetwerktab",  year = 2023L),
    "COLLEGANETWERK2023TABV1" = list(file_key = "colleganetwerktab", dataset_id = "colleganetwerktab", year = 2023L),
    "FAMILIENETWERK2023TABV1" = list(file_key = "familienetwerktab", dataset_id = "familienetwerktab", year = 2023L)
  )

  for (nm in names(new_names)) {
    parsed   <- simregdata:::.parse_file_registry(nm)
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


# ---- WOONBASEEKPERSONENOP ----

test_that("WOONBASEEKPERSONENOP generates valid education data", {
  sim_reset()
  sim_init("woonbase", year = 2023L, n = 200L, seed = 42L)
  dt <- read_sav("WOONBASEEKPERSONENOP2023V1")

  check_tibble(dt, min_rows = 100L, min_cols = 12L)
  expect_equal(ncol(dt), 12L)

  # Key columns
  expect_true("RINPERSOON" %in% names(dt))
  expect_true("RINPERSOONS" %in% names(dt))

  # SOI2021 columns present
  expect_true("OPLNIVSOI2021AGG4HBMETNIRWO1Jan" %in% names(dt))
  expect_true("OPLNIVSOI2021AGG4HBMETNIRWO31Dec" %in% names(dt))
  expect_true("OPLNIVSOI2021AGG4HGMETNIRWO1Jan" %in% names(dt))
  expect_true("OPLNIVSOI2021AGG4HGMETNIRWO31Dec" %in% names(dt))

  # SOI2021 is labelled
  expect_s3_class(dt[["OPLNIVSOI2021AGG4HBMETNIRWO1Jan"]], "haven_labelled")

  # SOI2016 deprecated (all "----")
  expect_true(all(dt[["OPLNIVSOI2016AGG4HBMETNIRWO1Jan"]] == "----"))

  # Weight is numeric
  expect_true(is.numeric(dt[["GEWICHTHOOGSTEOPL1Jan"]]))

  # RINPERSOON is 9-char
  expect_true(all(nchar(dt$RINPERSOON) == 9L))
})


# ---- WOONBASEEKHuishoudensWL ----

test_that("WOONBASEEKHuishoudensWL generates valid housing cost data", {
  sim_reset()
  sim_init("woonbase", year = 2023L, n = 200L, seed = 42L)
  dt <- read_sav("WOONBASEEKHuishoudensWL2023V1")

  check_tibble(dt, min_rows = 50L, min_cols = 144L)
  expect_equal(ncol(dt), 144L)

  # Key columns
  expect_true("RINPERSOON" %in% names(dt))
  expect_true("RINPERSOONS" %in% names(dt))

  # Sample of suffixed columns present
  for (sfx in c("1JAN", "31DEC")) {
    expect_true(paste0("MLTOTAAL", sfx) %in% names(dt))
    expect_true(paste0("MLHKALEHUUR", sfx) %in% names(dt))
    expect_true(paste0("CODEBEZIT", sfx) %in% names(dt))
    expect_true(paste0("QUOTETOTAAL", sfx) %in% names(dt))
  }

  # Numeric cost fields
  expect_true(is.numeric(dt[["MLTOTAAL1JAN"]]))
  expect_true(is.numeric(dt[["HYPSCHULDFISCAAL1JAN"]]))

  # Categoricals are labelled
  expect_s3_class(dt[["CODEBEZIT1JAN"]], "haven_labelled")
  expect_s3_class(dt[["HUURKLASSE1JAN"]], "haven_labelled")
  expect_s3_class(dt[["CODEHUUR1JAN"]], "haven_labelled")
})


# ---- WoonbaseEKWoonruimtenWV ----

test_that("WoonbaseEKWoonruimtenWV generates valid dwelling wealth data", {
  sim_reset()
  sim_init("woonbase", year = 2023L, n = 200L, seed = 42L)
  dt <- read_sav("WoonbaseEKWoonruimtenWV2023V1")

  check_tibble(dt, min_rows = 50L, min_cols = 14L)
  expect_equal(ncol(dt), 14L)

  # Key columns
  expect_true("SOORTOBJECTNUMMER" %in% names(dt))
  expect_true("RINOBJECTNUMMER" %in% names(dt))

  # Suffixed columns present
  for (sfx in c("1JAN", "31DEC")) {
    expect_true(paste0("AGIAHWONING", sfx) %in% names(dt))
    expect_true(paste0("BELIWONING", sfx) %in% names(dt))
    expect_true(paste0("POPIIVWONING", sfx) %in% names(dt))
  }

  # Categoricals are labelled
  expect_s3_class(dt[["POPIIVWONING1JAN"]], "haven_labelled")
  expect_s3_class(dt[["AGIAHWONING1JAN"]], "haven_labelled")

  # Numerics
  expect_true(is.numeric(dt[["BELIWONING1JAN"]]))
  expect_true(is.numeric(dt[["W1000VERWONING1JAN"]]))
})


# ---- WoonbaseEKPersonenWV ----

test_that("WoonbaseEKPersonenWV generates valid person wealth data", {
  sim_reset()
  sim_init("woonbase", year = 2023L, n = 200L, seed = 42L)
  dt <- read_sav("WoonbaseEKPersonenWV2023V1")

  check_tibble(dt, min_rows = 100L, min_cols = 14L)

  # Key columns
  expect_true("RINPERSOON" %in% names(dt))
  expect_true("RINPERSOONS" %in% names(dt))

  # Suffixed columns present for both 1JAN and 31DEC
  for (sfx in c("1JAN", "31DEC")) {
    expect_true(paste0("ARMOEDE", sfx) %in% names(dt))
    expect_true(paste0("ARMSOC", sfx)  %in% names(dt))
    expect_true(paste0("BELI", sfx)    %in% names(dt))
    expect_true(paste0("POPIIV", sfx)  %in% names(dt))
    expect_true(paste0("POSHHK", sfx)  %in% names(dt))
    expect_true(paste0("SECJ", sfx)    %in% names(dt))
  }

  # Income is numeric
  expect_true(is.numeric(dt$BELI1JAN))
  expect_true(is.numeric(dt$BELI31DEC))

  # SECJ is labelled
  expect_s3_class(dt$SECJ1JAN, "haven_labelled")
  expect_s3_class(dt$SECJ31DEC, "haven_labelled")

  # POSHHK is labelled with values 1-7
  expect_s3_class(dt$POSHHK1JAN, "haven_labelled")
  expect_true(all(as.integer(dt$POSHHK1JAN) %in% 1:7))

  # RINPERSOON is 9-char
  expect_true(all(nchar(dt$RINPERSOON) == 9L))
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
  # Compare against the full identity set (the Sleutelbestand key file), not the
  # WoonbasePopulatiePersonen snapshot: networks sample the year-invariant spine,
  # whereas the population file is filtered to the persons present in the year
  # (demographic entry/exit), so it omits some spine persons by design.
  dt_pers <- read_sav("WoonbaseSleutelbestand2023V1",
                       col_select = c(RINPERSOON))

  sim_init("burennetwerktab", year = 2023L, seed = 42L)
  dt_buren <- read_sav("BURENNETWERK2023TABV1",
                         col_select = c(RINPERSOON))

  # All ego persons in buren should come from spine
  common <- intersect(unique(dt_buren$RINPERSOON), dt_pers$RINPERSOON)
  match_rate <- length(common) / length(unique(dt_buren$RINPERSOON))
  expect_equal(match_rate, 1.0)
})


# ---- Longitudinal consistency: network stability across years ----

test_that("buren network is stable for non-movers across years", {
  sim_reset()
  sim_init("burennetwerktab", year = 2020L, n = 200L, seed = 42L)
  dt_2020 <- data.table::as.data.table(
    read_sav("BURENNETWERK2020TABV1"))

  sim_reset()
  sim_init("burennetwerktab", year = 2021L, n = 200L, seed = 42L)
  dt_2021 <- data.table::as.data.table(
    read_sav("BURENNETWERK2021TABV1"))

  # Same set of ego persons (Phase 1 determinism)
  expect_equal(sort(unique(dt_2020$RINPERSOON)),
               sort(unique(dt_2021$RINPERSOON)))

  # For persons in the same gemeente both years, their buren should match
  # Build ego-alter pairs as sets per person
  pairs_2020 <- dt_2020[, .(alter = list(sort(RINPERSOONRELATIE))),
                          by = RINPERSOON]
  pairs_2021 <- dt_2021[, .(alter = list(sort(RINPERSOONRELATIE))),
                          by = RINPERSOON]

  # Merge and compute overlap
  both <- pairs_2020[pairs_2021, on = "RINPERSOON", nomatch = 0L]
  n_stable <- sum(mapply(function(a, b) identical(a, b),
                          both$alter, both$i.alter))

  # Most persons should have identical networks (only movers differ)
  stability <- n_stable / nrow(both)
  expect_gt(stability, 0.80)
})

test_that("familie network is fully stable across years", {
  sim_reset()
  sim_init("familienetwerktab", year = 2020L, n = 200L, seed = 42L)
  dt_2020 <- data.table::as.data.table(
    read_sav("FAMILIENETWERK2020TABV1"))

  sim_reset()
  sim_init("familienetwerktab", year = 2021L, n = 200L, seed = 42L)
  dt_2021 <- data.table::as.data.table(
    read_sav("FAMILIENETWERK2021TABV1"))

  # Familie uses year-invariant seed: identical across years
  expect_equal(nrow(dt_2020), nrow(dt_2021))
  expect_equal(dt_2020$RINPERSOON, dt_2021$RINPERSOON)
  expect_equal(dt_2020$RINPERSOONRELATIE, dt_2021$RINPERSOONRELATIE)
  expect_equal(as.integer(dt_2020$RELATIE), as.integer(dt_2021$RELATIE))
})


# ---- sim_population ----

test_that("sim_population generates all non-network datasets", {
  skip_if_not_installed("arrow")
  out <- file.path(tempdir(), "sim_population_test")
  on.exit(unlink(out, recursive = TRUE), add = TRUE)

  sim_reset()
  sim_population(out, fraction = 0.0005, year = 2023L, seed = 1L,
             verbose = FALSE)

  dirs <- basename(list.dirs(out, recursive = FALSE))
  # Should have folders for woonbase, rdw, spolis, etc. (TAB suffix where applicable)
  expect_true("RDWNPACTTAB" %in% dirs)
  expect_true("SPOLISBUS" %in% dirs)
  expect_true("INPATAB" %in% dirs)

  # Network dirs should NOT exist
  expect_false("BURENNETWERKTAB" %in% dirs)
  expect_false("COLLEGAENETWERKTAB" %in% dirs)
  expect_false("FAMILIENETWERKTAB" %in% dirs)
})

test_that("sim_population include_network adds network datasets", {
  skip_if_not_installed("arrow")
  out <- file.path(tempdir(), "sim_population_net_test")
  on.exit(unlink(out, recursive = TRUE), add = TRUE)

  sim_reset()
  sim_population(out, fraction = 0.0005, year = 2023L, seed = 1L,
             include_network = TRUE, verbose = FALSE)

  dirs <- basename(list.dirs(out, recursive = FALSE))
  expect_true("BURENNETWERKTAB" %in% dirs)
  expect_true("FAMILIENETWERKTAB" %in% dirs)
})

test_that("sim_population validates fraction", {
  expect_error(sim_population(tempdir(), fraction = 0))
  expect_error(sim_population(tempdir(), fraction = 1.5))
  expect_error(sim_population(tempdir(), fraction = -0.1))
})


# ---- Custom datasets (sim_register) ----

test_that("sim_create_custom writes a template YAML", {
  tmp <- tempfile(fileext = ".yaml")
  on.exit(unlink(tmp), add = TRUE)

  sim_create_custom(tmp)
  expect_true(file.exists(tmp))

  content <- readLines(tmp)
  expect_true(any(grepl("^name:", content)))
  expect_true(any(grepl("^key:", content)))
  expect_true(any(grepl("type: categorical", content)))
})

test_that("sim_register creates a working person-keyed dataset", {
  tmp <- tempfile(fileext = ".yaml")
  on.exit(unlink(tmp), add = TRUE)

  writeLines(c(
    "name: test_survey",
    "label: Test Survey",
    "key: rinpersoon",
    "columns:",
    "  - name: satisfaction",
    "    type: categorical",
    "    values: [1, 2, 3]",
    "    labels: [Low, Medium, High]",
    "    probs: [0.3, 0.4, 0.3]",
    "  - name: score",
    "    type: numeric",
    "    mean: 50",
    "    sd: 10",
    "    min: 0",
    "    max: 100",
    "  - name: rid",
    "    type: id",
    "    width: 6",
    "  - name: status",
    "    type: constant",
    "    value: active"
  ), tmp)

  sim_reset()
  sim_register(tmp)
  sim_init("test_survey", year = 2023L, n = 100L, seed = 42L)
  dt <- read_sav("test_survey2023V1")

  check_tibble(dt, min_rows = 100L, min_cols = 6L)

  # Key columns auto-added
  expect_true("RINPERSOON" %in% names(dt))
  expect_true("RINPERSOONS" %in% names(dt))

  # User columns present
  expect_true("satisfaction" %in% names(dt))
  expect_true("score" %in% names(dt))
  expect_true("rid" %in% names(dt))
  expect_true("status" %in% names(dt))

  # Categorical is haven-labelled
  expect_s3_class(dt$satisfaction, "haven_labelled")
  expect_true(all(as.integer(dt$satisfaction) %in% 1:3))

  # Score is numeric in range
  expect_true(is.numeric(dt$score))
  expect_true(all(dt$score >= 0 & dt$score <= 100))

  # ID is 6-char
  expect_true(all(nchar(dt$rid) == 6L))

  # Constant
  expect_true(all(dt$status == "active"))

  # Persons come from shared spine
  sim_init("woonbase", year = 2023L, n = 100L, seed = 42L)
  wb <- read_sav("WoonbasePopulatiePersonen2023V1",
                  col_select = c(RINPERSOON))
  common <- intersect(dt$RINPERSOON, wb$RINPERSOON)
  expect_gt(length(common), 0L)
})

test_that("sim_register works with rinkenteken key", {
  tmp <- tempfile(fileext = ".yaml")
  on.exit(unlink(tmp), add = TRUE)

  writeLines(c(
    "name: test_vehicles",
    "label: Test Vehicles",
    "key: rinkenteken",
    "columns:",
    "  - name: mileage",
    "    type: numeric",
    "    mean: 15000",
    "    sd: 8000",
    "    min: 0"
  ), tmp)

  sim_reset()
  sim_register(tmp)
  sim_init("test_vehicles", year = 2023L, n = 100L, seed = 42L)
  dt <- read_sav("test_vehicles2023V1")

  expect_true("RINKENTEKEN" %in% names(dt))
  expect_true("RINPERSOON" %in% names(dt))
  expect_true("mileage" %in% names(dt))
  expect_true(is.numeric(dt$mileage))
})

test_that("sim_register appears in sim_catalog", {
  tmp <- tempfile(fileext = ".yaml")
  on.exit(unlink(tmp), add = TRUE)

  writeLines(c(
    "name: test_cat",
    "key: rinpersoon",
    "columns:",
    "  - name: x",
    "    type: constant",
    "    value: a"
  ), tmp)

  sim_reset()
  sim_register(tmp)

  out <- capture.output(sim_catalog("test_cat"))
  expect_true(any(grepl("test_cat", out)))
})

test_that("sim_register validates input", {
  tmp <- tempfile(fileext = ".yaml")
  on.exit(unlink(tmp), add = TRUE)

  # Missing name
  writeLines("key: rinpersoon\ncolumns:\n  - name: x\n    type: constant\n    value: a", tmp)
  expect_error(sim_register(tmp), "name")

  # Bad key
  writeLines("name: t\nkey: badkey\ncolumns:\n  - name: x\n    type: constant\n    value: a", tmp)
  expect_error(sim_register(tmp), "Unknown key")

  # No columns
  writeLines("name: t\nkey: rinpersoon", tmp)
  expect_error(sim_register(tmp), "column")
})
