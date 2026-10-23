# Column overview with calibration levels

Scans all column YAML specs across registered datasets and returns a
`data.table` describing each column's calibration level and data source.

## Usage

``` r
sim_column_overview()
```

## Value

A `data.table` with columns:

- dataset:

  Dataset identifier (e.g. `"woonbase"`, `"rdw"`)

- file:

  File type key (e.g. `"kenmerken_pers"`, `"kentekens"`)

- column:

  Column name (suffixed columns are expanded, e.g.
  `"AGHT1Jan, AGHT31Dec"`)

- level:

  Calibration level: `"statline-calibrated"`, `"spine-derived"`,
  `"random-categorical"`, `"random-normal"`, `"random-uniform"`,
  `"constant"`, `"random-id"`, `"computed"`

- source:

  Human-readable source description, e.g.
  `"params: loon_mean (81431NED)"` or `"spine.pers.RINPERSOON"`

- codelist:

  Codelist name if applicable, `NA` otherwise

- spatial:

  Spatial calibration level: `"gemeente"`, `"NL"`, or `NA`
