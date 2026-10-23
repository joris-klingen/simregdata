Getting started with simregdata
================

## What is simregdata?

`simregdata` generates synthetic CBS microdata for 15 datasets (31 file
types). It provides a drop-in `read_sav()` that intercepts CBS file
names and returns simulated data with the same structure as the real
`.sav` files on the CBS remote-access environment.

This lets you develop and test analysis scripts outside the CBS
environment using realistic data with:

- Correct Dutch population sizes (calibrated to CBS StatLine)
- haven-compatible labelled columns (same as `haven::read_sav()`)
- Consistent cross-file identifiers (RINPERSOON, HUISHOUDNR,
  RINOBJECTNUMMER, RINPERSOONHKW)
- Original CBS character codes recoverable via `cbs_code()`

### Datasets

| Category             | Datasets                                                          |
|----------------------|-------------------------------------------------------------------|
| Housing & population | Woonbase (13 files), GBA (3)                                      |
| Vehicles             | RDW (2)                                                           |
| Employment & income  | SPOLIS (1), INPATAB (1), INHATAB (1), SECMBUS (1)                 |
| Wealth               | VEHTAB (1)                                                        |
| Education            | HOOGSTEOPLTAB (1)                                                 |
| Business             | BETAB (1)                                                         |
| Energy               | Energieverbruik (2), Zonnestroominstallaties (1)                  |
| Networks             | Burennetwerktab (1), Colleganetwerktab (1), Familienetwerktab (1) |

## Quick start

