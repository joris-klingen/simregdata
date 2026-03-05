# Generate docs/column-overview.md from sim_column_overview()
# Run: Rscript analysis/generate_column_overview.R

devtools::load_all()

dt <- sim_column_overview()

# --- Build markdown ---
lines <- character()
add <- function(...) lines <<- c(lines, paste0(...))

add("# Column Overview")
add("")
add("Auto-generated overview of all simulated columns, their calibration level, and data source.")
add("")
add("Generated: ", Sys.Date())
add("")

# Summary table
add("## Summary by calibration level")
add("")
lev_counts <- sort(table(dt$level), decreasing = TRUE)
add("| Level | Count |")
add("|-------|------:|")
for (lv in names(lev_counts)) {
  add("| ", lv, " | ", lev_counts[[lv]], " |")
}
add("")
add("**Total columns:** ", nrow(dt))
add("")

# Per-dataset sections
for (ds in unique(dt$dataset)) {
  ds_dt <- dt[dt$dataset == ds, ]
  add("## ", ds)
  add("")

  for (fkey in unique(ds_dt$file)) {
    file_dt <- ds_dt[ds_dt$file == fkey, ]
    add("### ", fkey)
    add("")
    add("| Column | Level | Source |")
    add("|--------|-------|--------|")
    for (i in seq_len(nrow(file_dt))) {
      r <- file_dt[i, ]
      add("| `", r$column, "` | ", r$level, " | ", r$source, " |")
    }
    add("")
  }
}

# Write
outpath <- "docs/column-overview.md"
writeLines(lines, outpath)
cat(sprintf("Written %s (%d lines, %d columns)\n", outpath, length(lines), nrow(dt)))
