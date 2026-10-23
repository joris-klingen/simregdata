# Scaffold a new dataset from CBS PDF documentation

Generates skeleton YAML config files (manifest, codelists, column specs)
for a new CBS dataset. Column definitions are extracted from PDF text
files via
[`cbs_parse_pdf_columns()`](https://joris-klingen.github.io/simregdata/reference/cbs_parse_pdf_columns.md).
Character columns get `random_categorical` stubs; numeric columns get
`random_numeric` stubs. Users then edit the generated YAML to refine
distributions and codelists.

## Usage

``` r
cbs_scaffold_dataset(
  dataset_id,
  label = dataset_id,
  files = list(),
  spine_builder = "generic",
  output_dir = NULL
)
```

## Arguments

- dataset_id:

  Short identifier for the dataset (e.g. `"voertuigen"`).

- label:

  Human-readable label (e.g. `"CBS Voertuigen"`).

- files:

  Named list of file definitions. Each element should be a list with:

  cbs_name

  :   CBS CamelCase dataset name

  entity

  :   Entity type: `"person"`, `"household"`, or `"object"`

  txt_path

  :   Path to extracted PDF text file (optional)

- spine_builder:

  Spine builder type: `"woonbase"` (reads directly from the shared
  population spine) or `"generic"` (samples persons from the shared
  spine). Default `"generic"`.

- output_dir:

  Base output directory. Defaults to `inst/config/datasets/{dataset_id}`
  in the package source.

## Value

Invisibly, the output directory path.
