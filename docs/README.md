# CBS variable documentation

Source PDFs downloaded from the CBS microdata catalog
(<https://www.cbs.nl/nl-nl/onze-diensten/maatwerk-en-microdata/microdata-zelf-onderzoek-doen/microdatabestanden>).

## Structure

```
docs/
├── cbs-catalogs/          # Original PDFs (tracked in git)
│   ├── woonbase/
│   ├── rdw/
│   ├── spolis/
│   ├── vehtab/
│   └── energieverbruik/
└── extracted/             # Plain-text extractions (gitignored, regenerate on demand)
```

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

## PDF file names

PDF files keep their original download names from CBS and are not renamed.
Extracted text files mirror the PDF base name (with `.txt` extension).

## How these are used

The `cbs_scaffold_dataset()` function reads extracted text to auto-generate
skeleton YAML column configs for new datasets. See `R/scaffold.R`.
