# test_read_sav_woonbase.R
# Run this in RStudio to verify read_sav_woonbase.R works correctly.
# Each test prints PASS or FAIL with a short description.

source("scripts/functions/read_sav_woonbase.R")

# ── Test helpers ---------------------------------------------------------------

.n_pass <- 0L
.n_fail <- 0L

ok <- function(cond, msg) {
  if (isTRUE(cond)) {
    cat(sprintf("  PASS  %s\n", msg))
    .n_pass <<- .n_pass + 1L
  } else {
    cat(sprintf("  FAIL  %s\n", msg))
    .n_fail <<- .n_fail + 1L
  }
}

section <- function(title) cat(sprintf("\n── %s ──\n", title))


# ── 1. Spine initialisation ---------------------------------------------------

section("1. Spine initialisation")

woonbase_init(year = 2023L, n = 5000L, seed = 42L)

ok(!is.null(.wb$spine),           "spine is not NULL after init")
ok(is.list(.wb$spine),            "spine is a list")
ok(nrow(.wb$spine$pers) > 0L,    "spine$pers has rows")
ok(nrow(.wb$spine$hh)   > 0L,    "spine$hh has rows")
ok(nrow(.wb$spine$obj)  > 0L,    "spine$obj has rows")
ok(.wb$year == 2023L,             "spine year is 2023")

n_pers <- nrow(.wb$spine$pers)
n_hh   <- nrow(.wb$spine$hh)
n_obj  <- nrow(.wb$spine$obj)
cat(sprintf("    spine sizes: %s persons / %s households / %s objects\n",
            format(n_pers, big.mark=","),
            format(n_hh,   big.mark=","),
            format(n_obj,  big.mark=",")))

ok(n_pers >= 4500L,  "person count is plausible (>= n * 0.9)")
ok(n_hh   >= 1500L,  "household count is plausible")
ok(n_obj  == n_hh,   "object count equals household count")


# ── 2. File name parsing -------------------------------------------------------

section("2. File name parsing (various name formats)")

names_should_match <- c(
  "WoonbaseSleutelbestand2023V1"             = "sleutel",
  "woonbasesleutelbestand"                   = "sleutel",
  "WoonbaseKenmerkenPersonen2023V1"          = "kenmerken_pers",
  "woonbasekenmerkenpers"                    = "kenmerken_pers",
  "WoonbaseKenmerkenHuishoudens2022V2.sav"   = "kenmerken_hh",
  "woonbasekenmerkenhuis"                    = "kenmerken_hh",
  "WoonbaseKenmerkenWoonruimten2023"         = "kenmerken_obj",
  "woonbasekenmerkenwoon"                    = "kenmerken_obj",
  "WoonbasePopulatiePersonen2023V1"          = "populatie_pers",
  "woonbasepopulatieperso"                   = "populatie_pers",
  "WoonbasePopulatieHuishoudens2023"         = "populatie_hh",
  "woonbasepopulatiehuis"                    = "populatie_hh",
  "WoonbasePopulatieWoonruimten2023V1.sav"   = "populatie_obj",
  "woonbasepopulatiewoon"                    = "populatie_obj"
)

for (nm in names(names_should_match)) {
  parsed <- .wb_parse_file(nm)
  ok(identical(parsed, names_should_match[[nm]]),
     sprintf("parse '%s' -> '%s'", nm, names_should_match[[nm]]))
}

ok(is.null(.wb_parse_file("some_other_file.sav")), "non-Woonbase file -> NULL")
ok(is.null(.wb_parse_file("/path/to/GBA2023.sav")), "GBA file -> NULL (no false match)")


# ── 3. All seven file assemblers -----------------------------------------------

section("3. All seven file assemblers return non-empty tibbles")

file_keys <- c("woonbasesleutelbestand2023V1",
               "woonbasekenmerkenpers2023",
               "woonbasekenmerkenhuis2023",
               "woonbasekenmerkenwoon2023",
               "woonbasepopulatieperso2023",
               "woonbasepopulatiehuis2023",
               "woonbasepopulatiewoon2023")

