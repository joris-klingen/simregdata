# Set or clear the parquet data root

When a data root is set,
[`read_sav()`](https://joris-klingen.github.io/simregdata/reference/read_sav.md)
looks for pre-exported parquet files before generating data on-the-fly.
Use
[`sim_export()`](https://joris-klingen.github.io/simregdata/reference/sim_export.md)
to create the parquet files.

## Usage

``` r
sim_set_data_root(path)

sim_get_data_root()
```

## Arguments

- path:

  Directory containing exported parquet files (CBS VM-style layout), or
  `NULL` to revert to on-the-fly generation.

## Value

Invisibly, the previous data root (or `NULL`).

The current data root path, or `NULL` if not set.
