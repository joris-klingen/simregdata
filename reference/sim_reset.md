# Clear the cached spine

Forces a rebuild on the next
[`read_sav()`](https://joris-klingen.github.io/simregdata/reference/read_sav.md)
call.

## Usage

``` r
sim_reset(dataset = NULL)

woonbase_reset()
```

## Arguments

- dataset:

  Dataset to reset (default `NULL` resets all).

## Value

Invisibly `NULL`.
