# Implementation Plan: Tier 1 & 2 CBS Microdata Datasets

## Overview

Six new datasets to add, grouped by priority:

| Tier | Dataset | CBS Name | Unit | Key | Cols | Links to |
|------|---------|----------|------|-----|------|----------|
| 1 | INPATAB | INPATAB | person | RINPERSOON | ~103 | spine (person), INHATAB (via HKW) |
| 1 | HOOGSTEOPLTAB | HOOGSTEOPLTAB | person | RINPERSOON | 16 | spine (person) |
| 1 | SECMBUS | SECMBUS | person-month | RINPERSOON | ~25 | spine (person), like SPOLIS bus-type |
| 2 | INHATAB | INHATAB | household | RINPERSOONHKW | 27 | spine (household via HKW) |
| 2 | VEHTAB (vermogen) | VEHTAB | household | RINPERSOONHKW | 20 | spine (household via HKW) |
| 2 | BETAB | BETAB | business | BEID | 7 | SPOLIS (via SBEID) |

---

## Architecture decisions ----

### Spine strategy

- **INPATAB, HOOGSTEOPLTAB**: `spine_builder: generic`, entity: person. Sample persons from shared spine's `pers` table, one row per person per year. Straightforward — same pattern as GBA person-level files.

- **SECMBUS**: `spine_builder: generic`, entity: person. Monthly bus-type like SPOLIS, but simpler: one row per person-period (not per job). Needs start/end date expansion. Reuse the monthly expansion logic but without the multi-job structure.

