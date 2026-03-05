# Check simulated columns against CBS PDF documentation ----
#
# Runs cbs_check_columns() for each of the 9 Woonbase file types and
# prints a per-file report of matched / missing / extra / case-mismatch
# columns.

devtools::load_all(".")

pdf_dir <- "docs/extracted/full_text/woonbase"

# Mapping: file_type key → CBS file name, PDF text file
file_map <- list(
  sleutel        = list(file = "WoonbaseSleutelbestand2023V1",
                        txt  = "Woonbase-Sleutelbestand.txt"),
  kenmerken_pers = list(file = "WoonbaseKenmerkenPersonen2023V1",
                        txt  = "Woonbase-Kenmerken-Personen.txt"),
  kenmerken_hh   = list(file = "WoonbaseKenmerkenHuishoudens2023V1",
                        txt  = "Woonbase-Kenmerken-Huishoudens.txt"),
  kenmerken_obj  = list(file = "WoonbaseKenmerkenWoonruimten2023V1",
                        txt  = "Woonbase-Kenmerken-Woonruimten.txt"),
  populatie_pers = list(file = "WoonbasePopulatiePersonen2023V1",
                        txt  = "Woonbase-Populatie-Personen.txt"),
  populatie_hh   = list(file = "WoonbasePopulatieHuishoudens2023V1",
                        txt  = "Woonbase-Populatie-Huishoudens.txt"),
  populatie_obj  = list(file = "WoonbasePopulatieWoonruimten2023V1",
                        txt  = "Woonbase-Populatie-Woonruimten.txt")
)

# Run once — spine is cached across calls
woonbase_init(year = 2023, n = 1000, seed = 1)

for (key in names(file_map)) {
  info     <- file_map[[key]]
  txt_path <- file.path(pdf_dir, info$txt)

  cat("\n", strrep("=", 60), "\n")
  cat(" ", key, " (", info$file, ")\n", sep = "")
  cat(strrep("=", 60), "\n")

  res <- cbs_check_columns(file = info$file, txt_path = txt_path)

  cat("  Matched:        ", length(res$match), "\n")
  cat("  Missing (PDF):  ", length(res$missing), "\n")
  cat("  Extra (sim):    ", length(res$extra), "\n")
  cat("  Case mismatch:  ", nrow(res$case_mismatch), "\n")

  if (length(res$missing) > 0L) {
    cat("\n  Missing from simulator:\n")
    for (m in res$missing) cat("    - ", m, "\n")
  }
  if (length(res$extra) > 0L) {
    cat("\n  Extra in simulator:\n")
    for (e in res$extra) cat("    - ", e, "\n")
  }
  if (nrow(res$case_mismatch) > 0L) {
    cat("\n  Case mismatches (simulated -> pdf):\n")
    for (i in seq_len(nrow(res$case_mismatch))) {
      cat("    - ", res$case_mismatch$simulated[i], " -> ",
          res$case_mismatch$pdf[i], "\n")
    }
  }
}

cat("\n\nDone.\n")
