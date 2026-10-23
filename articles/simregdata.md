# Getting started with simregdata

`simregdata` returns simulated CBS microdata through a drop-in
[`read_sav()`](https://joris-klingen.github.io/simregdata/reference/read_sav.md).
Code written against it runs unchanged in CBS Remote Access, where the
same call reads the real file.

## Read a file

``` r

library(haven)
library(simregdata)  # after haven, so read_sav() is the simulator's

sim_init("woonbase", year = 2023, n = 5000, seed = 42)

pers <- read_sav("WoonbasePopulatiePersonen2023V1",
                 col_select = c(RINPERSOON, HUISHOUDNR1Jan, TYPHH1Jan))
head(pers)
#> # A tibble: 6 × 3
#>   RINPERSOON HUISHOUDNR1Jan TYPHH1Jan                    
#>   <chr>      <chr>          <int+lbl>                    
#> 1 488404786  000000000001   8 [Institutioneel huishouden]
#> 2 371027360  000000000001   8 [Institutioneel huishouden]
#> 3 639972388  000000000001   8 [Institutioneel huishouden]
#> 4 656756076  000000000001   8 [Institutioneel huishouden]
#> 5 181341029  000000000001   8 [Institutioneel huishouden]
#> 6 834905395  000000000001   8 [Institutioneel huishouden]
```

[`sim_init()`](https://joris-klingen.github.io/simregdata/reference/sim_init.md)
builds a shared population *spine* of persons, households and dwellings;
every dataset draws from it.
[`sim_catalog()`](https://joris-klingen.github.io/simregdata/reference/sim_catalog.md)
lists all file names.

## Labels and codes

Categorical columns are
[`haven::labelled`](https://haven.tidyverse.org/reference/labelled.html),
as in real `.sav` files.
[`cbs_code()`](https://joris-klingen.github.io/simregdata/reference/cbs_code.md)
recovers the original CBS character codes:

``` r

table(as_factor(pers$TYPHH1Jan))
#> 
#>            Eenpersoonshuishouden Niet-gehuwd paar zonder kinderen 
#>                              783                              316 
#>      Gehuwd paar zonder kinderen    Niet-gehuwd paar met kinderen 
#>                              874                              374 
#>         Gehuwd paar met kinderen               Eenouderhuishouden 
#>                             1334                              365 
#>                Overig huishouden        Institutioneel huishouden 
#>                               26                              412 
#>             Meerdere huishoudens 
#>                                0

sim_init("rdw", year = 2023)
rdw <- read_sav("RDWNPACT2023TABV1", n_max = 5)
cbs_code(rdw$BRANDSTCODECORVRTG)
#> [1] "1" "1" "1" "2" "1"
```

## Joins across files

Identifiers (`RINPERSOON`, `HUISHOUDNR`, `RINOBJECTNUMMER`,
`RINPERSOONHKW`) come from the spine, so joins between datasets match as
on the real data:

``` r

sim_init("inpatab", year = 2023)
inpa <- read_sav("INPA2023TABV1", col_select = c(RINPERSOON, INPPERSBESTINK))

joined <- merge(pers, inpa, by = "RINPERSOON")
nrow(joined) / nrow(pers)
#> [1] 1
```

## Export to parquet

For larger runs,
[`sim_population()`](https://joris-klingen.github.io/simregdata/reference/sim_population.md)
writes a sample of the population to parquet in the CBS folder layout;
[`sim_set_data_root()`](https://joris-klingen.github.io/simregdata/reference/sim_set_data_root.md)
then makes
[`read_sav()`](https://joris-klingen.github.io/simregdata/reference/read_sav.md)
read those files instead of simulating:

``` r

sim_population("sim_data", datasets = c("woonbase", "rdw"),
               years = 2019:2023, fraction = 0.01)
sim_set_data_root("sim_data")
```

[`sim_scan_columns()`](https://joris-klingen.github.io/simregdata/reference/sim_scan_columns.md)
finds the `col_select` columns your scripts use, so the export only
writes what you need.

## Other files

[`read_sav()`](https://joris-klingen.github.io/simregdata/reference/read_sav.md)
passes any name it does not recognise to
[`haven::read_sav()`](https://haven.tidyverse.org/reference/read_spss.html),
so one call works for simulated and real files. Datasets of your own can
be added from a YAML file with
[`sim_create_custom()`](https://joris-klingen.github.io/simregdata/reference/sim_create_custom.md)
and
[`sim_register()`](https://joris-klingen.github.io/simregdata/reference/sim_register.md).

## How it works

Each dataset is defined in YAML under `inst/config/datasets/`: a
manifest, codelists, column definitions and year-specific parameters.
The parameters are calibrated to CBS StatLine and stored in the package,
so generating data needs no network. The `*_update_params()` functions
refresh them.

Persons have a deterministic life course (birth, death, migration), so
the population changes between years while identifiers stay stable.
Building the spine for one million persons takes about 10 seconds.

See
[`vignette("quality-cars")`](https://joris-klingen.github.io/simregdata/articles/quality-cars.md)
and the other quality articles for how close analyses on simulated data
come to published statistics, and the [provenance
article](https://joris-klingen.github.io/simregdata/articles/provenance.html)
for where each parameter comes from.
