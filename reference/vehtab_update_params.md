# Fetch CBS StatLine wealth data and write VEHTAB params.yaml

Queries CBS StatLine table 83834NED (Vermogen van huishoudens;
huishoudenskenmerken) for calibrated mean wealth component values.
Standard deviations are estimated using empirical CV ratios appropriate
for the highly right-skewed wealth distribution.

## Usage

``` r
vehtab_update_params(years = 2006:2024, config_dir = .dataset_dir("vehtab"))
```

## Arguments

- years:

  Integer vector of years to fetch (default `2006:2024`).

- config_dir:

  Directory to write params.yaml into.

## Value

Invisibly, the full parameter list.
