# Download CBS microdata documentation PDFs from cbs-catalogs.yaml
#
# Run: Rscript docs/download_pdfs.R

catalog <- yaml::read_yaml("docs/cbs-catalogs.yaml")
out_dir <- "docs/cbs-catalogs"

n <- 0L
for (ds in names(catalog)) {
  for (entry in catalog[[ds]]) {
    dest <- file.path(out_dir, entry$file)
    if (file.exists(dest)) {
      cat(sprintf("  skip: %s (exists)\n", entry$file))
      next
    }
    dir.create(dirname(dest), recursive = TRUE, showWarnings = FALSE)
    cat(sprintf("  download: %s\n", entry$file))
    tryCatch(
      download.file(entry$url, dest, mode = "wb", quiet = TRUE),
      error = function(e) cat(sprintf("  FAILED: %s\n", conditionMessage(e)))
    )
    n <- n + 1L
  }
}
cat(sprintf("Done. Downloaded %d new PDFs to %s/\n", n, out_dir))
