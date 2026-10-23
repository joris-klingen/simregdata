# Extract text and column metadata from CBS documentation PDFs
#
# Reads dev/cbs-docs/cbs-catalogs.yaml, extracts full text and column metadata
# from each PDF, and writes to dev/cbs-docs/extracted/full_text/ and dev/cbs-docs/extracted/meta/.
#
# Requires: pdftools
# Run: Rscript dev/cbs-docs/extract_pdfs.R

if (!requireNamespace("pdftools", quietly = TRUE))
  stop("Install pdftools: install.packages('pdftools')")

catalog <- yaml::read_yaml("dev/cbs-dev/cbs-docs/cbs-catalogs.yaml")
devtools::load_all(".")

dir.create("dev/cbs-docs/extracted/full_text", recursive = TRUE, showWarnings = FALSE)
dir.create("dev/cbs-docs/extracted/meta", recursive = TRUE, showWarnings = FALSE)


# Full text extraction ----

cat("Extracting full text...\n")
for (ds in names(catalog)) {
  for (entry in catalog[[ds]]) {
    pdf_path <- file.path("dev/cbs-docs/pdf", entry$file)
    if (!file.exists(pdf_path)) {
      cat(sprintf("  SKIP (not found): %s\n", entry$file))
      next
    }
    out_dir <- file.path("dev/cbs-docs/extracted/full_text", ds)
    dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
    out_path <- file.path(out_dir, sub("\\.pdf$", ".txt", basename(entry$file)))
    txt <- pdftools::pdf_text(pdf_path)
    writeLines(txt, out_path)
    cat(sprintf("  %s (%d pages)\n", entry$file, length(txt)))
  }
}


# Column metadata extraction ----

cat("\nExtracting column metadata...\n")
for (ds in names(catalog)) {
  for (entry in catalog[[ds]]) {
    txt_path <- file.path("dev/cbs-docs/extracted/full_text", ds,
                          sub("\\.pdf$", ".txt", basename(entry$file)))
    if (!file.exists(txt_path)) next

    cols <- tryCatch(
      cbs_parse_pdf_columns(txt_path),
      error = function(e) NULL
    )

    if (is.null(cols) || nrow(cols) == 0L) {
      cat(sprintf("  SKIP (no column table found): %s\n", entry$file))
      next
    }

    csv_name <- sub("\\.pdf$", ".csv", basename(entry$file))
    csv_path <- file.path("dev/cbs-docs/extracted/meta", csv_name)
    write.csv(cols, csv_path, row.names = FALSE)
    cat(sprintf("  %s: %d columns\n", csv_name, nrow(cols)))
  }
}

cat("\nDone.\n")
