# Load cached household income parameters for a given year

Reads the mean and median household income per income concept and
household type from `inst/config/datasets/inhatab/params.yaml` (StatLine
83932NED). Years outside the table use the nearest year.

## Usage

``` r
inhatab_cbs_params(year = 2023L)
```

## Arguments

- year:

  Integer year (default 2023).

## Value

A named list (one element per household type) of named lists (one per
income concept) with `mean` and `median` in euro.