``` r
library(haven)
library(simregdata)   # load after haven so read_sav() masks haven::read_sav()

# See what files are available
sim_catalog()
#> 
#>   simregdata — synthetic file catalog
#>   ======================================
#> 
#>   Dataset: Bedrijven (activiteit en grootteklasse) (betab)
#>   CBS name                        Entity      read_sav() file argument
#>   ------------------------------  ----------  ----------------------------------------
#>   BE                              person      BE2023TABV1
#> 
#>   Dataset: Burennetwerk (burennetwerktab)
#>   CBS name                        Entity      read_sav() file argument
#>   ------------------------------  ----------  ----------------------------------------
#>   BURENNETWERK                    person      BURENNETWERK2023TABV1
#> 
#>   Dataset: Colleganetwerk (colleganetwerktab)
#>   CBS name                        Entity      read_sav() file argument
#>   ------------------------------  ----------  ----------------------------------------
#>   COLLEGANETWERK                  person      COLLEGANETWERK2023TABV1
#> 
#>   Dataset: Energieverbruik particuliere woningen (energieverbruik)
#>   CBS name                        Entity      read_sav() file argument
#>   ------------------------------  ----------  ----------------------------------------
#>   ENERGIEVERBRUIK                 object      ENERGIEVERBRUIK2023TABV1
#>   ENERGIEVERBRUIKMAAND            object      ENERGIEVERBRUIKMAAND2023TABV1
#> 
#>   Dataset: Familienetwerk (familienetwerktab)
#>   CBS name                        Entity      read_sav() file argument
#>   ------------------------------  ----------  ----------------------------------------
#>   FAMILIENETWERK                  person      FAMILIENETWERK2023TABV1
#> 
#>   Dataset: GBA Bevolkingsregister (gba)
#>   CBS name                        Entity      read_sav() file argument
#>   ------------------------------  ----------  ----------------------------------------
#>   GBAPERSOONKTAB                  person      GBAPERSOONKTAB2023TABV1
#>   GBAADRESOBJECTBUS               person      GBAADRESOBJECTBUS2023V1
#>   GBAHUISHOUDENSBUS               person      GBAHUISHOUDENSBUS2023V1
#> 
#>   Dataset: Hoogst behaald opleidingsniveau (hoogsteopltab)
#>   CBS name                        Entity      read_sav() file argument
#>   ------------------------------  ----------  ----------------------------------------
#>   HOOGSTEOPL                      person      HOOGSTEOPL2023TABV1
#> 
#>   Dataset: Inkomen van huishoudens (inhatab)
#>   CBS name                        Entity      read_sav() file argument
#>   ------------------------------  ----------  ----------------------------------------
#>   INHA                            person      INHA2023TABV1
#> 
#>   Dataset: Inkomen van personen (inpatab)
#>   CBS name                        Entity      read_sav() file argument
#>   ------------------------------  ----------  ----------------------------------------
#>   INPA                            person      INPA2023TABV1
#> 
#>   Dataset: RDW Motorvoertuigenpark (rdw)
#>   CBS name                        Entity      read_sav() file argument
#>   ------------------------------  ----------  ----------------------------------------
#>   RDWNPACT                        person      RDWNPACT2023TABV1
#>   VERKEERSPRESTATIE               person      VERKEERSPRESTATIE2023TABV1
#> 
#>   Dataset: Sociaaleconomische categorie (maandelijks) (secmbus)
#>   CBS name                        Entity      read_sav() file argument
#>   ------------------------------  ----------  ----------------------------------------
#>   SECMBUS                         person      SECMBUS2023V1
#> 
#>   Dataset: Banen en lonen (spolis)
#>   CBS name                        Entity      read_sav() file argument
#>   ------------------------------  ----------  ----------------------------------------
#>   SPOLISBUS                       person      SPOLISBUS2023V1
#> 
#>   Dataset: Vermogens van huishoudens (vehtab)
#>   CBS name                        Entity      read_sav() file argument
#>   ------------------------------  ----------  ----------------------------------------
#>   VEH                             household   VEH2023TABV1
#> 
#>   Dataset: CBS Woonbase (woonbase)
#>   CBS name                        Entity      read_sav() file argument
#>   ------------------------------  ----------  ----------------------------------------
#>   WoonbaseSleutelbestand          person      WoonbaseSleutelbestand2023V1
#>   WoonbaseKenmerkenPersonen       person      WoonbaseKenmerkenPersonen2023V1
#>   WoonbaseKenmerkenHuishoudens    household   WoonbaseKenmerkenHuishoudens2023V1
#>   WoonbaseKenmerkenWoonruimten    object      WoonbaseKenmerkenWoonruimten2023V1
#>   WoonbasePopulatiePersonen       person      WoonbasePopulatiePersonen2023V1
#>   WoonbasePopulatieHuishoudens    household   WoonbasePopulatieHuishoudens2023V1
#>   WoonbasePopulatieWoonruimten    object      WoonbasePopulatieWoonruimten2023V1
#>   WOONBASEEKHuishoudensWV         household   WOONBASEEKHuishoudensWV2023V1
#>   WoonbaseEKPersonenWV            person      WoonbaseEKPersonenWV2023V1
#>   WOONBASEEKPERSONENOP            person      WOONBASEEKPERSONENOP2023V1
#>   WOONBASEEKHuishoudensWL         household   WOONBASEEKHuishoudensWL2023V1
#>   WoonbaseEKWoonruimtenWV         object      WoonbaseEKWoonruimtenWV2023V1
#>   ExtraKenmerkenPanden            object      ExtraKenmerkenPanden2023TABV1
#> 
#>   Dataset: Kenmerken en elektriciteitsproductie van zonnestroominstallaties (zonnestroominstallaties)
#>   CBS name                        Entity      read_sav() file argument
#>   ------------------------------  ----------  ----------------------------------------
#>   Zonnnestroominstallaties        object      Zonnnestroominstallaties2023V1
```

### Initialise the spine

The “spine” is a shared set of person, household, and object
identifiers. Pre-building it ensures that joins between different files
always succeed.

``` r
# Build a small spine for development (5,000 persons)
sim_init("woonbase", year = 2023, n = 5000, seed = 42)
```

### Read synthetic Woonbase files

Use `read_sav()` exactly as you would with real CBS microdata. Pass the
exact CBS CamelCase dataset name:

``` r
# Read the person population file
dt_pers <- read_sav("WoonbasePopulatiePersonen2023V1",
                    n_max = 100,
                    col_select = c(RINPERSOON, TYPHH1Jan, GBAGeboorteJaar1Jan))
head(dt_pers)
#> # A tibble: 6 × 3
#>   RINPERSOON TYPHH1Jan                         GBAGeboorteJaar1Jan
#>   <chr>      <int+lbl>                                       <int>
#> 1 494318943  5 [Gehuwd paar met kinderen]                     1955
#> 2 031131210  5 [Gehuwd paar met kinderen]                     1995
#> 3 438882452  5 [Gehuwd paar met kinderen]                     2016
#> 4 859956951  4 [Niet-gehuwd paar met kinderen]                1994
#> 5 833043810  4 [Niet-gehuwd paar met kinderen]                1949
#> 6 847776314  4 [Niet-gehuwd paar met kinderen]                2022
```

``` r
# Read the household population file
dt_hh <- read_sav("WoonbasePopulatieHuishoudens2023V1",
                  n_max = 100,
                  col_select = c(HUISHOUDNR1Jan, TYPHH1Jan, LeeftijdRefPersoon1Jan))
head(dt_hh)
#> # A tibble: 6 × 3
#>   HUISHOUDNR1Jan TYPHH1Jan                         LeeftijdRefPersoon1Jan
#>   <chr>          <int+lbl>                                          <int>
#> 1 000000000001   5 [Gehuwd paar met kinderen]                          68
#> 2 000000000002   4 [Niet-gehuwd paar met kinderen]                     29
#> 3 000000000003   1 [Eenpersoonshuishouden]                             33
#> 4 000000000004   1 [Eenpersoonshuishouden]                             52
#> 5 000000000005   3 [Gehuwd paar zonder kinderen]                       25
#> 6 000000000006   4 [Niet-gehuwd paar met kinderen]                     64
```

### Haven-compatible labels

Categorical columns are returned as `haven::labelled` integers, just
like real `.sav` files. Use `haven::as_factor()` to convert to factors:

``` r
# TYPHH1Jan is a labelled integer
class(dt_pers$TYPHH1Jan)
#> [1] "haven_labelled" "vctrs_vctr"     "integer"
attr(dt_pers$TYPHH1Jan, "labels")
#>            Eenpersoonshuishouden Niet-gehuwd paar zonder kinderen 
#>                                1                                2 
#>      Gehuwd paar zonder kinderen    Niet-gehuwd paar met kinderen 
#>                                3                                4 
#>         Gehuwd paar met kinderen               Eenouderhuishouden 
#>                                5                                6 
#>                Overig huishouden        Institutioneel huishouden 
#>                                7                                8 
#>             Meerdere huishoudens 
#>                                9

# Convert to factor for analysis
table(haven::as_factor(dt_pers$TYPHH1Jan))
#> 
#>            Eenpersoonshuishouden Niet-gehuwd paar zonder kinderen 
#>                               23                                3 
#>      Gehuwd paar zonder kinderen    Niet-gehuwd paar met kinderen 
#>                               22                                9 
#>         Gehuwd paar met kinderen               Eenouderhuishouden 
#>                               35                                8 
#>                Overig huishouden        Institutioneel huishouden 
#>                                0                                0 
#>             Meerdere huishoudens 
#>                                0
```

### CBS character codes

CBS uses character codes internally (e.g. `"1"` = benzine, `"A"` =
PHEV). The `cbs_code()` function recovers these from `haven::labelled`
columns:

``` r
sim_init("rdw", year = 2023, n = 5000, seed = 42)
rdw <- read_sav("RDWNPACT2023TABV1", n_max = 10)

# Integer values (haven-labelled)
as.integer(rdw$BRANDSTCODECORVRTG)
#>  [1] 1 4 1 1 4 1 1 1 1 4

# Original CBS character codes
cbs_code(rdw$BRANDSTCODECORVRTG)
#>  [1] "1" "4" "1" "1" "4" "1" "1" "1" "1" "4"
```

