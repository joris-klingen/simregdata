# simcbsradata

Synthetic CBS microdata generator for R. Mimics the exact file structure, column names, value labels, and cross-file join keys of CBS registers — so analysis code written against this simulator runs unchanged on the real remote access data. Key variables are calibrated to publicly available CBS StatLine statistics, ensuring realistic marginal distributions for demographics, housing, vehicles, employment, wealth, and energy consumption.

## Background

[CBS microdata](https://www.cbs.nl/nl-nl/onze-diensten/maatwerk-en-microdata/microdata-zelf-onderzoek-doen "CBS microdata catalog") are linked administrative registers available to researchers via the CBS Remote Access environment. Because the real files are restricted, this project simulates them from the PDF variable documentation so that:

- Analysis scripts can be developed and tested locally
- Workflows can be benchmarked and profiled
- Colleagues without CBS access can reproduce results

Currently supports **15 datasets, 31 file types, 648 columns**. See the full [column overview](docs/column-overview.md) for all simulated columns with their source, spatial level, calibration links, and codelists.

## Installation

```r
# Install from GitHub
remotes::install_github("joris-klingen/simcbsradata")
```

## Supported datasets

Currently supports 15 CBS datasets across 31 file types:

| Dataset | Description | Key |
|---------|-------------|-----|
| **Woonbase** | Housing + population (13 files) | RINPERSOON, HUISHOUDNR, RINOBJECTNUMMER |
| **GBA** | Population register (3 files) | RINPERSOON |
| **RDW** | Vehicle registrations (2 files) | RINPERSOON, RINKENTEKEN |
| **SPOLIS** | Employment records with monthly job structure | RINPERSOON, SBEID |
| **VEHTAB** | Household wealth | RINPERSOONHKW |
| **INPATAB** | Personal income | RINPERSOON, RINPERSOONHKW |
| **INHATAB** | Household income | RINPERSOONHKW |
| **HOOGSTEOPLTAB** | Highest attained education level | RINPERSOON |
| **SECMBUS** | Socioeconomic category (monthly periods) | RINPERSOON |
| **BETAB** | Business register | BEID |
| **Energieverbruik** | Dwelling energy consumption (annual + monthly smart meter) | RINOBJECTNUMMER |
| **Zonnestroominstallaties** | Solar PV installations + monthly production | RINOBJECTNUMMER |
| **Burennetwerktab** | Neighbour network (neighbours + community members) | RINPERSOON |
| **Colleganetwerktab** | Colleague network (same employer) | RINPERSOON |
| **Familienetwerktab** | Family network (biological, in-law, step) | RINPERSOON |

All datasets share a common population spine with consistent join keys (RINPERSOON, HUISHOUDNR, RINOBJECTNUMMER, RINPERSOONHKW), so cross-file joins work exactly as on the real CBS Remote Access.

## Quick start

```r
library(simcbsradata)

# Build a woonbase spine for 2023 (100k persons takes ~2 s)
sim_init("woonbase", year = 2023, n = 100000, seed = 42)

# Read columns — works exactly like haven::read_sav() on the real CBS file,
# including haven::labelled columns that convert with as_factor()
dt <- read_sav(
  "WoonbasePopulatiePersonen2023V1",
  col_select = c(RINPERSOON, VBOWoningType1Jan, GBAGeboorteJaar1Jan)
)

# Full CBS VM path works too — year is inferred from the filename
dt <- read_sav(
  "G:/BOUWENENWONEN/WOONBASEPOPULATIEPERSONEN/WoonbasePopulatiePersonen2023V1.sav",
  col_select = c(RINPERSOON, VBOWoningType1Jan)
)

# Cross-file joins work because all files share the same spine IDs
library(data.table)  # for as.data.table() and join-by-reference below
dt_pers <- as.data.table(read_sav("WoonbasePopulatiePersonen2023V1",
                                   col_select = c(RINPERSOON, HUISHOUDNR1Jan,
                                                  VBOWoningType1Jan)))
dt_hh   <- as.data.table(read_sav("WoonbasePopulatieHuishoudens2023V1",
                                   col_select = c(HUISHOUDNR1Jan, TYPHH1Jan)))
dt_pers[dt_hh, on = "HUISHOUDNR1Jan", TYPHH1Jan := i.TYPHH1Jan]

# Initialize linked datasets (auto-builds shared spine if needed)
sim_init("rdw", year = 2023)
sim_init("spolis", year = 2023)

rdw  <- read_sav("RDWNPACT2023TABV1")
jobs <- read_sav("SPOLISBUS2023V1")

# Extract original CBS character codes from haven-labelled columns
cbs_code(rdw$BRANDSTCODECORVRTG)  # "1", "2", "4", "A", "B", ...

# See all available files
sim_catalog()

# Generate a 1% sample of specific datasets as parquet
sim_population("output/sim_data", datasets = c("woonbase", "rdw"))

# Multiple years at once
sim_population("output/sim_data", fraction = 0.01, years = 2019:2023)

# Use exported parquet files directly via read_sav()
sim_set_data_root("output/sim_data")
dt <- read_sav("WoonbasePopulatiePersonen2023V1")
```

## Custom datasets

Define your own datasets with a simple YAML file. Columns link to the shared spine via RINPERSOON, HUISHOUDNR, RINOBJECTNUMMER, or RINKENTEKEN.

```r
# Create a template
sim_create_custom("my_survey.yaml")

# Edit the YAML, then register it
sim_register("my_survey.yaml")

# Use it like any built-in dataset
sim_init("my_survey", year = 2023, n = 100000)
dt <- read_sav("my_survey2023V1")
```

## How the simulator works

### Public functions

| Function | Description |
|----------|-------------|
| `sim_population(output_dir, fraction, years, seed, datasets, col_select)` | Generates a fractional sample (default 1%) of all or selected datasets and exports to parquet. |
| `sim_init(dataset, year, n, seed)` | Builds the shared population spine and prepares dataset-specific state. |
| `read_sav(file, col_select, n_max, skip, ...)` | Drop-in replacement for `haven::read_sav()`. Returns synthetic data for registered CBS filenames; falls through to `haven::read_sav()` for unregistered paths. |
| `sim_export(output_dir, dataset, year, n, seed, col_select, force_resim)` | Exports simulated datasets to parquet in CBS VM-style folder layout. Skips files whose columns/`n`/`seed` already match the `.sim_meta.yaml` in `output_dir`; pass `force_resim = TRUE` to regenerate regardless. |
| `sim_set_data_root(path)` / `sim_get_data_root()` | Set/get a parquet data root so `read_sav()` reads pre-exported files instead of generating on-the-fly. |
| `sim_catalog(dataset, year)` | Prints all available synthetic file names. |
| `sim_reset(dataset)` | Clears the cached spine (forces rebuild on next call). |
| `cbs_code(x)` | Extracts original CBS character codes (e.g. `"1"`, `"A"`) from a `haven::labelled` column. |
| `sim_column_overview()` | Returns a `data.table` of all columns with calibration level, source, and spatial detail. |
| `sim_scan_columns(paths)` | Scans R scripts for `col_select` usage and returns a named list for `sim_export()`. |
| `sim_register(path)` | Registers a user-defined custom dataset from a simple YAML file. |
| `sim_create_custom(path)` | Writes a template YAML for defining a custom dataset. |
| `cbs_scaffold_dataset(dataset_id, files, ...)` | Scaffolds YAML config from CBS PDF documentation for a new built-in dataset. |
| `cbs_check_columns(file, txt_path)` | Compares simulated columns against CBS PDF documentation. |
| `cbs_parse_pdf_columns(txt_path)` | Parses variable tables from extracted CBS PDF text. |
| `*_cbs_params(year)` | Loads cached CBS parameters for a dataset (e.g. `spolis_cbs_params(2023)`). |
| `*_update_params(years)` | Fetches CBS StatLine data and writes `params.yaml` (e.g. `vehtab_update_params()`). |

### Demographic dynamics across years

Each person is assigned a **year-invariant life course** — a birth year, a
death year (from a sex-specific lifespan), and optional emigration / immigration
years — derived deterministically from their `RINPERSOON`. Because the life
course depends only on the person (not the simulation year) it is fully
reproducible for a given seed, yet it makes the population genuinely
**unbalanced across years**: persons are born into the panel, die, and migrate
in and out.

Population-snapshot files only contain the persons present in the simulation
year, and their entry/exit indicators are derived from the life course rather
than drawn independently:

- `WoonbasePopulatiePersonen`, `GBAADRESOBJECTBUS`, `GBAHUISHOUDENSBUS` are
  restricted to the year's living/registered population (`Indicator_PersoonIs*`
  for births, deaths, migration, and `IsAanwezig1Jan`/`IsAanwezig31Dec` reflect
  actual events).
