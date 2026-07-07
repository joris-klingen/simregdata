# CBS variable documentation

Source PDFs downloaded from the CBS microdata catalog
(<https://www.cbs.nl/nl-nl/onze-diensten/maatwerk-en-microdata/microdata-zelf-onderzoek-doen/microdatabestanden>).

## Structure

```
docs/
├── cbs-catalogs.yaml              # PDF source URLs (tracked in git)
├── download_pdfs.R                # Downloads PDFs from the YAML
├── extract_pdfs.R                 # Extracts full text + column metadata from PDFs
├── column-overview.md             # Generated overview of all simulated columns
├── cbs-variable-reference.md      # Hand-written CBS variable reference notes
├── implementation-plan-tier1-2.md # Design notes / implementation plan
├── cbs-catalogs/                  # Downloaded PDFs (gitignored)
│   ├── woonbase/                  # 9 files
│   ├── rdw/                       # 2 files
│   ├── spolis/                    # 1 file
│   ├── vehtab/                    # 1 file
│   └── energieverbruik/           # 1 file
└── extracted/                     # Extracted output (gitignored)
    ├── full_text/{dataset}/       # Plain text per PDF (one .txt per .pdf)
    └── meta/                      # Column metadata CSVs (volgnr, naam, formaat)
```

## Downloading PDFs

The PDFs are not stored in git. Download them with:

```r
source("docs/download_pdfs.R")
```

## Extracting text and metadata

After downloading PDFs, extract full text and column metadata:

```r
source("docs/extract_pdfs.R")
```

This produces:
- `extracted/full_text/{dataset}/{file}.txt` — full text from each PDF
- `extracted/meta/{file}.csv` — column metadata table (volgnr, naam, formaat)

The meta CSVs are useful for manually checking how the PDFs are parsed and
comparing against the simulated column specs.

## How these are used

The `cbs_scaffold_dataset()` function reads extracted text to auto-generate
skeleton YAML column configs for new datasets. See `R/scaffold.R`.

The `cbs_parse_pdf_columns()` function (in `R/validate.R`) parses the
"Bestandsopbouw" column table from extracted text files.
