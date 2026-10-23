# Generate a fractional sample of all datasets

Convenience wrapper around
[`sim_export()`](https://joris-klingen.github.io/simregdata/reference/sim_export.md)
that generates a percentage of the full CBS population for all datasets
and writes parquet files in CBS VM-style folder layout. Supports
multiple years in a single call.

## Usage

``` r
sim_population(
  output_dir,
  fraction = 0.01,
  years = 2023L,
  seed = 42L,
  include_network = FALSE,
  datasets = NULL,
  col_select = NULL,
  force_resim = FALSE,
  verbose = TRUE
)
```

## Arguments

- output_dir:

  Directory to write parquet files into.

- fraction:

  Fraction of the full population to simulate (default 0.01 = 1%). Must
  be between 0 (exclusive) and 1 (inclusive).

- years:

  Integer vector of simulation years (default 2023).

- seed:

  RNG seed for reproducibility (default 42).

- include_network:

  Logical; include network datasets (buren, collega, familie)? Default
  `FALSE`.

- datasets:

  Optional character vector of dataset identifiers to include (e.g.
  `c("woonbase", "rdw")`). Default `NULL` exports all registered
  datasets. Takes precedence over `include_network`.

- col_select:

  Optional named list passed to
  [`sim_export()`](https://joris-klingen.github.io/simregdata/reference/sim_export.md).
  Keys are CBS file names (e.g. `"WoonbasePopulatiePersonen"`,
  `"RDWNPACT"`) and values are character vectors of column names. Key
  columns (RINPERSOON etc.) are always included automatically.

- force_resim:

  Logical; if `TRUE`, wipe the output directory and regenerate
  everything from scratch. Default `FALSE` skips files that are already
  present in `.sim_meta.yaml` with matching columns, `n`, and `seed`.

- verbose:

  Print progress summary (default `TRUE`).

## Value

Invisibly, `output_dir`.

## Details

Network datasets (buren, collega, familie) are excluded by default
because they produce O(n \* relations_per_person) rows and can be very
large.
