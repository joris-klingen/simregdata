# Fetch CBS StatLine data and write to params.yaml and gem_weights.csv

Queries CBS StatLine via `cbsodataR` for population and household counts
for the requested years, and writes the results to:

- `params.yaml` — n_persons, n_hh, typhh_p per year

- `gem_weights.csv` — gemeente population weights per year

- `woz_means.csv` — mean WOZ value per gemeente per year

- `housing_gem.csv` — apartment share and owner-occupied share per
  gemeente per year (from table 71446ned)

Run once (or whenever CBS publishes new data) to refresh the parameters.

## Usage

``` r
woonbase_update_params(
  years = 2016:2024,
  config_dir = dirname(.wb_annual_yaml())
)
```

## Arguments

- years:

  Integer vector of years to fetch (default `2016:2024`).

- config_dir:

  Directory to write files into. Defaults to the package's bundled
  `inst/config/` (useful during development).

## Value

Invisibly, the full annual parameter list.
