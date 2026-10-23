# Fetch CBS Kerncijfers wijken en buurten and update energieverbruik params.yaml

Queries CBS StatLine "Kerncijfers wijken en buurten" tables for national
averages of gas consumption, electricity consumption, district heating
share, and dwelling count. The table ID changes each year.

## Usage

``` r
energieverbruik_update_params(
  years = 2017:2023,
  config_dir = .dataset_dir("energieverbruik")
)
```

## Arguments

- years:

  Integer vector of years to fetch (default `2017:2023`).

- config_dir:

  Directory to write params.yaml into.

## Value

Invisibly, the full parameter list.
