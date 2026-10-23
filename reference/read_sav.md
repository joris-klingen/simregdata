# Read a CBS file (synthetic) or any other .sav file (via haven)

Drop-in replacement for
[`haven::read_sav()`](https://haven.tidyverse.org/reference/read_spss.html)
that intercepts registered CBS dataset file names and returns synthetic
microdata. For all other file paths, falls through to
[`haven::read_sav()`](https://haven.tidyverse.org/reference/read_spss.html).

## Usage

``` r
read_sav(
  file,
  encoding = NULL,
  user_na = FALSE,
  col_select = NULL,
  skip = 0L,
  n_max = Inf,
  .name_repair = "unique",
  year = 2023L,
  seed = 42L,
  ...
)
```

## Arguments

- file:

  File name or path. For simulated files, use the exact CBS CamelCase
  name (e.g. `"WoonbasePopulatiePersonen2023V1"`).

- encoding:

  Passed to
  [`haven::read_sav()`](https://haven.tidyverse.org/reference/read_spss.html)
  (non-simulated files only).

- user_na:

  Passed to
  [`haven::read_sav()`](https://haven.tidyverse.org/reference/read_spss.html)
  (non-simulated files only).

- col_select:

  Column selection (tidyselect expressions or character vector).

- skip:

  Number of rows to skip (default 0).

- n_max:

  Maximum number of rows to return (default `Inf`).

- .name_repair:

  Column-name repair. For non-simulated files this is passed to
  [`haven::read_sav()`](https://haven.tidyverse.org/reference/read_spss.html).
  For simulated files (and parquet reads) it is applied only when it is
  a function (e.g. `~ make.unique(.x)`); string presets like `"unique"`
  are ignored because generated names are already unique.

- year:

  Simulation year used for auto-init (default 2023).

- seed:

  RNG seed used for auto-init (default 42).

- ...:

  Additional arguments passed to
  [`haven::read_sav()`](https://haven.tidyverse.org/reference/read_spss.html).

## Value

A tibble.
