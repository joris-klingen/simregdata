# tests/testthat/test-dwellings.R
# Dwelling (object) attributes on the spine: stable per dwelling, classes
# consistent with values, no construction years after the simulation year.

spine_obj <- function(year, n = 20000L, seed = 42L) {
  sim_reset()
  woonbase_init(year = year, n = n, seed = seed)
  data.table::copy(.sim_cache$spine$obj)
}

test_that("dwelling attributes are the same on 1 January and 31 December", {
  obj <- spine_obj(2023L)
  for (col in c("GemeenteCodeJJJJ", "BuurtCodeJJJJ", "VBOWoningType", "TypeEigenaar",
                "VBOBouwjaar", "VBOBouwJaarKlasse", "VBOOppervlakte",
                "VBOOppervlakteKlasse", "WOZWaardeObjectBAG")) {
    expect_identical(obj[[paste0(col, "1Jan")]], obj[[paste0(col, "31Dec")]],
                     info = col)
  }
})

test_that("construction-year and floor-area classes match the values", {
  obj <- spine_obj(2023L)
  expect_identical(obj$VBOBouwJaarKlasse1Jan,
                   as.character(findInterval(obj$VBOBouwjaar1Jan, .BOUWJAAR_LOWER)))
  # unknown values: class 9, floor area empty, WOZ 99999999999
  opp_unk <- obj$VBOOppervlakteKlasse1Jan == "9"
  woz_unk <- obj$WOZWaardeObjectBAGKlasse1Jan == "9"
  expect_gt(sum(opp_unk), 0)
  expect_gt(sum(woz_unk), 0)
  expect_true(all(is.na(obj$VBOOppervlakte1Jan) == opp_unk))
  expect_true(all((obj$WOZWaardeObjectBAG1Jan == 99999999999) == woz_unk))
  expect_identical(obj$VBOOppervlakteKlasse1Jan[!opp_unk],
                   as.character(findInterval(obj$VBOOppervlakte1Jan[!opp_unk], .OPP_LOWER)))
  expect_identical(obj$WOZWaardeObjectBAGKlasse1Jan[!woz_unk],
                   .woz_to_klasse(obj$WOZWaardeObjectBAG1Jan[!woz_unk]))
})

test_that("no dwelling is built after the simulation year", {
  for (yr in c(2012L, 2023L)) {
    obj <- spine_obj(yr)
    expect_lte(max(obj$VBOBouwjaar1Jan), yr)
    expect_identical(obj$Indicator_VBOIsNieuwbouw,
                     ifelse(obj$VBOBouwjaar1Jan == yr, "1", "0"))
  }
})

test_that("dwellings keep their attributes across simulation years", {
  a <- spine_obj(2022L)
  b <- spine_obj(2023L)
  m <- merge(a, b, by = "RINOBJECTNUMMER", suffixes = c(".a", ".b"))
  expect_equal(nrow(m), nrow(a))

  # construction year stable, except dwellings built in the later year
  old <- m$VBOBouwjaar1Jan.b <= 2022L
  expect_identical(m$VBOBouwjaar1Jan.a[old], m$VBOBouwjaar1Jan.b[old])
  expect_gt(mean(old), 0.98)
  # floor area follows dwelling type, which changes only where the
  # gemeente's apartment share does
  expect_gt(mean(m$VBOOppervlakte1Jan.a == m$VBOOppervlakte1Jan.b, na.rm = TRUE), 0.98)
  # gemeente only moves where the shares change or gemeenten merge
  expect_gt(mean(m$GemeenteCodeJJJJ1Jan.a == m$GemeenteCodeJJJJ1Jan.b), 0.95)
})

test_that("gemeente shares follow the StatLine population weights", {
  obj <- spine_obj(2023L, n = 100000L)
  p <- suppressMessages(woonbase_cbs_params(2023L))
  share <- table(obj$GemeenteCodeJJJJ1Jan)[p$gem_codes]
  share[is.na(share)] <- 0
  expect_gt(stats::cor(as.numeric(share) / nrow(obj), p$gem_probs / sum(p$gem_probs)), 0.99)
})

test_that(".hash_pair gives proportional weighted rendezvous", {
  ids <- .hash_id_num(sprintf("%016d", 1:20000))
  w <- c(1, 2, 3, 4)
  pick <- .rendezvous(ids, 1:4, w, "test")
  expect_equal(as.numeric(table(pick)) / length(pick), w / sum(w), tolerance = 0.05)
})

test_that("floor area depends on dwelling type", {
  obj <- spine_obj(2023L, n = 50000L)
  opp <- tapply(obj$VBOOppervlakte1Jan, obj$VBOWoningType1Jan, stats::median, na.rm = TRUE)
  expect_lt(opp[["05"]], opp[["04"]])
  expect_lt(opp[["04"]], opp[["01"]])
})
