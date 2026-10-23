# Register a custom dataset from a simple YAML file

Reads a single YAML file defining a custom dataset and registers it so
that
[`sim_init()`](https://joris-klingen.github.io/simregdata/reference/sim_init.md),
[`read_sav()`](https://joris-klingen.github.io/simregdata/reference/read_sav.md),
[`sim_catalog()`](https://joris-klingen.github.io/simregdata/reference/sim_catalog.md),
and
[`sim_population()`](https://joris-klingen.github.io/simregdata/reference/sim_population.md)
can use it. The dataset links to the shared population spine via a key
column (RINPERSOON, HUISHOUDNR, RINOBJECTNUMMER, or RINKENTEKEN).

## Usage

``` r
sim_register(path)
```

## Arguments

- path:

  Path to the custom dataset YAML file.

## Value

Invisibly, the dataset name.

## Details

Calling `sim_register()` again with the same name silently overwrites
the previous registration. Note that
[`sim_reset()`](https://joris-klingen.github.io/simregdata/reference/sim_reset.md)
clears all custom registrations.
