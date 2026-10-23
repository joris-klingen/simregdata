# Load CBS population parameters for a given year

Reads year-specific aggregate parameters (n_persons, n_hh, typhh_p) from
`params.yaml` and municipality weights from `gem_weights.csv`. Fixed
distributions (eigenaar, woningtype, bouwjaar, etc.) are appended from
internal defaults.

## Usage

``` r
woonbase_cbs_params(year = 2023L)
```

## Arguments

- year:

  Integer year (default 2023).

## Value

A named list of population parameters.

## Details

If the requested year is missing from the YAML, the nearest available
year is used with a warning.
