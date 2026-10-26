# Where the numbers come from

Every number that shapes the simulated data, and its source. The
simulator must not contain anything derived from CBS Remote Access
microdata that has not passed CBS output checking; this inventory is the
basis for confirming that. The [column
overview](https://joris-klingen.github.io/simregdata/articles/column-overview.md)
lists, per column, which generator produces it.

## Levels of realism

| Level | Description | Changes across years? |
|----|----|----|
| **StatLine-calibrated** | Marginal distribution downloaded from CBS StatLine and stored in `params.yaml`. Updated with `*_update_params()`. | Yes |
| **Spine-derived** | Value copied from the woonbase spine, which itself is built from StatLine-calibrated parameters. | Yes (via spine) |
| **Stable per identifier** | Deterministic value per entity (e.g. per RINKENTEKEN) via multiplicative hashing. Year-stable — same identifier always yields the same value. | No |
| **Codelist-labelled** | Categorical column with hardcoded probabilities and CBS codelist labels. Plausible but not matched to any specific year. | No |
| **Random numeric** | Drawn from a hardcoded normal/lognormal distribution. Mean/SD are plausible but not empirically calibrated. | No |
| **Random uniform** | Drawn from a uniform range. Fills structural requirements only. | No |
| **Constant/template** | Fixed value (e.g., `"R"`, `" "`, `"01"`). | No |

## Sources of parameters

- **StatLine (fetched)**: written to `params.yaml` or a CSV by an
  `*_update_params()` / `*_update_structure()` function from public CBS
  StatLine tables (CC BY 4.0), so reproducible.
- **StatLine (stated, entered by hand)**: the file names a StatLine
  table, but no function fetches it.
- **Modelling choice**: a documented assumption in the code.
- **Unknown**: hardcoded without a documented source, listed at the end
  for the author to confirm.

### Fetched from StatLine

| Parameter | File | Function | StatLine table(s) | Years |
|----|----|----|----|----|
| Population, households, household-type shares (`n_persons`, `n_hh`, `typhh_p`) | `woonbase/params.yaml` | [`woonbase_update_params()`](https://joris-klingen.github.io/simregdata/reference/woonbase_update_params.md) | 37230ned, 71486ned | 2016-2024 |
| Population weight per gemeente | `woonbase/gem_weights.csv` | [`woonbase_update_params()`](https://joris-klingen.github.io/simregdata/reference/woonbase_update_params.md) | 37230ned | 2016-2024 |
| Mean WOZ value per gemeente | `woonbase/woz_means.csv` | [`woonbase_update_params()`](https://joris-klingen.github.io/simregdata/reference/woonbase_update_params.md) | 70072ned | 2016-2024 |
| Vehicle fleet, type, fuel, colour, weight, construction year, annual km | `rdw/params.yaml` | [`rdw_update_params()`](https://joris-klingen.github.io/simregdata/reference/rdw_update_params.md) | 85236NED, 85237NED, 85404NED | 2019-2025 |
| Vehicle density weight per gemeente | `rdw/gem_vehicle_weights.csv` | [`rdw_update_params()`](https://joris-klingen.github.io/simregdata/reference/rdw_update_params.md) | 85236NED, 37230ned | 2019-2025 |
| Jobs and wages (SPOLIS) | `spolis/params.yaml` | [`spolis_update_params()`](https://joris-klingen.github.io/simregdata/reference/spolis_update_params.md) | 81431NED | 2019-2025 |
| Household wealth components (mean) | `vehtab/params.yaml` | [`vehtab_update_params()`](https://joris-klingen.github.io/simregdata/reference/vehtab_update_params.md) | 83834NED | 2006-2024 |
| Household income per type and income concept (mean, median) | `inhatab/params.yaml` | [`inhatab_update_params()`](https://joris-klingen.github.io/simregdata/reference/inhatab_update_params.md) | 83932NED | 2011-2024 |
| National gas and electricity per dwelling | `energieverbruik/params.yaml` (`gas_mean`, `elek_mean`) | [`energieverbruik_update_structure()`](https://joris-klingen.github.io/simregdata/reference/energieverbruik_update_structure.md) | 81528NED | 2010-2025 |
| Energy per dwelling type, construction year, floor area, occupants, solar panels; percentiles | `energieverbruik/params.yaml` (`structuur`) | [`energieverbruik_update_structure()`](https://joris-klingen.github.io/simregdata/reference/energieverbruik_update_structure.md) | 85140NED | 2019-2025 |
| Dwelling count, district-heating share | `energieverbruik/params.yaml` (`n_dwellings`, `stadsverwarming_pct`) | [`energieverbruik_update_params()`](https://joris-klingen.github.io/simregdata/reference/energieverbruik_update_params.md) | Kerncijfers wijken en buurten (83765NED … 85618NED) | 2017-2023 |

Derived from fetched values: the RDW construction-year distribution for
2010-2018 (2019 distribution truncated, `.rdw_backcast_bouwjaar()`), and
the energy structure for years before 2019 (2019 structure scaled to the
national level of 81528NED, `.energy_structure()`).

### StatLine stated as source, entered by hand

| Parameter | File | Stated source | Note |
|----|----|----|----|
| Education level distributions (`opl_niveau_hb`, `opl_niveau_hg`) | `hoogsteopltab/params.yaml` | 82275NED (file header) | no fetch function |
| Personal income means/sd, SEC distribution | `inpatab/params.yaml` | 83931NED, 84493NED (file header) | no fetch function |
| RDW parameters 2010-2018 | `rdw/params.yaml` | none per year; same keys as the fetched years | rounded values, no fetch for these years |
| SPOLIS parameters 2010-2018 | `spolis/params.yaml` | none per year; same keys as the fetched years | no fetch for these years |
| Energy 2004-2016 (`n_dwellings`, `stadsverwarming_pct`), `solar_pv_share` (all years), `gas_sd`, `elek_sd` | `energieverbruik/params.yaml` | none | `gas_sd`/`elek_sd` are no longer used |
| Standard deviations derived as a share of the mean | `vehtab`, `spolis`, `energieverbruik` | coefficients of variation in the update functions | modelling choice |

### Constants in the R code

| Constant | Location | Controls | Source |
|----|----|----|----|
| `eigenaar_p`, `woningtype_p`, `bouwjaar_p`, `woz_p`, `opp_p`, `geslacht_p`, `soortobj_p`, `vslsoort_p` | `R/params_woonbase.R` (defaults) | owner type, dwelling type, construction-year and floor-area class shares, WOZ class, sex, object and VSL type | **unknown** |
| `.REF_TYPHH_P` | `R/spine.R` | household-type shares for the year-invariant spine | **unknown** (close to 71486ned) |
| `.FIXED_AVG_HH_SIZE` (2.15) | `R/spine.R` | households per person in the spine | **unknown** (close to StatLine average household size) |
| Household size per type, moves per mover | `R/spine.R` (`HHSize`, `AantalKeerVerhuisd`) | household size within type, number of moves | **unknown** |
| `.OPP_BY_TYPE` | `R/spine.R` | starting pattern of floor area per dwelling type, fitted to `opp_p` | modelling choice |
| Apartment and owner shares per gemeente (fallback) | `R/params_woonbase.R` | formula on gemeente rank, used because `housing_gem.csv` (71446ned) is absent | modelling choice |
| `.DEMOG` (lifespans, migration shares) | `R/demographics.R` | birth, death and migration events | modelling choice, “approximate” per the file header |
| Household income: lognormal per type, WOZ copula (`rho = 0.5`), noise sd’s | `R/params_inhatab.R` | shape around the fetched 83932NED means and medians | modelling choice |
| `.GAS_MONTH_P`, `.ELEK_MONTH_P`, `.ZON_MONTH_P`, tariff shares, `.GASLOOS_VANAF`, all-electric share in new dwellings, block-heating share | `R/energy.R` | monthly profiles, high/low tariff, gas-free new dwellings | modelling choice |
| Solar capacity around 4 kWp | `R/energy.R` | `ZONVERMOGEN` | modelling choice |
| Structural shares: vehicles per owner, dropped (3%) and business-stock (2%) cars, owner types, non-GBA owners (2%) | `R/rdw_vehicles.R` | vehicle structure of RDWNPACT and VERKEERSPRESTATIE | modelling choice |
| Households with a loss (1%) or unknown income (1%) | `R/params_inhatab.R` | negative incomes and special codes in INHATAB (codes from the INHATAB documentation) | modelling choice |
| Vacant dwellings (1.5%), unknown floor area (0.5%) and WOZ (1%) | `R/dwellings_vacant.R` | dwellings without residents, class 9 | modelling choice |
| Heating-type, determination-method and empty-value shares | `R/energy.R` | `HOOFDVERWARMING31DEC`, `GASBRON`, `ELEKBRON`, empty `GAS`/`ELEK` | modelling choice |
| PHEV/HEV fleet shares by year | `R/params_rdw.R` | split of hybrids from petrol | stated: CBS publications “Meer dan 1 miljoen stekkerauto’s” (2025), “Wie rijdt er elektrisch?” (2023), RAI Kerncijfers |
| Job, period and SEC structure probabilities | `R/spolis_jobs.R`, `R/secm_periods.R` | jobs per person, periods per person | **unknown** |

### Distributions in the YAML column specs

Columns that are not taken from the spine or from `params.yaml` are
drawn from distributions written directly in
`inst/config/datasets/*/columns/*.yaml` (`random_categorical` with
`probs`, `random_numeric` with `mean`/`sd`/`min`/ `max`). Their source
is not documented column by column; the [column
overview](https://joris-klingen.github.io/simregdata/articles/column-overview.md)
lists each column with its generator.

| Dataset                 | Categorical | Numeric | Of which via `params.yaml` |
|-------------------------|-------------|---------|----------------------------|
| woonbase                | 32          | 97      | 0                          |
| spolis                  | 52          | 70      | 21                         |
| inpatab                 | 5           | 19      | 13                         |
| rdw                     | 11          | 4       | 9                          |
| zonnestroominstallaties | 4           | 17      | 2                          |
| vehtab                  | 0           | 15      | 30 references              |
| hoogsteopltab           | 10          | 0       | 2                          |
| secmbus                 | 9           | 0       | 0                          |
| inhatab                 | 6           | 10      | 0                          |
| betab                   | 4           | 0       | 3                          |
| energieverbruik         | 4           | 0       | 0                          |
| gba                     | 0           | 2       | 0                          |

Parameter files without any documented source: `betab/params.yaml`
(business-size distribution), `secmbus/params.yaml` (SEC distribution),
`zonnestroominstallaties/params.yaml` (installations, capacity, yield),
`burennetwerktab`, `colleganetwerktab`, `familienetwerktab` (relations
per person, relation-type shares).

## To confirm by the author

For each item: was it taken from a public source (which), chosen as a
plausible value, or computed in Remote Access? Anything computed in
Remote Access must either have passed CBS output checking or be replaced
before the repository is public.

1.  Woonbase defaults in `R/params_woonbase.R`: `eigenaar_p`,
    `woningtype_p`, `bouwjaar_p`, `woz_p`, `opp_p`, `soortobj_p`,
    `vslsoort_p`.
2.  `.REF_TYPHH_P`, `.FIXED_AVG_HH_SIZE` and the household-size
    probabilities in `R/spine.R`.
3.  Hand-entered parameter files: `hoogsteopltab` and `inpatab` (stated
    StatLine sources, but entered by hand), RDW and SPOLIS 2010-2018,
    energieverbruik before 2017 and `solar_pv_share`.
4.  Parameter files without a stated source: `betab`, `secmbus`,
    `zonnestroominstallaties`, and the three network datasets.
5.  Job and period structure in `R/spolis_jobs.R` and
    `R/secm_periods.R`.
6.  The hardcoded `probs` and `mean`/`sd` values in the YAML column
    specs (above), in particular the 129 in woonbase and 122 in spolis.
