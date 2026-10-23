# Project Instructions

## Adding new datasets

When a new dataset is added (new config under `inst/config/datasets/`), always also:

1. **Regenerate column overview**: run `Rscript dev/generate_column_overview.R` to update `vignettes/articles/column-overview.Rmd`
2. **Update README.md**: add the new dataset to the dataset table and update the column count
3. **Add StatLine table ID** (if applicable) to the `statline_tables` list in `R/column_overview.R`
4. **Add tests**: file name parsing + data generation tests in `tests/testthat/test-new-datasets.R`
5. **Add cross-dataset test**: if the dataset links to others, add its keys to `tests/testthat/test-cross-datasets.R`
6. **Provenance**: record the source of any new parameters in `vignettes/articles/provenance.Rmd`

## Documentation site

The pkgdown site (`_pkgdown.yml`) is built and deployed to GitHub Pages by
`.github/workflows/pkgdown.yaml`. Build locally with
`pkgdown::build_site()` (output in `docs/`, which is gitignored). The
`quality-*` vignettes fetch StatLine, so building them needs internet access.
