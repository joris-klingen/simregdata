# Scan R scripts for CBS column usage

Parses R scripts and extracts column names from
[`read_sav()`](https://joris-klingen.github.io/simregdata/reference/read_sav.md)
calls that use `col_select`. Returns a named list suitable for passing
to
[`sim_export()`](https://joris-klingen.github.io/simregdata/reference/sim_export.md)'s
`col_select` parameter.

## Usage

``` r
sim_scan_columns(paths)
```

## Arguments

- paths:

  Character vector of file or directory paths. Directories are searched
  recursively for `.R` files.

## Value

A named list of character vectors, keyed by uppercase CBS file name
(e.g. `list(SPOLISBUS = c("RINPERSOON", "IKVID", ...))`.

## Examples

``` r
if (FALSE) { # \dontrun{
cols <- sim_scan_columns("my_project/scripts/")
sim_export("output", dataset = "spolis", col_select = cols)
} # }
```
