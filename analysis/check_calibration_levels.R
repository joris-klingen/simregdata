# analysis/check_calibration_levels.R
#
# Audit calibration level of every column across all datasets.
# Identifies random-uniform, random-normal, and codelist-hardcoded columns
# that could potentially be calibrated against CBS StatLine.
# Run: Rscript analysis/check_calibration_levels.R

library(yaml)
library(data.table)

datasets <- c("woonbase", "rdw", "spolis", "vehtab", "energieverbruik", "gba")
base <- "inst/config/datasets"

audit <- list()
for (ds in datasets) {
  col_dir <- file.path(base, ds, "columns")
  if (!dir.exists(col_dir)) next
  for (f in list.files(col_dir, "\\.yaml$", full.names = TRUE)) {
    spec <- yaml::read_yaml(f)
    fkey <- tools::file_path_sans_ext(basename(f))
    for (col in spec$columns) {
      level <- if (!is.null(col$source) && grepl("^spine\\.", col$source)) {
        "spine-derived"
      } else if (!is.null(col$value) || !is.null(col$template)) {
        "constant"
      } else if (!is.null(col$random_categorical)) {
        rc <- col$random_categorical
        if (!is.null(rc$from_params)) "statline-calibrated"
        else "codelist-hardcoded"
      } else if (!is.null(col$random_numeric)) {
        rn <- col$random_numeric
        if (!is.null(rn$mean_from_params) || !is.null(rn$sd_from_params)) "statline-calibrated"
        else if (identical(rn$distribution, "uniform")) "random-uniform"
        else "random-normal"
      } else if (!is.null(col$random_id)) {
        "random-id"
      } else if (!is.null(col$source) && grepl("^computed\\.", col$source)) {
        "computed"
      } else {
        "other"
      }
      audit[[length(audit) + 1]] <- data.table(
        dataset = ds, file = fkey, column = col$name, level = level)
    }
  }
}

dt <- rbindlist(audit)


# Summary counts ----

cat("=== CALIBRATION LEVEL COUNTS ===\n\n")
print(dt[, .N, by = level][order(-N)])


# Random-uniform columns ----

cat("\n\n=== RANDOM-UNIFORM COLUMNS ===\n\n")
print(dt[level == "random-uniform", .(dataset, file, column)], row.names = FALSE)


# Random-normal columns ----

cat("\n\n=== RANDOM-NORMAL COLUMNS ===\n\n")
print(dt[level == "random-normal", .(dataset, file, column)], row.names = FALSE)


# Codelist-hardcoded columns ----

cat("\n\n=== CODELIST-HARDCODED COLUMNS ===\n\n")
print(dt[level == "codelist-hardcoded", .(dataset, file, column)], row.names = FALSE)