- `GBAPERSOONKTAB` keeps one row per person ever registered (it is demographic,
  not a period snapshot).

The shared identity spine that other datasets sample from (SPOLIS, income,
networks, …) stays year-invariant, so cross-year network stability and
reproducible joins are unaffected. Household member/child counts and the
reference person are recomputed for the surviving members of each snapshot.

*Current scope:* dynamics are applied to the shared person spine and the
person-level snapshot files; household/object files keep their full structure,
and explicit GBA date columns (full birth/death/migration dates) are a planned
follow-up. Event rates are approximate and centred on the reference year;
calibration to CBS StatLine is tracked separately.

### Architecture

The simulator uses a YAML-driven config system under `inst/config/datasets/{dataset_id}/`:

- **`manifest.yaml`** — registers the dataset, its spine builder, and file types
- **`codelists.yaml`** — value label mappings (applied as `haven::labelled`)
- **`columns/*.yaml`** — per-file column definitions (sources, distributions, codelists)
- **`params.yaml`** — year-specific CBS-calibrated parameters

### CBS parameters

Year-specific parameters are stored in each dataset's `params.yaml` and checked into git. **No API calls are made during data generation.** To refresh when CBS publishes new data:

```r
woonbase_update_params()            # 37230ned, 71486ned
rdw_update_params()                 # 85237NED, 85236NED, 85404NED
spolis_update_params()              # 81431NED
vehtab_update_params()              # 83834NED
energieverbruik_update_params()     # Kerncijfers wijken en buurten
```

## Performance

**Interactive use** (1M persons on a modern laptop):

| Stage | Approximate time |
|-------|-----------------|
| Spine build (`sim_init("woonbase")`) | 8–15 s |
| Assemble 2 columns (`read_sav` with `col_select`) | < 0.5 s |
| Assemble all columns (no `col_select`) | 3–5 s |

**Bulk export** (`sim_population` at 1% sample, ~178k persons):

| Scenario | Time | Output |
|----------|------|--------|
| Woonbase + RDW, `col_select` (5-6 cols/file), 8 years | ~170 s (~21 s/year) | 88 parquet files, ~550 MB |

The bulk of the time is spent on spine construction per year. Using `col_select`
to limit columns keeps file sizes manageable and speeds up assembly.

## Dependencies

```r
# stats, tools and utils ship with base R, so they are not installed here
install.packages(c("data.table", "haven", "rlang", "tidyselect", "yaml",
                   "tibble"))
install.packages(c("arrow", "cbsodataR"))  # optional: parquet I/O + StatLine refresh
```
