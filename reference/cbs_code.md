# Extract CBS character codes from a haven-labelled column

Converts a haven-labelled integer vector back to the original CBS
character codes (e.g. `"1"`, `"A"`, `"B"` for BRANDSTCODECORVRTG). The
reverse mapping is stored as the `"cbs_codes"` attribute by
[`read_sav()`](https://joris-klingen.github.io/simregdata/reference/read_sav.md)
/
[`sim_init()`](https://joris-klingen.github.io/simregdata/reference/sim_init.md).

## Usage

``` r
cbs_code(x)
```

## Arguments

- x:

  A haven-labelled vector (as produced by
  [`read_sav()`](https://joris-klingen.github.io/simregdata/reference/read_sav.md)).

## Value

A character vector of CBS codes.
