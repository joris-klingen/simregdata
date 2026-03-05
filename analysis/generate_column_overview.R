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
file_order <- list()  # dataset -> ordered file keys (from manifest)

for (dpath in datasets) {
  mf <- file.path(dpath, "manifest.yaml")
  if (!file.exists(mf)) next
  manifest <- yaml::read_yaml(mf)
  ds_id <- manifest$dataset_id
  ds_labels[[ds_id]] <- manifest$label %||% ds_id
  if (!is.null(manifest$files)) {
    file_order[[ds_id]] <- names(manifest$files)
    for (fkey in names(manifest$files)) {
      fi <- manifest$files[[fkey]]
      cbs_name <- fi$cbs_name %||% fkey
      tab <- if (isTRUE(fi$tab_suffix) && !grepl("TAB$", toupper(cbs_name))) "TAB" else ""
      display_name <- paste0(cbs_name, tab)
      cbs_names[[ds_id]][[fkey]] <- display_name
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

# Per-dataset sections (files are collapsible, dataset headers are not)
for (ds in unique(dt$dataset)) {
  ds_dt <- dt[dt$dataset == ds, ]
  ds_label <- ds_labels[[ds]] %||% ds

  add("## ", ds_label)
  add("")

  fkeys <- file_order[[ds]] %||% unique(ds_dt$file)
  for (fkey in fkeys) {
    file_dt <- ds_dt[ds_dt$file == fkey, ]
    cbs_name <- cbs_names[[ds]][[fkey]] %||% fkey

    add("<details>")
    add(sprintf("<summary><code>%s</code></summary>", cbs_name))
    add("")
    add("| Column | Source | Spatial | Codelist |")
    add("|--------|--------|---------|----------|")
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
      # Combine level + source into a single description
      src_cell <- switch(r$level,
        "spine-derived"       = "spine-derived",
        "computed"            = "computed",
        "statline-calibrated" = r$source,
        "constant"            = r$source,
        "random-id"           = r$source,
        "random-normal"       = paste0("random: ", r$source),
        "random-uniform"      = paste0("random: ", r$source),
        "random-categorical"  = paste0("random: ", r$source),
        r$source
      )
      add("| `", r$column, "` | ", src_cell, " | ", sp_cell, " | ", cl_cell, " |")
    }
    add("")
    add("</details>")
    add("")
  }
}

# Write
outpath <- "docs/column-overview.md"
writeLines(lines, outpath)
cat(sprintf("Written %s (%d lines, %d columns)\n", outpath, length(lines), nrow(dt)))