results <- list()
for (f in file_keys) {
  dt <- tryCatch(read_sav(f), error = function(e) { cat("  ERROR:", conditionMessage(e), "\n"); NULL })
  key <- .wb_parse_file(f)
  ok(!is.null(dt),         sprintf("%s: no error", key))
  ok(is.data.frame(dt),    sprintf("%s: returns data frame", key))
  ok(nrow(dt) > 0L,        sprintf("%s: has rows (%d)", key, if(!is.null(dt)) nrow(dt) else 0L))
  ok(ncol(dt) > 0L,        sprintf("%s: has columns (%d)", key, if(!is.null(dt)) ncol(dt) else 0L))
  results[[key]] <- dt
}


# ── 4. haven::labelled columns ------------------------------------------------

section("4. Categorical columns are haven::labelled integers")

check_labelled <- function(dt, col, file_key) {
  if (!col %in% names(dt)) {
    ok(FALSE, sprintf("%s: column '%s' exists", file_key, col))
    return()
  }
  ok(inherits(dt[[col]], "haven_labelled"),
     sprintf("%s: %s is haven_labelled", file_key, col))
  ok(is.integer(unclass(dt[[col]])),
     sprintf("%s: %s underlying type is integer", file_key, col))
  ok(length(attr(dt[[col]], "labels")) > 0L,
     sprintf("%s: %s has value labels", file_key, col))
}

check_labelled(results$sleutel,        "TYPHH",          "sleutel")
check_labelled(results$sleutel,        "PLHH",           "sleutel")
check_labelled(results$kenmerken_pers, "PLHH1Jan",       "kenmerken_pers")
check_labelled(results$kenmerken_hh,   "TYPHH1Jan",      "kenmerken_hh")
check_labelled(results$kenmerken_obj,  "VSLSoort1Jan",   "kenmerken_obj")
check_labelled(results$populatie_pers, "TYPHH1Jan",      "populatie_pers")
check_labelled(results$populatie_hh,   "TYPHH1Jan",      "populatie_hh")
check_labelled(results$populatie_obj,  "VSLSoort1Jan",   "populatie_obj")


# ── 5. n_max and skip --------------------------------------------------------

section("5. n_max and skip")

dt_100  <- read_sav("woonbasepopulatieperso", n_max = 100L)
dt_skip <- read_sav("woonbasepopulatieperso", n_max = 100L, skip = 50L)

ok(nrow(dt_100)  == 100L, "n_max=100 returns exactly 100 rows")
ok(nrow(dt_skip) == 100L, "skip=50, n_max=100 returns 100 rows")
ok(!identical(dt_100$RINPERSOON[1], dt_skip$RINPERSOON[1]),
   "skip shifts the starting row (different first RINPERSOON)")


# ── 6. col_select (tidyselect) ------------------------------------------------

section("6. col_select")

dt_sel <- read_sav("woonbasepopulatieperso",
                   n_max = 200L,
                   col_select = c(RINPERSOON, TYPHH1Jan, GBAGeboorteJaar1Jan))

ok(ncol(dt_sel) == 3L,                      "col_select tidyselect: exactly 3 columns")
ok("RINPERSOON"      %in% names(dt_sel),     "col_select: RINPERSOON present")
ok("TYPHH1Jan"       %in% names(dt_sel),     "col_select: TYPHH1Jan present")
ok("GBAGeboorteJaar1Jan" %in% names(dt_sel), "col_select: GBAGeboorteJaar1Jan present")

# Character vector selection
dt_chr <- read_sav("woonbasekenmerkenhuis2023",
                   n_max = 100L,
                   col_select = c("HUISHOUDNR1Jan", "TYPHH1Jan"))
ok(ncol(dt_chr) == 2L,  "col_select character vector: 2 columns")


# ── 7. Cross-file join consistency -------------------------------------------

