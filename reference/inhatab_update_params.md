# Fetch CBS StatLine household income data and write INHATAB params.yaml

Queries StatLine table `83932NED` (Inkomen huishoudens; inkomensklassen)
for the mean and median household income per income concept (primary,
gross, disposable, standardised) and household type. The simulator draws
household income from these (see `.simulate_hh_income()`), which feeds
both woonbase (`BESTINKH1JAN` etc.) and INHATAB.

## Usage

``` r
inhatab_update_params(years = 2011:2024, config_dir = .dataset_dir("inhatab"))
```

## Arguments

- years:

  Integer vector of years to fetch (default `2011:2024`).

- config_dir:

  Directory to write params.yaml into.

## Value

Invisibly, the full parameter list.
