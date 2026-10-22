# tests/testthat/test-energy.R
# Dwelling-level energy use (R/energy.R): consistent columns and the
# published gradients by dwelling characteristics.

energy_2023 <- function() {
  sim_reset()
  woonbase_init(year = 2023L, n = 20000L, seed = 42L)
  sim_init("energieverbruik", year = 2023L, seed = 43L)
  e <- data.table::as.data.table(read_sav("ENERGIEVERBRUIK2023TABV1"))
  obj <- .sim_cache$spine$obj
  e[obj, on = "RINOBJECTNUMMER", `:=`(
    woningtype = i.VBOWoningType1Jan, bouwjaar = i.VBOBouwjaar1Jan)]
  e[, `:=`(gas = as.numeric(GAS), elek = as.numeric(ELEK),
           terug = as.numeric(ELEKTERUG), netto = as.numeric(ELEKNETTO),
           zon = as.character(cbs_code(ZONPV)) == "1",
           stadsw = as.character(cbs_code(STADSW)) == "1")]
  e
}

test_that("electricity columns are consistent with each other and with solar panels", {
  e <- energy_2023()
  expect_equal(e$netto, e$elek - e$terug)
  expect_true(all(e$terug[!e$zon] == 0))
  expect_true(all(e$terug[e$zon] > 0))
  expect_lt(mean(e$netto[e$zon]), mean(e$netto[!e$zon]))
})

test_that("district heating dwellings use no gas", {
  e <- energy_2023()
  expect_true(all(e$gas[e$stadsw] == 0))
  expect_equal(as.character(cbs_code(e$HOOFDVERWARMING31DEC))[e$stadsw],
               rep("5", sum(e$stadsw)))
})

test_that("gas and electricity follow the dwelling", {
  e <- energy_2023()
  by_type <- e[, .(gas = mean(gas), elek = mean(elek), zon = mean(zon)), by = woningtype]
  data.table::setkey(by_type, woningtype)
  expect_gt(by_type["01", gas], 1.8 * by_type["05", gas])
  expect_gt(by_type["01", elek], 1.5 * by_type["05", elek])
  expect_gt(by_type["01", zon], 4 * by_type["05", zon])
  expect_gt(mean(e$gas[e$bouwjaar < 1946]), 2 * mean(e$gas[e$bouwjaar >= 2015]))
})

test_that("monthly values add up to the annual values", {
  e <- energy_2023()
  m <- data.table::as.data.table(read_sav("ENERGIEVERBRUIKMAAND2023TABV1"))
  m <- m[match(e$RINOBJECTNUMMER, m$RINOBJECTNUMMER)]
  gas_m <- rowSums(as.matrix(m[, paste0("GASLEV", sprintf("%02d", 1:12)), with = FALSE]))
  elek_m <- rowSums(as.matrix(m[, c(paste0("ELKLEV", sprintf("%02d", 1:12)),
                                    paste0("ELKLEVLAAG", sprintf("%02d", 1:12))), with = FALSE]))
  expect_equal(gas_m, e$gas, tolerance = 0.01)
  expect_equal(elek_m, e$elek, tolerance = 0.01)
})

test_that("solar panels stay installed in later years", {
  zon_year <- function(y) {
    sim_reset()
    suppressWarnings(woonbase_init(year = y, n = 20000L, seed = 42L))
    suppressWarnings(sim_init("energieverbruik", year = y, seed = 43L))
    e <- data.table::as.data.table(read_sav(sprintf("ENERGIEVERBRUIK%dTABV1", y),
                                            col_select = c(RINOBJECTNUMMER, ZONPV)))
    e[as.character(cbs_code(ZONPV)) == "1", RINOBJECTNUMMER]
  }
  z21 <- zon_year(2021L)
  z23 <- zon_year(2023L)
  expect_gt(length(z23), length(z21))
  expect_gt(mean(z21 %in% z23), 0.9)
})
