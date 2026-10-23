# Package index

## Simulate and read

- [`read_sav()`](https://joris-klingen.github.io/simregdata/reference/read_sav.md)
  : Read a CBS file (synthetic) or any other .sav file (via haven)
- [`sim_init()`](https://joris-klingen.github.io/simregdata/reference/sim_init.md)
  : Initialize a dataset spine and cache it for the session
- [`sim_reset()`](https://joris-klingen.github.io/simregdata/reference/sim_reset.md)
  [`woonbase_reset()`](https://joris-klingen.github.io/simregdata/reference/sim_reset.md)
  : Clear the cached spine
- [`sim_catalog()`](https://joris-klingen.github.io/simregdata/reference/sim_catalog.md)
  [`woonbase_catalog()`](https://joris-klingen.github.io/simregdata/reference/sim_catalog.md)
  : Print a catalog of available synthetic datasets and files
- [`cbs_code()`](https://joris-klingen.github.io/simregdata/reference/cbs_code.md)
  : Extract CBS character codes from a haven-labelled column

## Export

- [`sim_population()`](https://joris-klingen.github.io/simregdata/reference/sim_population.md)
  : Generate a fractional sample of all datasets
- [`sim_export()`](https://joris-klingen.github.io/simregdata/reference/sim_export.md)
  : Export simulated datasets to parquet files
- [`sim_set_data_root()`](https://joris-klingen.github.io/simregdata/reference/sim_set_data_root.md)
  [`sim_get_data_root()`](https://joris-klingen.github.io/simregdata/reference/sim_set_data_root.md)
  : Set or clear the parquet data root
- [`sim_scan_columns()`](https://joris-klingen.github.io/simregdata/reference/sim_scan_columns.md)
  : Scan R scripts for CBS column usage

## Custom datasets

- [`sim_create_custom()`](https://joris-klingen.github.io/simregdata/reference/sim_create_custom.md)
  : Create a custom dataset template YAML
- [`sim_register()`](https://joris-klingen.github.io/simregdata/reference/sim_register.md)
  : Register a custom dataset from a simple YAML file
- [`sim_column_overview()`](https://joris-klingen.github.io/simregdata/reference/sim_column_overview.md)
  : Column overview with calibration levels

## Woonbase

- [`sim_catalog()`](https://joris-klingen.github.io/simregdata/reference/sim_catalog.md)
  [`woonbase_catalog()`](https://joris-klingen.github.io/simregdata/reference/sim_catalog.md)
  : Print a catalog of available synthetic datasets and files
- [`sim_reset()`](https://joris-klingen.github.io/simregdata/reference/sim_reset.md)
  [`woonbase_reset()`](https://joris-klingen.github.io/simregdata/reference/sim_reset.md)
  : Clear the cached spine
- [`woonbase_cbs_params()`](https://joris-klingen.github.io/simregdata/reference/woonbase_cbs_params.md)
  : Load CBS population parameters for a given year
- [`woonbase_init()`](https://joris-klingen.github.io/simregdata/reference/woonbase_init.md)
  : Pre-build the Woonbase spine and cache it for the session
- [`woonbase_update_params()`](https://joris-klingen.github.io/simregdata/reference/woonbase_update_params.md)
  : Fetch CBS StatLine data and write to params.yaml and gem_weights.csv

## StatLine parameters

Load the bundled parameters, or refresh them from StatLine.

- [`energieverbruik_cbs_params()`](https://joris-klingen.github.io/simregdata/reference/energieverbruik_cbs_params.md)
  : Load cached ENERGIEVERBRUIKTAB parameters for a given year
- [`inhatab_cbs_params()`](https://joris-klingen.github.io/simregdata/reference/inhatab_cbs_params.md)
  : Load cached household income parameters for a given year
- [`rdw_cbs_params()`](https://joris-klingen.github.io/simregdata/reference/rdw_cbs_params.md)
  : Load cached RDW parameters for a given year
- [`spolis_cbs_params()`](https://joris-klingen.github.io/simregdata/reference/spolis_cbs_params.md)
  : Load cached SPOLIS parameters for a given year
- [`vehtab_cbs_params()`](https://joris-klingen.github.io/simregdata/reference/vehtab_cbs_params.md)
  : Load cached VEHTAB parameters for a given year
- [`woonbase_cbs_params()`](https://joris-klingen.github.io/simregdata/reference/woonbase_cbs_params.md)
  : Load CBS population parameters for a given year
- [`energieverbruik_update_params()`](https://joris-klingen.github.io/simregdata/reference/energieverbruik_update_params.md)
  : Fetch CBS Kerncijfers wijken en buurten and update energieverbruik
  params.yaml
- [`inhatab_update_params()`](https://joris-klingen.github.io/simregdata/reference/inhatab_update_params.md)
  : Fetch CBS StatLine household income data and write INHATAB
  params.yaml
- [`rdw_update_params()`](https://joris-klingen.github.io/simregdata/reference/rdw_update_params.md)
  : Fetch CBS StatLine data and write RDW params.yaml
- [`spolis_update_params()`](https://joris-klingen.github.io/simregdata/reference/spolis_update_params.md)
  : Fetch CBS StatLine data and write SPOLIS params.yaml
- [`vehtab_update_params()`](https://joris-klingen.github.io/simregdata/reference/vehtab_update_params.md)
  : Fetch CBS StatLine wealth data and write VEHTAB params.yaml
- [`woonbase_update_params()`](https://joris-klingen.github.io/simregdata/reference/woonbase_update_params.md)
  : Fetch CBS StatLine data and write to params.yaml and gem_weights.csv
- [`energieverbruik_update_structure()`](https://joris-klingen.github.io/simregdata/reference/energieverbruik_update_structure.md)
  : Fetch the dwelling-level energy structure from StatLine

## Building new datasets

Tools for transcribing CBS variable documentation.

- [`cbs_check_columns()`](https://joris-klingen.github.io/simregdata/reference/cbs_check_columns.md)
  : Compare simulated columns against CBS PDF documentation
- [`cbs_parse_pdf_columns()`](https://joris-klingen.github.io/simregdata/reference/cbs_parse_pdf_columns.md)
  : Parse column definitions from extracted CBS PDF text
- [`cbs_scaffold_dataset()`](https://joris-klingen.github.io/simregdata/reference/cbs_scaffold_dataset.md)
  : Scaffold a new dataset from CBS PDF documentation