### Cross-file joins

Because the spine is shared, identifiers match across files:

``` r
pers <- read_sav("WoonbasePopulatiePersonen2023V1",
                 col_select = c(RINPERSOON, HUISHOUDNR1Jan))
hh   <- read_sav("WoonbasePopulatieHuishoudens2023V1",
                 col_select = c(HUISHOUDNR1Jan, TYPHH1Jan))

joined <- merge(pers, hh, by = "HUISHOUDNR1Jan")
cat(sprintf("Join match rate: %.1f%%\n", nrow(joined) / nrow(pers) * 100))
#> Join match rate: 100.0%
```

## Linked datasets

All datasets share the same population spine, so cross-dataset joins
work out of the box:

``` r
# Auto-builds shared spine if needed
sim_init("spolis", year = 2023)
sim_init("inpatab", year = 2023)

jobs   <- read_sav("SPOLISBUS2023V1", n_max = 5)
income <- read_sav("INPA2023TABV1", n_max = 5)

head(jobs[, c("RINPERSOON", "SBASISLOON", "SCONTRACTSOORT")])
#> # A tibble: 5 × 3
#>   RINPERSOON SBASISLOON SCONTRACTSOORT   
#>   <chr>           <dbl> <int+lbl>        
#> 1 847280784        1804 1 [Bepaalde tijd]
#> 2 847280784        2075 1 [Bepaalde tijd]
#> 3 847280784        6526 1 [Bepaalde tijd]
#> 4 847280784        1359 1 [Bepaalde tijd]
#> 5 847280784        1860 1 [Bepaalde tijd]
head(income[, c("RINPERSOON", "INPPERSBESTINK", "INPSECJ")])
#> # A tibble: 5 × 3
#>   RINPERSOON INPPERSBESTINK INPSECJ                             
#>   <chr>               <dbl> <int+lbl>                           
#> 1 847280784           37715 1 [Werknemer]                       
#> 2 719479549           47664 7 [Ontvanger bijstandsuitkering]    
#> 3 073304317           24554 6 [Ontvanger werkloosheidsuitkering]
#> 4 776993912           33214 1 [Werknemer]                       
#> 5 271821755           12454 1 [Werknemer]
```

## Woonbase file types (13 files)

| Key               | CBS dataset name             | Unit      | Description                                                    |
|-------------------|------------------------------|-----------|----------------------------------------------------------------|
| sleutel           | WoonbaseSleutelbestand       | person    | Key file linking persons to HH and objects                     |
| kenmerken_pers    | WoonbaseKenmerkenPersonen    | person    | Person characteristics (age, gender, civil status)             |
| kenmerken_hh      | WoonbaseKenmerkenHuishoudens | household | Household characteristics (type, size)                         |
| kenmerken_obj     | WoonbaseKenmerkenWoonruimten | object    | Dwelling characteristics (WOZ, floor area, build year)         |
| populatie_pers    | WoonbasePopulatiePersonen    | person    | Person population (rich: includes HH + object attributes)      |
| populatie_hh      | WoonbasePopulatieHuishoudens | household | Household population (includes ref-person + object attributes) |
| populatie_obj     | WoonbasePopulatieWoonruimten | object    | Dwelling population (includes HH + ref-person attributes)      |
| ek_hh_welvaart    | WOONBASEEKHuishoudensWV      | household | Household income and wealth (Extra Kenmerken)                  |
| ek_pers_welvaart  | WoonbaseEKPersonenWV         | person    | Person income and poverty (Extra Kenmerken)                    |
| ek_pers_opleiding | WOONBASEEKPERSONENOP         | person    | Person education level (Extra Kenmerken)                       |
| ek_hh_woonlasten  | WOONBASEEKHuishoudensWL      | household | Household housing costs and mortgage (Extra Kenmerken)         |
| ek_obj_welvaart   | WoonbaseEKWoonruimtenWV      | object    | Dwelling income and wealth (Extra Kenmerken)                   |
| ek_obj_panden     | ExtraKenmerkenPanden         | object    | Building characteristics (Extra Kenmerken)                     |

