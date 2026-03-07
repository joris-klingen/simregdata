# Project Instructions

## Adding new datasets

When a new dataset is added (new config under `inst/config/datasets/`), always also:

1. **Regenerate column overview**: Run `Rscript analysis/generate_column_overview.R` to update `docs/column-overview.md`
2. **Update README.md**: Add the new dataset to the dataset table in the "Supported datasets" section, and update the column count
3. **Add StatLine table ID** (if applicable) to the `statline_tables` list in `R/column_overview.R`
4. **Add tests**: Add file name parsing + data generation tests to `tests/testthat/test-new-datasets.R`
5. **Add cross-dataset test**: If the dataset links to others, add a join test to `analysis/test_cross_datasets.R`
