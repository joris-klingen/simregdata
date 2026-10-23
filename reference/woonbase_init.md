# Pre-build the Woonbase spine and cache it for the session

Call this once before using
[`read_sav()`](https://joris-klingen.github.io/simregdata/reference/read_sav.md)
on Woonbase files. The spine (shared person / household / object
identifiers) is cached so that cross-file joins always succeed.

## Usage

``` r
woonbase_init(year = 2023L, n = NULL, seed = 42L)
```

## Arguments

- year:

  Simulation year (default 2023).

- n:

  Number of persons to generate. `NULL` (the default) fetches the actual
  Dutch population count from the bundled YAML for `year`.

- seed:

  RNG seed for reproducibility (default 42).

## Value

Invisibly `NULL`.
