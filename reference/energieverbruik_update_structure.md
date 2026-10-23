# Fetch the dwelling-level energy structure from StatLine

Adds to `inst/config/datasets/energieverbruik/params.yaml`:

- from `81528NED` (all `years`): national mean gas (`gas_mean`) and
  electricity delivery (`elek_mean`) per dwelling;

- from `85140NED` (2019 onwards): a `structuur` block per year with the
  mean temperature-corrected gas use and electricity delivery, the share
  with solar panels and with district heating, per dwelling type,
  construction-year class, floor-area class and number of occupants, the
  national percentiles, and electricity delivery and net delivery for
  dwellings with and without solar panels.

The simulator draws gas and electricity per dwelling from this structure
(see `.build_energy()`).

## Usage

``` r
energieverbruik_update_structure(
  years = 2010:2025,
  config_dir = .dataset_dir("energieverbruik")
)
```

## Arguments

- years:

  Integer vector of years (default `2010:2025`).

- config_dir:

  Directory holding params.yaml.

## Value

Invisibly, the full parameter list.
