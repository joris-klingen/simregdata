# Fetch CBS StatLine data and write RDW params.yaml

Queries CBS StatLine for vehicle stock and traffic performance data:

- `85237NED` — Personenauto's actief; voertuigkenmerken (fuel, color,
  weight, construction year)

- `85236NED` — Motorvoertuigen actief; voertuigtype, regio (vehicle type
  breakdown, total vehicle count)

- `85404NED` — Verkeersprestaties personenauto's; km, brandstof (average
  annual mileage)

## Usage

``` r
rdw_update_params(years = 2019:2025, config_dir = .dataset_dir("rdw"))
```

## Arguments

- years:

  Integer vector of years to fetch (default `2019:2024`).

- config_dir:

  Directory to write params.yaml into.

## Value

Invisibly, the full parameter list.