## Bulk export with sim_population()

`sim_population()` generates a fractional sample of all (or selected)
datasets and writes parquet files in CBS VM-style folder layout:

``` r
# Export woonbase + rdw for 2019-2023 at 1%
sim_population("output/sim_data",
               datasets = c("woonbase", "rdw"),
               years = 2019:2023)

# Export everything (excluding networks by default)
sim_population("output/sim_data", fraction = 0.01, years = 2023)

# Then use the exported files directly
sim_set_data_root("output/sim_data")
dt <- read_sav("WoonbasePopulatiePersonen2023V1")
```

## Custom datasets

Define your own datasets with a simple YAML file:

``` r
# Create a template
sim_create_custom("my_survey.yaml")

# Edit the YAML, then register it
sim_register("my_survey.yaml")

# Use it like any built-in dataset
sim_init("my_survey", year = 2023, n = 100000)
dt <- read_sav("my_survey2023V1")
```

## Refreshing CBS parameters

Population sizes and dataset-specific distributions are stored in
bundled YAML files. To update from CBS StatLine (requires `cbsodataR`):

``` r
woonbase_update_params(years = 2016:2025)
rdw_update_params(years = 2019:2025)
spolis_update_params(years = 2010:2025)
inhatab_update_params(years = 2011:2024)            # household income (83932NED)
energieverbruik_update_structure(years = 2010:2025) # energy per dwelling (81528NED, 85140NED)
```

## Unregistered files

For any file name that doesn’t match a registered dataset, `read_sav()`
falls through to `haven::read_sav()`. This means you can use a single
`read_sav()` call throughout your code:

``` r
# This reads a real .sav file via haven
dt <- read_sav("G:/MICRODATA/SOME_OTHER_FILE.sav")
```

## Function reference

| Function                                                                  | Description                                                                                                                                                                                                       |
|---------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `sim_population(output_dir, fraction, years, seed, datasets, col_select)` | Generates a fractional sample (default 1%) of all or selected datasets and exports to parquet.                                                                                                                    |
| `sim_init(dataset, year, n, seed)`                                        | Builds the shared population spine and prepares dataset-specific state.                                                                                                                                           |
| `read_sav(file, col_select, n_max, skip, ...)`                            | Drop-in replacement for `haven::read_sav()`. Returns synthetic data for registered CBS filenames; falls through to `haven::read_sav()` for unregistered paths.                                                    |
| `sim_export(output_dir, dataset, year, n, seed, col_select, force_resim)` | Exports simulated datasets to parquet in CBS VM-style folder layout. Skips files whose columns/`n`/`seed` already match the `.sim_meta.yaml` in `output_dir`; pass `force_resim = TRUE` to regenerate regardless. |
| `sim_set_data_root(path)` / `sim_get_data_root()`                         | Set/get a parquet data root so `read_sav()` reads pre-exported files instead of generating on-the-fly.                                                                                                            |
| `sim_catalog(dataset, year)`                                              | Prints all available synthetic file names.                                                                                                                                                                        |
| `sim_reset(dataset)`                                                      | Clears the cached spine (forces rebuild on next call).                                                                                                                                                            |
| `cbs_code(x)`                                                             | Extracts original CBS character codes (e.g. `"1"`, `"A"`) from a `haven::labelled` column.                                                                                                                        |
| `sim_column_overview()`                                                   | Returns a `data.table` of all columns with calibration level, source, and spatial detail.                                                                                                                         |
| `sim_scan_columns(paths)`                                                 | Scans R scripts for `col_select` usage and returns a named list for `sim_export()`.                                                                                                                               |
| `sim_register(path)`                                                      | Registers a user-defined custom dataset from a simple YAML file.                                                                                                                                                  |
| `sim_create_custom(path)`                                                 | Writes a template YAML for defining a custom dataset.                                                                                                                                                             |
| `cbs_scaffold_dataset(dataset_id, files, ...)`                            | Scaffolds YAML config from CBS PDF documentation for a new built-in dataset.                                                                                                                                      |
| `cbs_check_columns(file, txt_path)`                                       | Compares simulated columns against CBS PDF documentation.                                                                                                                                                         |
| `cbs_parse_pdf_columns(txt_path)`                                         | Parses variable tables from extracted CBS PDF text.                                                                                                                                                               |
| `*_cbs_params(year)`                                                      | Loads cached CBS parameters for a dataset (e.g. `spolis_cbs_params(2023)`).                                                                                                                                       |
| `*_update_params(years)`                                                  | Fetches CBS StatLine data and writes `params.yaml` (e.g. `vehtab_update_params()`).                                                                                                                               |

