# Export simulated datasets to parquet files

Generates synthetic data for one or all registered datasets and writes
each file as a parquet file in a CBS VM-style folder layout:
`output_dir/UPPERCASECBSNAME/CbsName{YYYY}V1.parquet`.

## Usage

``` r
sim_export(
  output_dir,
  dataset = NULL,
  year = 2023L,
  n = NULL,
  seed = 42L,
  col_select = NULL,
  force_resim = FALSE
)
```

## Arguments

- output_dir:

  Directory to write parquet files into.

- dataset:

  Dataset identifier, or `NULL` (default) to export all registered
  datasets.

- year:

  Simulation year (default 2023).

- n:

  Number of persons in the spine. `NULL` (default) uses the population
  count from bundled parameters.

- seed:

  RNG seed for reproducibility (default 42).

- col_select:

  Optional named list of character vectors specifying which columns to
  include per CBS file. Keys are CBS file names (e.g. `"SPOLISBUS"`) or
  file keys (e.g. `"spolisbus"`). Identity/join key columns (defined in
  each manifest's `key_columns`) are always included. Files not listed
  are skipped entirely. Default `NULL` exports all files with all
  columns.

- force_resim:

  Logical; if `TRUE`, regenerate all files regardless of what was
  previously simulated. Default `FALSE` skips files whose columns, `n`,
  and `seed` already match the `.sim_meta.yaml` in `output_dir`.

## Value

Invisibly, a list with elements `dir` (the output directory), `written`
(number of parquet files written) and `skipped` (number of files skipped
because they were already simulated).
