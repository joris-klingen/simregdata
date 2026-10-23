# Fetch CBS StatLine data and write SPOLIS params.yaml

Queries CBS StatLine for employment data:

- `81431NED` — Banen van werknemers; economische activiteit (SBI2008)
  (job counts, FT/PT ratio, sector breakdown)

## Usage

``` r
spolis_update_params(years = 2019:2025, config_dir = .dataset_dir("spolis"))
```

## Arguments

- years:

  Integer vector of years to fetch (default `2019:2025`).

- config_dir:

  Directory to write params.yaml into.

## Value

Invisibly, the full parameter list.
