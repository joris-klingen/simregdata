# Initialize a dataset spine and cache it for the session

Builds the shared person/household/object spine (if not already cached)
and prepares dataset-specific state so that subsequent
[`read_sav()`](https://joris-klingen.github.io/simregdata/reference/read_sav.md)
calls can assemble files without rebuilding.

## Usage

``` r
sim_init(dataset = "woonbase", year = 2023L, n = NULL, seed = 42L)
```

## Arguments

- dataset:

  Dataset identifier (default `"woonbase"`).

- year:

  Simulation year (default 2023).

- n:

  Number of persons to generate. `NULL` (the default) fetches the actual
  population count from bundled parameters for `year`. Note that `n` and
  `seed` only take effect when the shared spine is (re)built; if a spine
  for `year` is already cached, the existing spine (with its original
  `n`/`seed`) is reused. Call
  [`sim_reset()`](https://joris-klingen.github.io/simregdata/reference/sim_reset.md)
  first to force a rebuild with a different `n` or `seed`.

- seed:

  RNG seed for reproducibility (default 42).

## Value

Invisibly `NULL`.

## Details

The spine is shared across all datasets. Calling `sim_init()` for any
dataset auto-builds the spine from woonbase parameters when needed.
