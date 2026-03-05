# CBS variable documentation

Source PDFs downloaded from the CBS microdata catalog
(<https://www.cbs.nl/nl-nl/onze-diensten/maatwerk-en-microdata/microdata-zelf-onderzoek-doen/microdatabestanden>).

## Structure

```
docs/
├── cbs-catalogs.yaml     # PDF source URLs (tracked in git)
├── download_pdfs.R       # Downloads PDFs listed in the YAML
├── cbs-catalogs/         # Downloaded PDFs (gitignored)
│   ├── woonbase/         # 9 files
│   ├── rdw/              # 2 files
│   ├── spolis/           # 1 file
│   ├── vehtab/           # 1 file
│   └── energieverbruik/  # 1 file
└── extracted/            # Plain-text extractions (gitignored, regenerate on demand)
```

## Downloading PDFs

The PDFs are not stored in git. Download them with:

```r
source("docs/download_pdfs.R")
```

This reads `cbs-catalogs.yaml` and downloads any missing PDFs to `docs/cbs-catalogs/`.

## Extracting text from PDFs

The extracted `.txt` files are not checked into git. Regenerate them with
`pdftools` in R:

```r
library(pdftools)
for (pdf in list.files("docs/cbs-catalogs", "\\.pdf$", recursive = TRUE, full.names = TRUE)) {
  out <- file.path("docs/extracted",
                   dirname(sub("^docs/cbs-catalogs/", "", pdf)),
                   sub("\\.pdf$", ".txt", basename(pdf)))
  dir.create(dirname(out), recursive = TRUE, showWarnings = FALSE)
  writeLines(pdf_text(pdf), out)
}
```

## How these are used

The `cbs_scaffold_dataset()` function reads extracted text to auto-generate
skeleton YAML column configs for new datasets. See `R/scaffold.R`.
