# Demographic dynamics across years (births / deaths / migration)
# See R/demographics.R and the Phase 1 / Phase 2 split in R/spine.R.

ch <- function(x) as.character(haven::zap_labels(x))

test_that("life course is deterministic and year-invariant for a fixed seed", {
  sim_reset()
  sim_init("woonbase", year = 2021L, n = 8000L, seed = 7L)
  p21 <- data.table::copy(.sim_cache$spine$pers[
    , .(RINPERSOON, DemogEntryYear, DemogExitYear,
        DemogEntryType, DemogExitType)])

  sim_reset()
  sim_init("woonbase", year = 2025L, n = 8000L, seed = 7L)
  p25 <- .sim_cache$spine$pers[
    , .(RINPERSOON, DemogEntryYear, DemogExitYear,
        DemogEntryType, DemogExitType)]

  # Same persons, same entry/exit years regardless of the simulation year
  data.table::setkey(p21, RINPERSOON)
  data.table::setkey(p25, RINPERSOON)
  expect_equal(p21$RINPERSOON, p25$RINPERSOON)
  expect_equal(p21$DemogEntryYear, p25$DemogEntryYear)
  expect_equal(p21$DemogExitYear,  p25$DemogExitYear)
  expect_equal(p21$DemogEntryType, p25$DemogEntryType)
})

test_that("entry/exit years always form a valid interval", {
  sim_reset()
  sim_init("woonbase", year = 2023L, n = 8000L, seed = 1L)
  p <- .sim_cache$spine$pers
  expect_true(all(p$DemogExitYear >= p$DemogEntryYear))
  expect_true(all(p$DemogEntryType %in% c("birth", "immig")))
  expect_true(all(p$DemogExitType  %in% c("death", "emig")))
})

test_that("present mask matches the entry/exit interval for the year", {
  sim_reset()
  sim_init("woonbase", year = 2023L, n = 8000L, seed = 1L)
  sp <- .sim_cache$spine
  p <- sp$pers
  expected <- p$DemogEntryYear <= 2023L & p$DemogExitYear >= 2023L
  expect_equal(sp$pers_present, expected)
  expect_gt(sum(sp$pers_present), 0L)
  expect_lt(sum(sp$pers_present), nrow(p))  # some persons are absent
})

test_that("population snapshot contains only persons present in the year", {
  sim_reset()
  sim_init("woonbase", year = 2023L, n = 8000L, seed = 1L)
  sp <- .sim_cache$spine
  present_ids <- sp$pers$RINPERSOON[sp$pers_present]

  dt <- data.table::as.data.table(
    read_sav("WoonbasePopulatiePersonen2023V1"))
  expect_setequal(dt$RINPERSOON, present_ids)

  # Nobody present is flagged as having left (or not yet arrived) in a way that
  # contradicts their presence: a person deceased this year is still in the
  # snapshot (present during the year), but absent next year.
  expect_true(all(ch(dt$Indicator_PersoonIsOverleden) %in% c("0", "1")))
})

test_that("panels are unbalanced across years but reproducible", {
  sim_reset()
  sim_init("woonbase", year = 2019L, n = 8000L, seed = 3L)
  d19 <- read_sav("WoonbasePopulatiePersonen2019V1",
                  col_select = RINPERSOON)$RINPERSOON

  sim_reset()
  sim_init("woonbase", year = 2024L, n = 8000L, seed = 3L)
  d24 <- read_sav("WoonbasePopulatiePersonen2024V1",
                  col_select = RINPERSOON)$RINPERSOON

  sim_reset()
  sim_init("woonbase", year = 2024L, n = 8000L, seed = 3L)
  d24b <- read_sav("WoonbasePopulatiePersonen2024V1",
                   col_select = RINPERSOON)$RINPERSOON

  # Different population each year (entry/exit) ...
  expect_false(setequal(d19, d24))
  # ... yet fully reproducible for a given year + seed
  expect_equal(sort(d24), sort(d24b))

  # Persons leave and enter across years
  expect_gt(length(setdiff(d19, d24)), 0L)  # left between 2019 and 2024
  expect_gt(length(setdiff(d24, d19)), 0L)  # entered between 2019 and 2024
})

test_that("mortality accumulates over time (older snapshots are smaller tails)", {
  # A later year has had more time for the fixed birth-year cohorts to die, so
  # the share of the fixed identity set still present trends down.
  sim_reset()
  sim_init("woonbase", year = 2020L, n = 8000L, seed = 5L)
  present_2020 <- mean(.sim_cache$spine$pers_present)

  sim_reset()
  sim_init("woonbase", year = 2035L, n = 8000L, seed = 5L)
  present_2035 <- mean(.sim_cache$spine$pers_present)

  expect_lt(present_2035, present_2020)
})

test_that("every household in the snapshot keeps a reference person", {
  sim_reset()
  sim_init("woonbase", year = 2023L, n = 8000L, seed = 2L)
  dt <- data.table::as.data.table(
    read_sav("WoonbasePopulatiePersonen2023V1"))
  has_ref <- dt[, .(ok = any(ch(RefPersoonHH1Jan) == "1")),
                by = HUISHOUDNR1Jan]
  expect_true(all(has_ref$ok))
})

test_that("GBAPERSOONKTAB is not filtered (one row per person ever)", {
  sim_reset()
  sim_init("gba", year = 2023L, n = 8000L, seed = 2L)
  full_n <- nrow(.sim_cache$spine$pers)
  dt <- data.table::as.data.table(read_sav("GBAPERSOONKTAB2023TABV1"))
  expect_equal(nrow(dt), full_n)
})

test_that("filtering does not disturb the full identity spine used for sampling", {
  # Networks and other datasets sample from the full year-invariant spine, so
  # its row count must stay identical across years for a fixed seed.
  sim_reset()
  sim_init("woonbase", year = 2020L, n = 8000L, seed = 9L)
  n2020 <- nrow(.sim_cache$spine$pers)
  sim_reset()
  sim_init("woonbase", year = 2024L, n = 8000L, seed = 9L)
  n2024 <- nrow(.sim_cache$spine$pers)
  expect_equal(n2020, n2024)
})
