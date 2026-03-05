# Temporary script: check all simulated columns against PDF metadata
suppressPackageStartupMessages({
  library(data.table)
  library(haven)
})
devtools::load_all(".")

checks <- list(
  list(ds="woonbase", file="WoonbaseSleutelbestand2023V1",
       txt="docs/extracted/full_text/woonbase/Woonbase-Sleutelbestand.txt"),
  list(ds="woonbase", file="WoonbaseKenmerkenPersonen2023V1",
       txt="docs/extracted/full_text/woonbase/Woonbase-Kenmerken-Personen.txt"),
  list(ds="woonbase", file="WoonbaseKenmerkenHuishoudens2023V1",
       txt="docs/extracted/full_text/woonbase/Woonbase-Kenmerken-Huishoudens.txt"),
  list(ds="woonbase", file="WoonbaseKenmerkenWoonruimten2023V1",
       txt="docs/extracted/full_text/woonbase/Woonbase-Kenmerken-Woonruimten.txt"),
  list(ds="woonbase", file="WoonbasePopulatiePersonen2023V1",
       txt="docs/extracted/full_text/woonbase/Woonbase-Populatie-Personen.txt"),
  list(ds="woonbase", file="WoonbasePopulatieHuishoudens2023V1",
       txt="docs/extracted/full_text/woonbase/Woonbase-Populatie-Huishoudens.txt"),
  list(ds="woonbase", file="WoonbasePopulatieWoonruimten2023V1",
       txt="docs/extracted/full_text/woonbase/Woonbase-Populatie-Woonruimten.txt"),
  list(ds="woonbase", file="WOONBASEEKHuishoudensWV2023V1",
       txt="docs/extracted/full_text/woonbase/Woonbase-Extra-kenmerken-Huishoudens-Welvaart.txt"),
  list(ds="woonbase", file="ExtraKenmerkenPanden2023V1",
       txt="docs/extracted/full_text/woonbase/Woonbase-Extra-kenmerken-Woonruimten-Panden.txt"),
  list(ds="rdw", file="RDWNPACT2023TABV1",
       txt="docs/extracted/full_text/rdw/rdwnpacttab.txt"),
  list(ds="rdw", file="VERKEERSPRESTATIE2023TABV1",
       txt="docs/extracted/full_text/rdw/verkeersprestatietab.txt"),
  list(ds="spolis", file="SPOLISBUS2023V1",
       txt="docs/extracted/full_text/spolis/spolisbus.txt"),
  list(ds="vehtab", file="VEH2023TABV1",
       txt="docs/extracted/full_text/vehtab/vehtab.txt"),
  list(ds="energieverbruik", file="ENERGIEVERBRUIK2023TABV1",
       txt="docs/extracted/full_text/energieverbruik/energieverbruiktab.txt")
)

sim_reset()
sim_init("woonbase", year = 2023, n = 500, seed = 1)
for (ds in c("rdw", "spolis", "vehtab", "energieverbruik"))
  sim_init(ds, year = 2023, n = 500, seed = 1)

results <- list()
for (chk in checks) {
  if (!file.exists(chk$txt)) { cat("SKIP:", chk$file, "\n"); next }
  pdf_cols <- tryCatch(cbs_parse_pdf_columns(chk$txt), error = function(e) NULL)
  if (is.null(pdf_cols)) { cat("PARSE FAIL:", chk$file, "\n"); next }
  dt <- tryCatch(read_sav(chk$file), error = function(e) NULL)
  if (is.null(dt)) { cat("READ FAIL:", chk$file, "\n"); next }

  sim_names <- names(dt)
  pdf_names <- pdf_cols$naam
  matched <- intersect(sim_names, pdf_names)
  sim_rest <- setdiff(sim_names, matched)
  pdf_rest <- setdiff(pdf_names, matched)

  sim_lower <- tolower(sim_rest)
  pdf_lower <- tolower(pdf_rest)
  case_overlap <- intersect(sim_lower, pdf_lower)

  case_pairs <- if (length(case_overlap) > 0) {
    data.frame(
      sim = sim_rest[match(case_overlap, sim_lower)],
      pdf = pdf_rest[match(case_overlap, pdf_lower)])
  } else data.frame(sim = character(), pdf = character())

  true_missing <- setdiff(pdf_rest, case_pairs$pdf)
  true_extra <- setdiff(sim_rest, case_pairs$sim)

  results[[length(results) + 1]] <- data.table(
    dataset = chk$ds, file = chk$file,
    pdf_cols = length(pdf_names), sim_cols = length(sim_names),
    matched = length(matched), case_mm = nrow(case_pairs),
    missing = length(true_missing), extra = length(true_extra))

  if (length(true_missing) > 0 || length(true_extra) > 0 || nrow(case_pairs) > 0) {
    cat(sprintf("\n--- %s ---\n", chk$file))
    if (nrow(case_pairs) > 0) {
      cat("  Case mismatches:\n")
      for (i in seq_len(nrow(case_pairs)))
        cat(sprintf("    sim: %-40s pdf: %s\n", case_pairs$sim[i], case_pairs$pdf[i]))
    }
    if (length(true_missing) > 0) cat("  Missing from sim:", paste(true_missing, collapse = ", "), "\n")
    if (length(true_extra) > 0) cat("  Extra in sim:", paste(true_extra, collapse = ", "), "\n")
  }
}

cat("\n\n=== COLUMN CHECK SUMMARY ===\n\n")
dt_res <- rbindlist(results)
print(dt_res, row.names = FALSE)
cat(sprintf("\nTotal: %d matched, %d case mismatches, %d missing, %d extra across %d files\n",
    sum(dt_res$matched), sum(dt_res$case_mm), sum(dt_res$missing), sum(dt_res$extra), nrow(dt_res)))