section("7. Cross-file join consistency (shared spine IDs)")

pers_ids <- read_sav("woonbasepopulatieperso",
                     col_select = c(RINPERSOON, HUISHOUDNR1Jan))
hh_ids   <- read_sav("woonbasepopulatiehuis",
                     col_select = c(HUISHOUDNR1Jan, TYPHH1Jan))

ok(nrow(pers_ids) > 0L, "person file has rows for join test")
ok(nrow(hh_ids)   > 0L, "household file has rows for join test")

joined <- merge(pers_ids, hh_ids, by = "HUISHOUDNR1Jan")
ok(nrow(joined) > 0L,
   sprintf("HUISHOUDNR1Jan join yields %d rows (> 0)", nrow(joined)))

match_rate <- nrow(joined) / nrow(pers_ids)
ok(match_rate > 0.95,
   sprintf("join match rate %.1f%% (> 95%%)", match_rate * 100))

# Persons and sleutel share RINPERSOON
sleutel_ids <- read_sav("woonbasesleutelbestand2023", col_select = c(RINPERSOON, HUISHOUDNR))
pers_ids2   <- read_sav("woonbasepopulatieperso",    col_select = c(RINPERSOON, HUISHOUDNR1Jan))

joined2 <- merge(sleutel_ids, pers_ids2, by = "RINPERSOON")
ok(nrow(joined2) > 0L,
   sprintf("RINPERSOON join (sleutel ↔ populatie_pers): %d rows", nrow(joined2)))


# ── 8. Uniqueness of key IDs -------------------------------------------------

section("8. Uniqueness of key IDs")

ok(anyDuplicated(.wb$spine$pers$RINPERSOON)  == 0L, "RINPERSOON unique in spine")
ok(anyDuplicated(.wb$spine$hh$HUISHOUDNR)    == 0L, "HUISHOUDNR unique in spine")
ok(anyDuplicated(.wb$spine$obj$RINOBJECTNUMMER) == 0L, "RINOBJECTNUMMER unique in spine")


# ── 9. Value distribution sanity checks --------------------------------------

section("9. Value distribution sanity checks")

pp <- results$populatie_pers
typhh_vals <- as.integer(pp$TYPHH1Jan)
ok(all(typhh_vals %in% 1L:9L, na.rm=TRUE),  "populatie_pers: TYPHH1Jan values in 1-9")

hh <- results$populatie_hh
lft <- hh$LeeftijdRefPersoon1Jan
ok(is.numeric(lft) || is.integer(lft),       "populatie_hh: LeeftijdRefPersoon1Jan is numeric")
ok(all(lft >= 0L & lft <= 120L, na.rm=TRUE), "populatie_hh: LeeftijdRefPersoon1Jan in 0-120")

obj <- results$kenmerken_obj
woz <- obj$WOZWaardeObjectBAG1Jan
ok(is.numeric(woz),                           "kenmerken_obj: WOZWaardeObjectBAG1Jan is numeric")
ok(median(woz, na.rm=TRUE) > 50000,           "kenmerken_obj: median WOZ > 50k")


# ── 10. woonbase_reset --------------------------------------------------------

section("10. woonbase_reset clears cache")

woonbase_reset()
ok(is.null(.wb$spine), "spine is NULL after reset")

# Auto-init on next read_sav call (small n_max so it's fast)
dt_auto <- read_sav("woonbasekenmerkenhuis2023", n_max = 50L)
ok(!is.null(.wb$spine),  "spine auto-rebuilt on read_sav after reset")
ok(nrow(dt_auto) == 50L, "auto-init + n_max=50 returns 50 rows")


# ── Summary -------------------------------------------------------------------

cat(sprintf("\n══════════════════════════════\n"))
cat(sprintf("  Results: %d passed, %d failed\n", .n_pass, .n_fail))
cat(sprintf("══════════════════════════════\n"))
if (.n_fail == 0L) cat("  All tests passed!\n") else cat("  Some tests FAILED — check output above.\n")
