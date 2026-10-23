# Compare simulated columns against CBS PDF documentation

Generates a small synthetic dataset for a Woonbase file type, parses the
corresponding CBS PDF documentation, and reports matches, missing
columns, extra columns, and case mismatches.

## Usage

``` r
cbs_check_columns(file, txt_path, year = 2023L, n = 1000L)
```

## Arguments

- file:

  CBS file name (e.g. `"WoonbaseSleutelbestand2023V1"`).

- txt_path:

  Path to the extracted PDF text file for this file type.

- year:

  Simulation year (default 2023).

- n:

  Number of rows to simulate (default 1000).

## Value

A list with elements `match`, `missing`, `extra`, and `case_mismatch`.
