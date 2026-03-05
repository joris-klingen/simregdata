# Generate docs/column-overview.md from sim_column_overview()
# Run: Rscript analysis/generate_column_overview.R

devtools::load_all()

dt <- sim_column_overview()

# --- Load manifest files to get full CBS names per file key ---
base <- system.file("config/datasets", package = "simcbsradata")
if (!nzchar(base)) base <- "inst/config/datasets"

datasets <- list.dirs(base, recursive = FALSE, full.names = TRUE)
cbs_names <- list()   # dataset -> file_key -> cbs_name
ds_labels <- list()   # dataset -> label

for (dpath in datasets) {
  mf <- file.path(dpath, "manifest.yaml")
  if (!file.exists(mf)) next
  manifest <- yaml::read_yaml(mf)
  ds_id <- manifest$dataset_id
  ds_labels[[ds_id]] <- manifest$label %||% ds_id
  if (!is.null(manifest$files)) {
    for (fkey in names(manifest$files)) {
      cbs_names[[ds_id]][[fkey]] <- manifest$files[[fkey]]$cbs_name %||% fkey
    }
  }
}

# GitHub base URL for codelist links
gh_base <- "https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets"

# --- Build markdown ---
lines <- character()
add <- function(...) lines <<- c(lines, paste0(...))

add("# Column Overview")
add("")
add("Overview of all simulated columns")
add("")

# Per-dataset sections (collapsible)
for (ds in unique(dt$dataset)) {
  ds_dt <- dt[dt$dataset == ds, ]
  n_cols <- nrow(ds_dt)
  n_files <- length(unique(ds_dt$file))
  n_cal <- sum(ds_dt$level == "statline-calibrated")
  ds_label <- ds_labels[[ds]] %||% ds

  add("<details>")
  add(sprintf("<summary><strong>%s</strong> — %d columns across %d files (%d statline-calibrated)</summary>",
              ds_label, n_cols, n_files, n_cal))
  add("")

  for (fkey in unique(ds_dt$file)) {
    file_dt <- ds_dt[ds_dt$file == fkey, ]
    cbs_name <- cbs_names[[ds]][[fkey]] %||% fkey
    n_fcols <- nrow(file_dt)
    n_fcal <- sum(file_dt$level == "statline-calibrated")

    add("<details>")
    add(sprintf("<summary><code>%s</code> — %d columns (%d statline-calibrated)</summary>",
                cbs_name, n_fcols, n_fcal))
    add("")
    add("| Column | Level | Spatial | Source | Codelist |")
    add("|--------|-------|---------|--------|----------|")
    for (i in seq_len(nrow(file_dt))) {
      r <- file_dt[i, ]
      # Build codelist link if applicable
      cl <- r$codelist
      if (!is.na(cl) && nzchar(cl)) {
        cl_url <- sprintf("%s/%s/codelists.yaml", gh_base, ds)
        cl_cell <- sprintf("[%s](%s)", cl, cl_url)
      } else {
        cl_cell <- ""
      }
      sp_cell <- if (!is.na(r$spatial)) r$spatial else ""
      add("| `", r$column, "` | ", r$level, " | ", sp_cell, " | ", r$source, " | ", cl_cell, " |")
    }
    add("")
    add("</details>")
    add("")
  }

  add("</details>")
  add("")
}

# Write
outpath <- "docs/column-overview.md"
writeLines(lines, outpath)
cat(sprintf("Written %s (%d lines, %d columns)\n", outpath, length(lines), nrow(dt)))
