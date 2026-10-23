# tests/testthat/test-cross-datasets.R
# Datasets initialised on one shared spine join on their keys: every key in a
# yearly register is found in the woonbase population of the same year.

test_that("datasets join on their keys within one simulation year", {
  sim_reset()
  sim_init("woonbase", year = 2023L, n = 5000L, seed = 11L)
  for (ds in c("rdw", "spolis", "inpatab", "inhatab", "vehtab", "energieverbruik")) {
    sim_init(ds, year = 2023L, seed = 12L)
  }
  rd <- function(file, cols) data.table::as.data.table(read_sav(file, col_select = tidyselect::all_of(cols)))

  pers <- rd("WoonbasePopulatiePersonen2023V1", c("RINPERSOON", "HUISHOUDNR1Jan"))
  obj  <- rd("WoonbasePopulatieWoonruimten2023V1", "RINOBJECTNUMMER")
  rdw  <- rd("RDWNPACT2023TABV1", c("RINPERSOONS", "RINPERSOON", "RINKENTEKEN"))
  vp   <- rd("VERKEERSPRESTATIE2023TABV1", "RINKENTEKEN")
  jobs <- rd("SPOLISBUS2023V1", "RINPERSOON")
  inpa <- rd("INPA2023TABV1", c("RINPERSOON", "RINPERSOONHKW"))
  inha <- rd("INHA2023TABV1", "RINPERSOONHKW")
  veh  <- rd("VEH2023TABV1", "RINPERSOONHKW")
  ener <- rd("ENERGIEVERBRUIK2023TABV1", "RINOBJECTNUMMER")

  # persons
  # vehicle owners in the GBA link; companies and others (K, S) do not
  in_gba <- as.character(cbs_code(rdw$RINPERSOONS)) == "R"
  expect_true(all(rdw$RINPERSOON[in_gba] %in% pers$RINPERSOON))
  expect_false(any(rdw$RINPERSOON[!in_gba] %in% pers$RINPERSOON))
  expect_true(all(jobs$RINPERSOON %in% pers$RINPERSOON))
  expect_true(all(inpa$RINPERSOON %in% pers$RINPERSOON))
  # vehicles: traffic performance belongs to registered vehicles
  expect_true(all(vp$RINKENTEKEN %in% rdw$RINKENTEKEN))
  # households: income and wealth share the household key of INPATAB
  expect_true(all(inha$RINPERSOONHKW %in% inpa$RINPERSOONHKW))
  expect_gt(mean(veh$RINPERSOONHKW %in% inpa$RINPERSOONHKW), 0.95)
  # dwellings
  expect_true(all(ener$RINOBJECTNUMMER %in% obj$RINOBJECTNUMMER))
})
