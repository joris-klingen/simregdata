# simcbsradata

Synthetic CBS microdata generator for R. Mimics the exact file structure, column names, value labels, and cross-file join keys of CBS registers — so analysis code written against this simulator runs unchanged on the real restricted-access data.

Supports multiple CBS datasets: **Woonbase** (housing + population, 9 file types), **RDW** (vehicle registrations + traffic performance, 2 file types), and **SPOLIS** (employment records with wages, hours, insurance, 1 file type).

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

## Directory layout

The repo root **is** the R package. Non-package files (`analysis/`, `plots/`, etc.) live
alongside it and are excluded from the built package via `.Rbuildignore`.

```
simcbsradata/
├── R/                             # Package R code
├── inst/config/datasets/
│   ├── woonbase/                  # 9 file types, params.yaml, gem_weights.csv
│   ├── rdw/                       # 2 file types, params.yaml, gem_vehicle_weights.csv
│   └── spolis/                    # 1 file type, params.yaml
├── man/                           # Function documentation
├── tests/                         # Unit tests
├── vignettes/                     # Package vignettes
├── analysis/                      # Analysis & dev scripts (not part of package)
│   ├── analyse_woonbase.R         # 6 plots + 2 maps from joined Woonbase files
│   ├── analyse_rdw_woonbase.R     # 5 plots: fuel, car ownership, VKT
│   ├── housing_type_timeseries.R  # Housing stock composition 2016–2024
│   └── maps_woonbase.R           # Municipality choropleths
├── pdfs_cbs_catalog/pdf/          # CBS variable documentation PDFs
├── DESCRIPTION
└── NAMESPACE
```

## Supported datasets

### Woonbase (9 file types)

| Short name | CBS dataset name | Entity |
|------------|------------------|--------|
| `sleutel` | WoonbaseSleutelbestand | person |
| `kenmerken_pers` | WoonbaseKenmerkenPersonen | person |
| `kenmerken_hh` | WoonbaseKenmerkenHuishoudens | household |
| `kenmerken_obj` | WoonbaseKenmerkenWoonruimten | object |
| `populatie_pers` | WoonbasePopulatiePersonen | person |
| `populatie_hh` | WoonbasePopulatieHuishoudens | household |
| `populatie_obj` | WoonbasePopulatieWoonruimten | object |
| `ek_hh_welvaart` | WOONBASEEKHuishoudensWV | household |
| `ek_obj_panden` | ExtraKenmerkenPanden | object |

### RDW (2 file types)

| Short name | CBS dataset name | Entity |
|------------|------------------|--------|
| `kentekens` | RDWNPACT | person |
| `verkeersprestatie` | VERKEERSPRESTATIE | person |

### SPOLIS (1 file type)

| Short name | CBS dataset name | Entity |
|------------|------------------|--------|
| `spolisbus` | SPOLISBUS | person |

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

# Initialize linked datasets (RDW, SPOLIS) — requires woonbase spine first
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
| `sim_init(dataset, year, n, seed)` | Builds and caches the shared spine for a dataset. Call once per dataset before reading files. |
| `read_sav(file, col_select, n_max, skip, ...)` | Drop-in replacement for `haven::read_sav()`. Matches registered CBS dataset names and returns synthetic data; infers the year from the filename. Falls through to `haven::read_sav()` for unregistered paths. |
| `sim_catalog(dataset, year)` | Prints all available synthetic file names across all datasets. |
| `sim_reset(dataset)` | Clears the cached spine (forces a rebuild on next call). |
| `woonbase_cbs_params(year)` | Loads CBS population parameters from `params.yaml`. |
| `woonbase_update_params(years)` | Fetches CBS StatLine data and writes `params.yaml` + `gem_weights.csv`. |
| `rdw_cbs_params(year)` | Loads RDW vehicle parameters from `params.yaml`. |
| `rdw_update_params(years)` | Fetches CBS StatLine data for vehicles (85237NED, 85236NED, 85404NED). |
| `spolis_cbs_params(year)` | Loads SPOLIS employment parameters from `params.yaml`. |
| `spolis_update_params(years)` | Fetches CBS StatLine data for employment (81431NED). |
| `cbs_scaffold_dataset(...)` | Generates skeleton YAML config for a new dataset from PDF documentation. |

Backward-compatible wrappers: `woonbase_init()`, `woonbase_reset()`, `woonbase_catalog()`.

### Architecture

The simulator uses a YAML-driven config system under `inst/config/datasets/{dataset_id}/`:

- **`manifest.yaml`** — registers the dataset, its spine builder, and file types
- **`codelists.yaml`** — value label mappings (applied as `haven::labelled`)
- **`columns/*.yaml`** — per-file column definitions (sources, distributions, codelists)
- **`params.yaml`** — year-specific CBS-calibrated parameters

### Spine generation

**Woonbase** uses a custom spine builder with three stages:
1. **Objects** — dwelling records with spatial attributes, WOZ value, floor area, etc.
2. **Households** — linked to objects; TYPHH proportions from `params.yaml`
3. **Persons** — expanded from households; person roles, birth year, civil status

**RDW and SPOLIS** use the generic spine builder: sample RINPERSOON with replacement from the woonbase person spine, scaled by `n_vehicles / n_persons` or `n_jobs / n_persons`.

### CBS parameters

Year-specific parameters (population counts, household types, vehicle distributions, employment stats) are stored in each dataset's `params.yaml` and checked into git. **No API calls are made during data generation.**

To refresh (e.g. when CBS publishes new data):

```r
library(simcbsradata)
woonbase_update_params()            # refreshes 2016–2024
rdw_update_params()                 # refreshes 2019–2025
spolis_update_params()              # refreshes 2019–2025
```

CBS StatLine tables used:
- `37230ned` — Population on 1 January
- `71486ned` — Household type distribution
- `85237NED` — Personenauto's: fuel, color, weight, construction year
- `85236NED` — Motor vehicles: type breakdown, total count
- `85404NED` — Traffic performance: annual mileage
- `81431NED` — Employment: job counts, FT/PT ratio, wages, sectors

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
                   "ggplot2", "sf", "glue",     # for analysis scripts
                   "cbsodataR",                  # optional: refresh params from StatLine
                   "profvis"))                   # optional: flame graph
```
