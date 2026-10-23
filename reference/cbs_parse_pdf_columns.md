# Parse column definitions from extracted CBS PDF text

Reads the "Bestandsopbouw" variable table from an extracted CBS PDF text
file and returns a data.frame of variable definitions.

## Usage

``` r
cbs_parse_pdf_columns(txt_path)
```

## Arguments

- txt_path:

  Path to an extracted PDF text file.

## Value

A data.frame with columns `volgnr` (integer), `naam` (character), and
`formaat` (character).
