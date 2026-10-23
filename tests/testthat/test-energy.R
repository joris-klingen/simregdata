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
  e <- energy_2023()[!is.na(elek)]
  # as in the register: net delivery capped at 0, feed-in at twice delivery
  expect_equal(e$netto, pmax(e$elek - e$terug, 0))
  expect_true(all(e$terug <= 2 * e$elek))
  expect_true(all(e$terug[!e$zon] == 0))
  expect_gt(mean(e$terug[e$zon] > 0), 0.99)
  expect_lt(mean(e$netto[e$zon]), mean(e$netto[!e$zon]))
})

test_that("district heating dwellings use at most a little gas", {
  e <- energy_2023()[!is.na(gas)]
  hv <- as.character(cbs_code(e$HOOFDVERWARMING31DEC))
  expect_true(all(hv[e$stadsw] %in% c("3", "4", "5")))
  expect_true(all(e$gas[e$stadsw & hv == "5"] == 0))
  expect_true(all(e$gas[e$stadsw] < 400))
})

test_that("register codes follow the dwelling", {
  e <- energy_2023()
  bron <- as.character(cbs_code(e$GASBRON))
  # empty values only where delivery was not assigned
  expect_true(all(is.na(e$gas) == (bron == "NT")))
  expect_gt(sum(is.na(e$elek)), 0)
  # vacant dwellings use nothing, district heating has its own code
  expect_true(all(e$gas[bron == "LG"] == 0 & e$elek[bron == "LG"] == 0))
  expect_true(all(bron[e$stadsw] %in% c("SW", "LG", "NT")))
  # gas-free dwellings have no gas profile
  prof <- as.character(cbs_code(e$WONINGBEWONING10PROFIELEN))
  expect_true(all(prof[bron %in% c("SW", "WP") & e$gas == 0] == "-1", na.rm = TRUE))
  # solar source only for dwellings with panels
  zb <- as.character(cbs_code(e$ZONPVBRON))
  expect_true(all((zb == "4") == !e$zon))
})

test_that("gas and electricity follow the dwelling", {
  e <- energy_2023()
  e <- e[as.character(cbs_code(GASBRON)) != "LG"]
  by_type <- e[, .(gas = mean(gas, na.rm = TRUE), elek = mean(elek, na.rm = TRUE),
                   zon = mean(zon)), by = woningtype]
  data.table::setkey(by_type, woningtype)
  expect_gt(by_type["01", gas], 1.8 * by_type["05", gas])
  expect_gt(by_type["01", elek], 1.5 * by_type["05", elek])
  expect_gt(by_type["01", zon], 4 * by_type["05", zon])
  expect_gt(mean(e$gas[e$bouwjaar < 1946], na.rm = TRUE),
            2 * mean(e$gas[e$bouwjaar >= 2015], na.rm = TRUE))
})

test_that("monthly values add up to the annual values", {
  e <- energy_2023()[!is.na(gas) & !is.na(elek)]
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

test_that("variables introduced in 2022 are empty before", {
  sim_reset()
  suppressWarnings(woonbase_init(year = 2021L, n = 5000L, seed = 42L))
  suppressWarnings(sim_init("energieverbruik", year = 2021L, seed = 43L))
  e <- read_sav("ENERGIEVERBRUIK2021TABV1",
                col_select = c(ZONPVBRON, KBHOOFDVERWARMING31DEC))
  expect_true(all(is.na(e$ZONPVBRON)))
  expect_true(all(is.na(e$KBHOOFDVERWARMING31DEC)))
})