## Demographic dynamics across years

Each person is assigned a **year-invariant life course** — a birth year,
a death year (from a sex-specific lifespan), and optional emigration /
immigration years — derived deterministically from their `RINPERSOON`.
Because the life course depends only on the person (not the simulation
year) it is fully reproducible for a given seed, yet it makes the
population genuinely **unbalanced across years**: persons are born into
the panel, die, and migrate in and out.

Population-snapshot files only contain the persons present in the
simulation year, and their entry/exit indicators are derived from the
life course rather than drawn independently:

- `WoonbasePopulatiePersonen`, `GBAADRESOBJECTBUS`, `GBAHUISHOUDENSBUS`
  are restricted to the year’s living/registered population
  (`Indicator_PersoonIs*` for births, deaths, migration, and
  `IsAanwezig1Jan`/`IsAanwezig31Dec` reflect actual events).
- `GBAPERSOONKTAB` keeps one row per person ever registered (it is
  demographic, not a period snapshot).

The shared identity spine that other datasets sample from (SPOLIS,
income, networks, …) stays year-invariant, so cross-year network
stability and reproducible joins are unaffected. Household member/child
counts and the reference person are recomputed for the surviving members
of each snapshot.

*Current scope:* dynamics are applied to the shared person spine and the
person-level snapshot files; household/object files keep their full
structure, and explicit GBA date columns (full birth/death/migration
dates) are a planned follow-up. Event rates are approximate and centred
on the reference year; calibration to CBS StatLine is tracked
separately.

## Architecture

The simulator uses a YAML-driven config system under
`inst/config/datasets/{dataset_id}/`:

- **`manifest.yaml`** — registers the dataset, its spine builder, and
  file types
- **`codelists.yaml`** — value label mappings (applied as
  `haven::labelled`)
- **`columns/*.yaml`** — per-file column definitions (sources,
  distributions, codelists)
- **`params.yaml`** — year-specific CBS-calibrated parameters

Year-specific parameters are stored in each dataset’s `params.yaml` and
checked into git. **No API calls are made during data generation** — the
`*_update_params()` functions above are only needed to refresh
parameters when CBS publishes new StatLine data.

## Performance

**Interactive use** (1M persons on a modern laptop):

| Stage                                             | Approximate time |
|---------------------------------------------------|------------------|
| Spine build (`sim_init("woonbase")`)              | 8–15 s           |
| Assemble 2 columns (`read_sav` with `col_select`) | \< 0.5 s         |
| Assemble all columns (no `col_select`)            | 3–5 s            |

**Bulk export** (`sim_population` at 1% sample, ~178k persons):

| Scenario                                              | Time                | Output                    |
|-------------------------------------------------------|---------------------|---------------------------|
| Woonbase + RDW, `col_select` (5-6 cols/file), 8 years | ~170 s (~21 s/year) | 88 parquet files, ~550 MB |

The bulk of the time is spent on spine construction per year. Using
`col_select` to limit columns keeps file sizes manageable and speeds up
assembly.
