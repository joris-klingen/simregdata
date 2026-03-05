# simcbsradata

Synthetic CBS microdata generator for R. Mimics the exact file structure, column names, value labels, and cross-file join keys of CBS registers — so analysis code written against this simulator runs unchanged on the real remote access data. Key variables are calibrated to publicly available CBS StatLine statistics, ensuring realistic marginal distributions for demographics, housing, vehicles, employment, wealth, and energy consumption.

## Background

[CBS microdata](https://www.cbs.nl/nl-nl/onze-diensten/maatwerk-en-microdata/microdata-zelf-onderzoek-doen) are linked administrative registers available to researchers via the CBS Remote Access environment. Because the real files are restricted, this project simulates them from the PDF variable documentation so that:

- Analysis scripts can be developed and tested locally
- Workflows can be benchmarked and profiled
- Colleagues without CBS access can reproduce results

## Installation

```r
# Install from GitHub
remotes::install_github("joris-klingen/simcbsradata")
```

## Supported datasets

Currently supports 6 CBS datasets across 17 file types: **GBA** (population register), **Woonbase** (housing + population), **RDW** (vehicle registrations), **SPOLIS** (employment records), **VEHTAB** (household wealth), and **Energieverbruik** (dwelling energy consumption). More datasets will be added over time.

All datasets share a common population spine with consistent join keys (RINPERSOON, HUISHOUDNR, RINOBJECTNUMMER), so cross-file joins work exactly as on the real CBS Remote Access.

See the full [column overview](docs/column-overview.md) for all 396 simulated columns with their source, spatial level, calibration links, and codelists.

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

# See all available files
sim_catalog()
```

## How the simulator works

### Public functions

| Function | Description |
|----------|-------------|
| `sim_init(dataset, year, n, seed)` | Builds the shared population spine and prepares dataset-specific state. |
| `read_sav(file, col_select, n_max, skip, ...)` | Drop-in replacement for `haven::read_sav()`. Returns synthetic data for registered CBS filenames; falls through to `haven::read_sav()` for unregistered paths. |
| `sim_catalog(dataset, year)` | Prints all available synthetic file names. |
| `sim_reset(dataset)` | Clears the cached spine (forces rebuild on next call). |
| `sim_column_overview()` | Returns a `data.table` of all columns with calibration level and source. |
| `*_cbs_params(year)` | Loads cached CBS parameters for a dataset (e.g. `spolis_cbs_params(2023)`). |
| `*_update_params(years)` | Fetches CBS StatLine data and writes `params.yaml` (e.g. `vehtab_update_params()`). |

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

At 1M persons on a modern laptop:

| Stage | Approximate time |
|-------|-----------------|
| Spine build (`sim_init("woonbase")`) | 8–15 s |
| Assemble 2 columns (`read_sav` with `col_select`) | < 0.5 s |
| Assemble all columns (no `col_select`) | 3–5 s |

## Dependencies

```r
install.packages(c("data.table", "haven", "rlang", "tidyselect", "yaml",
                   "tibble", "stats", "tools",
                   "cbsodataR"))  # optional: refresh params from StatLine
```
