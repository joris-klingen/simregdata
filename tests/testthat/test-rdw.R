# tests/testthat/test-rdw.R
# Vehicle structure of RDWNPACT and VERKEERSPRESTATIE (R/rdw_vehicles.R)

rdw_2023 <- function() {
  sim_reset()
  woonbase_init(year = 2023L, n = 20000L, seed = 42L)
  sim_init("rdw", year = 2023L, seed = 43L)
  list(kent = data.table::as.data.table(read_sav("RDWNPACT2023TABV1")),
       vp = data.table::as.data.table(read_sav("VERKEERSPRESTATIE2023TABV1")))
}
code <- function(x) as.character(cbs_code(x))

test_that("owners can have several vehicles, each with its own plate", {
  d <- rdw_2023()
  expect_equal(data.table::uniqueN(d$kent$RINKENTEKEN), nrow(d$kent))
  per_owner <- d$kent[code(RINPERSOONS) == "R", .N, by = RINPERSOON]$N
  expect_gt(mean(per_owner > 1), 0.15)
})

test_that("the file holds dropped and business-stock passenger cars", {
  soort <- code(rdw_2023()$kent$VRTGSOORT)
  expect_gt(sum(soort == "F"), 0)
  expect_gt(sum(soort == "P"), 0)
})

test_that("traffic performance covers active cars of natural persons only", {
  d <- rdw_2023()
  cars <- d$kent[code(VRTGSOORT) == "6" & code(SRTREFVRTG) == "N"]
  expect_setequal(d$vp$RINKENTEKEN, cars$RINKENTEKEN)
  m <- d$vp[d$kent, on = "RINKENTEKEN", nomatch = 0]
  expect_identical(m$RinpersoonVP, m$RINPERSOON)
})

test_that("numeric columns are numeric and weights vary", {
  d <- rdw_2023()
  expect_type(d$vp$VPGEWICHT, "double")
  expect_type(d$vp$VPDGNWEG, "double")
  expect_type(d$kent$AANTALCYLCORVRTG, "double")
  expect_gt(stats::sd(d$vp$VPGEWICHT), 0.05)
})

test_that("type-specific fields are filled only for their vehicle types", {
  k <- rdw_2023()$kent
  soort <- code(k$VRTGSOORT)
  car <- soort %in% c("6", "F", "P")
  expect_true(all((code(k$KLEURCODEVRTG) == "99") == !car))
  expect_true(all(is.na(k$CYLININHOUDCORVRTG[!soort %in% c("7", "Q")])))
  expect_true(all(is.na(k$MASSALEEGCORVRTG[soort %in% c("7", "Q")])))
  expect_true(all(is.na(k$MAXLAADVERMCORVRTG[car])))
  expect_true(all(is.na(k$SOORTBROMFIETSCOR[soort != "0"])))
})

test_that("company-owned vehicles carry origin K", {
  k <- rdw_2023()$kent
  expect_true(all(code(k$RINPERSOONS)[code(k$SRTREFVRTG) != "N"] == "K"))
})