- **INHATAB, VEHTAB**: `spine_builder: generic`, entity: household. New pattern — needs **household-level** sampling. These link via `RINPERSOONSHKW + RINPERSOONHKW` (the household head's RINPERSOON). Implementation: sample unique households from the shared spine's `hh` table, generate a deterministic HKW ID per household.

- **BETAB**: `spine_builder: generic`, entity: business. Links to SPOLIS via `BEID`. Implementation: generate a lookup table of unique BEIDs from the SPOLIS spine. Each BEID gets SBI codes and size class. Only useful when SPOLIS is also initialized.

### Household key (HKW) mechanism

INHATAB and VEHTAB use `RINPERSOONSHKW` + `RINPERSOONHKW` as the household identifier (the income/wealth statistics household number, based on the main earner). This is different from the woonbase `HUISHOUDNR`.

**Plan**: Add a `.deterministic_hkw_id()` function (similar to `.deterministic_job_id()`) that maps each unique `HUISHOUDNR` to a stable `RINPERSOONHKW`. The `RINPERSOONSHKW` is always `"R"`. Also need a `KOPPELPERSOONHUISHOUDEN` linking file (maps RINPERSOON ↔ RINPERSOONHKW). This linking file should be generated automatically when INHATAB or VEHTAB is initialized.

### SECMBUS monthly expansion

SECMBUS records have `AANVSECM` (start date) and `EINDSECM` (end date) defining periods. Unlike SPOLIS (one row per job-month), SECMBUS has one row per person-period where the socioeconomic category is constant. Most people have 1-2 records per year (e.g., employed all year = 1 record; employed then unemployed = 2 records).

**Plan**: Build a `.build_secm_periods()` function that:
1. Assigns each person a primary SECM category
2. ~80% have 1 period (stable), ~15% have 2 periods (transition), ~5% have 3+ periods
3. Period dates are contiguous and cover Jan 1 - Dec 31
4. SECM transitions follow realistic patterns (e.g., employed→unemployed, not the reverse typically in a single year)

---

## Tier 1 datasets ----

### 1. INPATAB (Personal income)

**Source**: CBS documentation, 103 variables, available 2011-2020+

**Config structure**:
```
inst/config/datasets/inpatab/
  manifest.yaml
  columns/inpatab.yaml
  params.yaml          # income distributions by year
  codelists.yaml       # INPSECJ codes, percentile labels
```

**Key columns to implement** (prioritized subset of ~103):

| Column | Format | Type | Description |
|--------|--------|------|-------------|
| RINPERSOONS | A1 | source | Person ID prefix ("R") |
| RINPERSOON | A9 | source | Person ID from spine |
| RINPERSOONSHKW | A1 | computed | HKW prefix ("R") |
| RINPERSOONHKW | A9 | computed | Household head ID (deterministic from HUISHOUDNR) |
| INPPERSINK | F10 | random_numeric (normal) | Personal income |
| INPPERSPRIM | F10 | random_numeric | Primary income (wages + self-employment) |
| INPPERSBRUT | F10 | computed | Gross income |
| INPPERSBESTINK | F10 | computed | Disposable personal income |
| INPSECJ | A2 | random_categorical | Socioeconomic category (annual) |
| INPBELI | F10 | random_numeric | Taxable income |
| INPT* (transfers) | F10 | random_numeric | ~20 transfer income columns |
| INPP100PERSINK | F3 | computed | Income percentile |
| INPP100PERSBEST | F3 | computed | Disposable income percentile |

**Params** (from StatLine `83931NED` / `84493NED`):
- Mean/SD personal income by year
- INPSECJ distribution (employee, self-employed, pensioner, etc.)
- Income component shares (primary, transfers, taxes)

**Implementation steps**:
1. Create `inst/config/datasets/inpatab/manifest.yaml` with `spine_builder: generic`
2. Create `inst/config/datasets/inpatab/columns/inpatab.yaml` — start with ~30 most-used columns
3. Create `inst/config/datasets/inpatab/params.yaml` with income distributions from StatLine
4. Create `inst/config/datasets/inpatab/codelists.yaml` for INPSECJ
5. Add HKW ID generation to `R/spine.R` or new `R/household_key.R`
6. Register in existing architecture — no new R code needed beyond HKW

**Calibration sources**:
- StatLine 83931NED: Personen; inkomen
- StatLine 84493NED: Inkomen van personen, kenmerken

### 2. HOOGSTEOPLTAB (Education level)

**Source**: CBS documentation, 16 variables, available 1999-2024

**Config structure**:
```
inst/config/datasets/hoogsteopltab/
  manifest.yaml
  columns/hoogsteopltab.yaml
  codelists.yaml       # SOI2021 education levels, ISCED directions
```

**Key columns**:

| Column | Format | Type | Description |
|--------|--------|------|-------------|
| RINPERSOONS | A1 | source | "R" |
| RINPERSOON | A9 | source | Person ID |
| OPLNRHB | A6 | random_categorical | Education number (highest attained) |
| OPLNRHG | A6 | random_categorical | Education number (highest followed) |
| GEWICHTHOOGSTEOPL | F12.6 | constant/computed | Weight (1.0 for register, >1 for EBB) |
| OPLNIVSOI2021AGG4HBmetNIRWO | A4 | random_categorical | SOI2021 level attained (18 cats) |
| OPLNIVSOI2021AGG4HGmetNIRWO | A4 | random_categorical | SOI2021 level followed |
| RICHTSOI2021SCEDF2013HBNIRWO | A4 | random_categorical | ISCED-F direction attained |
| RICHTSOI2021SCEDF2013HGNIRWO | A4 | random_categorical | ISCED-F direction followed |
| BRONOPLARCHIEFHB | A2 | random_categorical | Source of attained education |
| BRONOPLARCHIEFHG | A2 | random_categorical | Source of followed education |
| RGEBB | A1 | random_categorical | Register/EBB indicator |
| OPLNIVSOI2016AGG4HBMETNIRWO | A4 | value (empty) | Deprecated (empty from 2019V2+) |
| OPLNIVSOI2016AGG4HGMETNIRWO | A4 | value (empty) | Deprecated |
| RICHTdetailISCEDF2013HBmetNIRWO | A4 | value (empty) | Deprecated |
| RICHTdetailISCEDF2013HGmetNIRWO | A4 | value (empty) | Deprecated |

**Key design decision**: The SOI2021AGG4 variable is the most commonly used. It has 18 categories mapping to education levels like:
- 1111 = basisonderwijs
- 1211 = vmbo-b/k
- 1212 = vmbo-g/t, havo/vwo onderbouw
- 1213 = mbo1
- 2111 = havo/vwo
- 2112 = mbo2/3
- 2120 = mbo4
- 3111 = hbo-bachelor
- 3112 = wo-bachelor
- 3211 = hbo-master
- 3212 = wo-master
- 3213 = doctor

OPLNRHB/HG are detailed 6-digit codes. For simulation, generate the SOI2021AGG4 level first, then derive a plausible OPLNRHB from a lookup table.

**Params** (from StatLine `82275NED`):
- Education level distribution by year (shares of each SOI category)
- Can correlate with age from spine if desired (older → lower education on average)

**Implementation steps**:
1. Create manifest, columns YAML, codelists
2. Build education distribution from StatLine data
3. All 16 columns can be handled by the generic assembly engine
4. No new R code needed — purely YAML-driven

### 3. SECMBUS (Socioeconomic category, monthly)

**Source**: CBS documentation, ~25 variables, monthly bus-type

**Config structure**:
```
inst/config/datasets/secmbus/
  manifest.yaml
  columns/secmbus.yaml
  codelists.yaml       # SECM categories
```

**Key columns**:

| Column | Format | Type | Description |
|--------|--------|------|-------------|
| RINPERSOONS | A1 | source | "R" |
| RINPERSOON | A9 | source | Person ID |
| AANVSECM | A8 | computed | Period start date (YYYYMMDD) |
| EINDSECM | A8 | computed | Period end date (YYYYMMDD) |
| SECM | A4 | random_categorical | Socioeconomic category code |
| XKOPPELBBAVBDZ | A1 | random_categorical | Income source indicator |
| XKOPPELBBARBEID | A1 | random_categorical | Employment income indicator |
| XKOPPELBBSZELF | A1 | random_categorical | Self-employment indicator |
| XKOPPELBBPENSIOEN | A1 | random_categorical | Pension income indicator |
| XKOPPELBBBIJSTUITK | A1 | random_categorical | Social assistance indicator |
| XKOPPELBBARBONGESCHUITK | A1 | random_categorical | Disability benefit indicator |
| XKOPPELBBWW | A1 | random_categorical | Unemployment benefit indicator |
| XKOPPELBBANDERUITK | A1 | random_categorical | Other benefit indicator |
| XKOPPELBBSTUDFINANC | A1 | random_categorical | Student finance indicator |
| ONDERWIJSNR_crypt | A? | random_id | Encrypted education number |

**Architecture**: Similar to SPOLIS but simpler. Need a period-expansion function.

**SECM categories** (main ones):
- 11 = Werknemer (employee)
- 12 = DGA (director-major shareholder)
- 13 = Zelfstandige (self-employed)
- 14 = Overig actief (other active)
- 21 = Ontvanger WW (unemployment benefit)
- 22 = Ontvanger bijstand (social assistance)
- 23 = Ontvanger AO-uitkering (disability)
- 24 = Ontvanger overige uitkering (other benefit)
- 25 = Pensioen (pension)
- 26 = Student/scholier
- 31 = Overig zonder inkomen

**New R code needed**: `R/secm_periods.R`
- `.build_secm_periods(spine_pers, year, seed)` — generates period rows per person
- Most people: 1 period covering full year
- Some people: 2-3 periods with transitions
- XKOPPEL indicators derived from SECM category

**Implementation steps**:
1. Create `R/secm_periods.R` with period builder
2. Add SECM branch in `R/api.R` (like SPOLIS branch)
3. Create manifest, columns YAML, codelists, params
4. XKOPPEL columns: deterministic from SECM (e.g., employee → XKOPPELBBARBEID=1)
5. Period dates: contiguous, covering Jan 1 – Dec 31

---

## Tier 2 datasets ----

### 4. INHATAB (Household income)

**Source**: CBS documentation, 27 variables, available 2011-2020+

**Config structure**:
```
inst/config/datasets/inhatab/
  manifest.yaml
  columns/inhatab.yaml
  params.yaml          # household income distributions
  codelists.yaml       # percentile labels, household types
```

**Key columns**:

| Column | Format | Type | Description |
|--------|--------|------|-------------|
| RINPERSOONSHKW | A1 | value | "R" |
| RINPERSOONHKW | A9 | source | Household head ID |
| INHAHL | F2 | source | Household size |
| INHAHLMI | F2 | random_numeric | Members with income |
| INHBESTINKH | F10 | random_numeric (normal) | Disposable household income |
| INHGESTINKH | F10 | random_numeric | Standardized household income |
| INHBRUTINKH | F10 | random_numeric | Gross household income |
| INHPRIMINKH | F10 | random_numeric | Primary household income |
| INHBELIH | F10 | random_numeric | Tax burden |
| INHBBIHJ | A2 | random_categorical | Social assistance type |
| INHP100HBEST | F3 | computed | Disposable income percentile |
| INHP100HGEST | F3 | computed | Standardized income percentile |
| INHP100HBRUT | F3 | computed | Gross income percentile |
| INHP100HPRIM | F3 | computed | Primary income percentile |
| INHP100HBESTES | F3 | computed | Standardized disposable percentile |
| INHP100HGESTES | F3 | computed | Standardized standardized percentile |
| INHARMEUR | F3 | computed | Income vs European poverty line (%) |
| INHARMEURL | F3 | computed | Longitudinal European poverty |
| INHARMLAG | F3 | computed | Income vs low-income threshold (%) |
| INHARMLAGL | F3 | computed | Longitudinal low-income |
| INHARMSOC | F3 | computed | Income vs social minimum (%) |
| INHARMSOCL | F3 | computed | Longitudinal social minimum |
| INHEHALGR | A1 | random_categorical | Main income earner indicator |
| INHPOPIIV | A1 | random_categorical | Household type (private/institutional) |
| INHSAMAOW | A2 | random_categorical | AOW composition |
| INHSAMHH | A2 | random_categorical | Household composition |
| INHUAF | F3 | computed | UAF indicator |
| INHUAFL | F3 | computed | Longitudinal UAF |
| INHUAFTYP | A1 | random_categorical | UAF type |

**Architecture**: Household-level. Needs HKW mechanism (shared with VEHTAB).

**Params** (from StatLine `83932NED`):
- Mean/SD household income by year
- Income distributions by household type

**Implementation steps**:
1. Implement HKW ID generation (shared prerequisite with VEHTAB)
2. Create manifest with `spine_builder: generic`, entity: household
3. Add household-sampling branch in `R/api.R`
4. Income amounts: correlate with household size from spine
5. Percentiles: rank-based assignment after generating income values

### 5. VEHTAB — vermogen (Household wealth)

**Source**: CBS documentation, 20 variables, available 2006-2024

**Config structure**:
```
inst/config/datasets/vehtab_vermogen/
  manifest.yaml
  columns/vehtab.yaml
  params.yaml          # wealth distributions
  codelists.yaml       # percentile labels
```

**Note**: Dataset ID should be `vehtab_vermogen` to distinguish from the existing `vehtab` (vehicle registration) dataset already in the package.

**Key columns**:

| Column | Format | Type | Description |
|--------|--------|------|-------------|
| RINPERSOONSHKW | A1 | value | "R" |
| RINPERSOONHKW | A9 | source | Household head ID |
| VEHP100WELVAART | F3 | computed | Welfare percentile (1-100) |
| VEHP100HVERM | F3 | computed | Wealth percentile (1-100) |
| VEHW1000VERH | F11 | random_numeric | Total household wealth |
| VEHW1100BEZH | F11 | computed | Total assets |
| VEHW1110FINH | F11 | computed | Financial assets |
| VEHW1111BANH | F11 | random_numeric (lognormal) | Bank/savings |
| VEHW1112EFFH | F11 | random_numeric (lognormal) | Securities/stocks |
| VEHW1120ONRH | F11 | computed | Real estate total |
| VEHW1121WONH | F11 | random_numeric | Owner-occupied housing value |
| VEHW1122OGOH | F11 | random_numeric | Other real estate |
| VEHW1130ONDH | F11 | random_numeric | Business assets |
| VEHW1140ABEH | F11 | random_numeric | Substantial holdings |
| VEHW1150OVEH | F11 | random_numeric | Other assets |
| VEHW1200STOH | F11 | computed | Total debts |
| VEHW1210SHYH | F11 | random_numeric | Mortgage debt |
| VEHW1220SSTH | F11 | random_numeric | Student debt |
| VEHW1230SOVH | F11 | random_numeric | Other debts |
| VEHWVEREXEWH | F11 | computed | Wealth excluding own home |

**Architecture**: Same HKW mechanism as INHATAB.

**Key design**: Wealth has a hierarchical structure:
- `VEHW1000VERH` = `VEHW1100BEZH` - `VEHW1200STOH` (assets - debts)
- `VEHW1100BEZH` = `VEHW1110FINH` + `VEHW1120ONRH` + `VEHW1130ONDH` + `VEHW1140ABEH` + `VEHW1150OVEH`
- `VEHW1110FINH` = `VEHW1111BANH` + `VEHW1112EFFH`
- etc.

Generate leaf components first (bank, stocks, housing, mortgage, etc.), then compute aggregates. Use lognormal distributions for wealth components. Missing value sentinel: `99999999999`.

**Params** (from StatLine `83834NED`):
- Wealth component distributions by year
- Share of homeowners, mortgage holders

**Implementation steps**:
1. Uses same HKW mechanism as INHATAB
2. Generate leaf wealth components with lognormal distributions
3. Build computed aggregates in a pre_compute chain
4. Assign percentiles by ranking
5. Handle missing values (99999999999 for unobserved)

### 6. BETAB (Business register)

**Source**: CBS documentation, 7 variables, available 1999-2025

**Config structure**:
```
inst/config/datasets/betab/
  manifest.yaml
  columns/betab.yaml
  codelists.yaml       # SBI codes, GKSBS size classes, GK classes
```

**Key columns**:

| Column | Format | Type | Description |
|--------|--------|------|-------------|
| BEID | A8 | source | Business unit ID (= SBEID from SPOLIS) |
| SBI2008VJJJJ | A5 | random_categorical | SBI 2008 activity code |
| SBI2025VJJJJ | A5 | random_categorical | SBI 2025 activity code |
| SBI1993VJJJJ | A5 | random_categorical | SBI 1993 activity code (legacy) |
| GKSBS | A2 | random_categorical | EU size class (16 categories) |
| GEMHVJJJJ | A4 | random_categorical | Municipality of main establishment |
| GK | A1 | random_categorical | Size class by employees (10 categories, legacy) |

**Architecture**: Business-level entity. Unique row per BEID.

**Key design**: BETAB is a lookup table for businesses that appear in SPOLIS. The `BEID` matches `SBEID` in SPOLIS.

**Option A** (independent): Generate standalone BETAB with random BEIDs
**Option B** (linked): Generate BETAB from SPOLIS's unique SBEIDs

Recommend **Option B**: When SPOLIS is initialized, collect unique SBEIDs and store them. When BETAB is initialized, use those SBEIDs as the BEID population. If SPOLIS isn't initialized, fall back to random generation.

**Implementation steps**:
1. Create manifest with `spine_builder: generic`, entity: business
2. Add business-sampling branch in `R/api.R`
3. SBI codes: use realistic top-level distribution from StatLine
4. GKSBS: realistic size class distribution (most are small businesses)
5. GEMHVJJJJ: sample from municipality codes in spine

---

## Shared infrastructure needed ----

### 1. HKW ID generation (`R/household_key.R`)

New file with:
- `.deterministic_hkw_id(huishoudnr)` — maps HUISHOUDNR → RINPERSOONHKW (9-digit)
- Uses `rlang::hash()` like `.deterministic_job_id()`
- Needed by: INPATAB, INHATAB, VEHTAB (vermogen)

### 2. Period expansion for SECMBUS (`R/secm_periods.R`)

New file with:
- `.build_secm_periods(spine_pers, year, seed)` — generates period rows
- Simpler than SPOLIS: no multi-job, just person-period transitions
- Returns data.table with RINPERSOON, period_start, period_end, SECM, period_group

### 3. Household-level sampling in `R/api.R`

New branch for household-entity datasets:
- Sample unique households from spine's `hh` table
- Generate HKW IDs
- Build `ds_spine$hh` with household-level attributes

### 4. Business-level sampling in `R/api.R`

New branch for business-entity datasets:
- Either pull unique BEIDs from SPOLIS cache, or generate random ones
- Build `ds_spine$biz` with one row per business

---

## Implementation order ----

Recommended sequence (dependencies marked):

1. **HKW infrastructure** — needed by INPATAB, INHATAB, VEHTAB
2. **HOOGSTEOPLTAB** — simplest (person-level, 16 cols, all categorical, no new R code)
3. **INPATAB** — person-level, many columns but straightforward assembly
4. **SECMBUS** — needs period builder (new R code), moderate complexity
5. **INHATAB** — depends on HKW, household-level sampling
6. **VEHTAB (vermogen)** — depends on HKW, hierarchical wealth computation
7. **BETAB** — depends on SPOLIS, business-level sampling

Estimated new files:
- 6 × manifest.yaml
- 6 × columns/*.yaml
- 4 × codelists.yaml
- 3 × params.yaml
- 2 new R source files (household_key.R, secm_periods.R)
- Modifications to R/api.R (household + business branches)
- Additions to R/globals.R (new NSE variables)
