Calibration overview
================

## What does “calibrated” mean?

simcbsradata distinguishes several levels of column realism:

| Level                     | Description                                                                                                                                   | Changes across years? |
|---------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------|-----------------------|
| **StatLine-calibrated**   | Marginal distribution downloaded from CBS StatLine and stored in `params.yaml`. Updated with `*_update_params()`.                             | Yes                   |
| **Spine-derived**         | Value copied from the woonbase spine, which itself is built from StatLine-calibrated parameters.                                              | Yes (via spine)       |
| **Stable per identifier** | Deterministic value per entity (e.g. per RINKENTEKEN) via multiplicative hashing. Year-stable — same identifier always yields the same value. | No                    |
| **Codelist-labelled**     | Categorical column with hardcoded probabilities and CBS codelist labels. Plausible but not matched to any specific year.                      | No                    |
| **Random numeric**        | Drawn from a hardcoded normal/lognormal distribution. Mean/SD are plausible but not empirically calibrated.                                   | No                    |
| **Random uniform**        | Drawn from a uniform range. Fills structural requirements only.                                                                               | No                    |
| **Constant/template**     | Fixed value (e.g., `"R"`, `" "`, `"01"`).                                                                                                     | No                    |

The tables below classify every column across all 15 datasets.

## Summary: StatLine-calibrated parameters

| Parameter                                      | Dataset                 | CBS table           | Simulated column(s)             |
|------------------------------------------------|-------------------------|---------------------|---------------------------------|
| Population size (`n_persons`)                  | Woonbase                | 37230ned            | Controls spine row count        |
| Household count (`n_hh`)                       | Woonbase                | 71486ned            | Controls HH count in spine      |
| HH-type distribution (`typhh_p`)               | Woonbase                | 71486ned            | TYPHH in all file types         |
| Gemeente population weights                    | Woonbase                | 37230ned            | GemeenteCode sampling probs     |
| Vehicle fleet size (`n_vehicles`)              | RDW                     | 85236NED            | Controls RDW row count          |
| Gemeente vehicle weights                       | RDW                     | 85236NED + 37230ned | Spine sampling probs per gem    |
| Fuel type (`brandstof_p`)                      | RDW                     | 85237NED            | BRANDSTCODECORVRTG              |
| Vehicle colour (`kleur_p`)                     | RDW                     | 85237NED            | KLEURCODEVRTG                   |
| Vehicle weight (`gewicht_mean/sd`)             | RDW                     | 85237NED            | MASSALEEGCORVRTG                |
| Vehicle type (`vrtgsoort_p`)                   | RDW                     | 85236NED            | VRTGSOORT                       |
| Construction year (`bouwjaar_p`)               | RDW                     | 85237NED            | EERSTETOELDAT1VRTG              |
| Annual km (`jaarkm_mean/sd`)                   | RDW                     | 85404NED            | VPJAARKM                        |
| Job count (`n_jobs`)                           | SPOLIS                  | 85275NED            | Controls SPOLIS row count       |
| Household count (`n_households`)               | VEHTAB                  | (woonbase)          | Controls VEHTAB row count       |
| Dwelling count (`n_dwellings`)                 | Energieverbruik         | (woonbase)          | Controls row count              |
| Gas consumption (`gas_mean/sd`)                | Energieverbruik         | CBS energy stats    | GAS                             |
| Electricity (`elek_mean/sd`)                   | Energieverbruik         | CBS energy stats    | ELEK                            |
| Solar PV share (`solar_pv_share`)              | Energieverbruik         | CBS energy stats    | ZONPV                           |
| Education level (`opl_niveau_hb/hg`)           | HOOGSTEOPLTAB           | 82275NED            | OPLNIVSOI2021AGG4HBmetNIRWO, HG |
| Personal income (`secj_dist`, income means)    | INPATAB                 | 83931NED, 84493NED  | INPSECJ, INPPERSINK, etc.       |
| Household income (income means)                | INHATAB                 | 83932NED            | INHBESTINKH, INHBRUTINKH, etc.  |
| SEC monthly (`secm_dist`)                      | SECMBUS                 | (implicit)          | SECM                            |
| SBI sector (`sbi2008_dist`)                    | BETAB                   | (implicit)          | SBI2008VJJJJ                    |
| Business size (`gksbs_dist`)                   | BETAB                   | (implicit)          | GKSBS                           |
| PV installations (`n_installations`, capacity) | Zonnestroominstallaties | (implicit)          | Vermogen_panelen                |
| Network relation counts                        | Buren/Collega/Familie   | (implicit)          | Row count per person            |

## Per-dataset column classification

### Woonbase (9 files, ~183 columns)

The shared population spine is the foundation for all datasets, built
from woonbase parameters. Three things are StatLine-calibrated:

| What                 | CBS table | params.yaml key   |
|----------------------|-----------|-------------------|
| National population  | 37230ned  | `n_persons`       |
| National HH count    | 71486ned  | `n_hh`            |
| HH-type distribution | 71486ned  | `typhh_p`         |
| Gemeente weights     | 37230ned  | `gem_weights.csv` |

**Spine-derived columns** (present across multiple files, calibrated via
spine):

- `RINPERSOON`, `RINPERSOONS` – person identifiers
- `HUISHOUDNR1Jan` – household identifier
- `RINOBJECTNUMMER`, `SOORTOBJECTNUMMER` – object identifiers
- `GBAGeboorteJaar1Jan` – birth year (from spine age distribution)
- `GBAGeslachtsAanduiding1Jan` – sex (spine: ~50/50)
- `TYPHH1Jan` – household type (**StatLine-calibrated**)
- `AantalPersonenPerHuishouden1Jan` – HH size (derived from TYPHH)
- `GemeenteCodeJJJJ1Jan` – municipality (**StatLine-calibrated**)
- `VBOWoningType1Jan` – dwelling type (fixed distribution)
- `VBOBouwjaar1Jan` – construction year (fixed distribution)
- `VBOOppervlakte1Jan` – floor area (fixed distribution)
- `WOZWaardeObjectBAG1Jan` – WOZ value (fixed distribution)
- `TypeEigenaar1Jan` – owner type (fixed distribution)

**Codelist-labelled columns** (hardcoded probabilities):

- `PLHH1Jan` – position in household
- `OplNivCBS1Jan`, `OplNivSOI1Jan` – education level
- `GBABURGELIJKESTAAT1Jan` – civil status
- `HHBWoonSit1Jan` – living situation
- All `*Klasse*` columns – categorical class versions

**Random numeric / uniform** (NOT calibrated):

- `BESTINKH1JAN`, `INKONTV1JAN`, etc. – income components (EK files)
- `P100HBEST1JAN` – income percentile (uniform 1-100)
- `VERMHH1JAN`, `SCHULDHH1JAN` – wealth/debt (random normal)
- `LeeftijdRefPersoon1Jan` – ref person age (derived)
- `AantalKinderenPerHuishouden1Jan` – children count (derived)

### GBA (3 files, ~23 columns)

The GBA (Gemeentelijke Basisadministratie / BRP) is the population
register. All columns are **spine-derived** – they read directly from
the shared population spine, which itself is calibrated via woonbase
parameters.

#### GBAPERSOONTAB

| Column                        | Level          | Source                  |
|-------------------------------|----------------|-------------------------|
| RINPERSOONS                   | Constant       | Always `"R"` (labelled) |
| RINPERSOON                    | Spine-derived  | Person identifier       |
| GBAGEBOORTEJAAR               | Spine-derived  | Birth year from spine   |
| GBAGEBOORTEMAAND              | Random uniform | 1-12                    |
| GBAGEBOORTELAND               | Codelist       | Hardcoded probs         |
| GBAGESLACHT                   | Spine-derived  | Sex from spine          |
| GBAAANTALOUDERSBUITENLAND     | Codelist       | Hardcoded probs         |
| GBAGENERATIE                  | Codelist       | Hardcoded probs         |
| GBAHERKOMSTGROEPERING         | Codelist       | Hardcoded probs         |
| GBAGEBOORTELANDMOEDER         | Codelist       | Hardcoded probs         |
| GBAGEBOORTELANDVADER          | Codelist       | Hardcoded probs         |
| GBADATUMAANVANGHUIDIGVERBLIJF | Spine-derived  | From AanvangWoonduur    |
| GBADATUMVESTIGINGINNEDERLAND  | Codelist       | Hardcoded probs         |
| GBADATUMOVERLIJDEN            | Constant       | `"00000000"`            |
| GBADATUMEMIGRATIE             | Constant       | `"00000000"`            |
| GBABURGERLIJKESTAAT           | Spine-derived  | Civil status from spine |

#### GBAADRESOBJECTBUS

| Column                                    | Level          | Source                                 |
|-------------------------------------------|----------------|----------------------------------------|
| RINPERSOONS                               | Constant       | Always `"R"` (labelled)                |
| RINPERSOON                                | Spine-derived  | Person identifier                      |
| SOORTOBJECTNUMMER                         | Spine-derived  | Object type from spine                 |
| RINOBJECTNUMMER                           | Spine-derived  | Object identifier from spine           |
| GBADATUMAANVANGADRESHOUDING               | Spine-derived  | From AanvangWoonduur                   |
| GBADATUMEINDEADRESHOUDING                 | Constant       | `"99999999"`                           |
| GBAGEMEENTEVANINSCHRIJVING                | Spine-derived  | Municipality from spine (pers_spatial) |
| GBAAANTALINGESCHREVENENOPNUMMERAANDUIDING | Random numeric | Hardcoded mean/sd                      |

#### GBAHUISHOUDENSBUS

| Column      | Level         | Source                                      |
|-------------|---------------|---------------------------------------------|
| RINPERSOONS | Constant      | Always `"R"` (labelled)                     |
| RINPERSOON  | Spine-derived | Person identifier                           |
| HUESSION    | Spine-derived | Household number from spine                 |
| DAESSION    | Spine-derived | HH start date from spine                    |
| TYPHH       | Spine-derived | HH type (**StatLine-calibrated** via spine) |
| PLESSION    | Spine-derived | Position in HH from spine                   |
| AANESSION   | Spine-derived | HH size from spine                          |
| REFESSION   | Spine-derived | Ref person indicator from spine             |

### RDW (2 files, ~19 columns)

Vehicle characteristics use `stable_per: RINKENTEKEN` — values are
deterministic per license plate via multiplicative hashing, ensuring
year-stability.

#### RDWNPACT (kentekens)

| Column                | Level                              | Source                                    |
|-----------------------|------------------------------------|-------------------------------------------|
| RINPERSOONS           | Constant                           | Always `"R"`                              |
| RINPERSOON            | Spine-derived                      | From woonbase person spine                |
| SOORTENTITEITTAB      | Constant                           | Always `1`                                |
| RINKENTEKEN           | Stable per person                  | Deterministic from RINPERSOON via hashing |
| VRTGSOORT             | **StatLine** + stable per kenteken | `vrtgsoort_p` (85236NED)                  |
| BRANDSTCODECORVRTG    | **StatLine** + stable per kenteken | `brandstof_p` (85237NED)                  |
| MASSALEEGCORVRTG      | **StatLine** + stable per kenteken | `gewicht_mean/sd` (85237NED)              |
| KLEURCODEVRTG         | **StatLine** + stable per kenteken | `kleur_p` (85237NED)                      |
| EERSTETOELDAT1VRTG    | **StatLine** + stable per kenteken | `bouwjaar_p` (85237NED)                   |
| MODELCODEVRTG         | Codelist                           | Hardcoded probs                           |
| INRICHTINGCODEVRTG    | Codelist                           | Hardcoded probs                           |
| TYPENATUURLIJKPERSOON | Constant                           | Always `1`                                |
| TYPERECHTSPERSOON     | Constant                           | Always `""`                               |

Car turnover: ~12%/year. Ownership duration is deterministic per person
(3-10 years), and a new RINKENTEKEN is generated per ownership
generation.

#### VERKEERSPRESTATIE

| Column              | Level          | Source                      |
|---------------------|----------------|-----------------------------|
| RinpersoonVP        | Spine-derived  | From RDWNPACT               |
| RINKENTEKEN         | Spine-derived  | Consistent with RDWNPACT    |
| VPJAARKM            | **StatLine**   | `jaarkm_mean/sd` (85404NED) |
| VPMAANDKM01-12      | Random uniform | Hardcoded range             |
| VPBRANDSTOFVERBRUIK | Random numeric | Hardcoded mean/sd           |

### SPOLIS (1 file, 133 columns)

**Calibrated:**

- Row count (`n_jobs`) from CBS 85275NED

**Spine-derived:**

- `RINPERSOON`, `RINPERSOONS` – from woonbase person spine

**NOT calibrated** (all 131 remaining columns):

- All wage columns (`SVLOON`, `SBASISLOON`, `SLNINGLD`, etc.) – random
  normal
- All days/hours columns (`SDAGENMET`, `SVOLTIJDDAGEN`, etc.) – random
  normal
- All categorical columns (`SCONTRACTSOORT`, `SCAO`, `SPOLESSION`, etc.)
  – codelist-labelled with hardcoded probs
- All SBI sector codes (`SSBI2008V*`) – codelist-labelled
- All amount columns (`SBIJZONDEREBELONING`, `SEXTRSAL`, etc.) – random
  normal

### INPATAB (1 file, 28 columns)

Personal income register. Several income aggregates are
StatLine-calibrated.

| Column                                                                            | Level              | Source                                                   |
|-----------------------------------------------------------------------------------|--------------------|----------------------------------------------------------|
| RINPERSOONS                                                                       | Constant           | Always `"R"`                                             |
| RINPERSOON                                                                        | Spine-derived      | Person identifier                                        |
| RINPERSOONSHKW                                                                    | Constant           | Always `"R"`                                             |
| RINPERSOONHKW                                                                     | Spine-derived      | Ref person from spine HH                                 |
| INPSECJ                                                                           | **StatLine**       | `secj_dist` (83931NED) – 11 employment status categories |
| INPPERSINK                                                                        | **StatLine**       | Personal income mean/sd (84493NED)                       |
| INPPERSPRIM                                                                       | **StatLine**       | Primary income mean/sd                                   |
| INPPERSBRUT                                                                       | **StatLine**       | Gross income mean/sd                                     |
| INPPERSBESTINK                                                                    | **StatLine**       | Disposable income mean/sd                                |
| INPPERSGESTINK                                                                    | **StatLine**       | Standardised income mean/sd                              |
| INPLHP, INPWINST, INPUITKERINGS, INPPENSINK, INPTRANSFER, INPPREMVV, INPBELASTING | Random numeric     | Hardcoded mean/sd                                        |
| INPP100PERSINK, INPP100PERSBEST, INPP100PERSPRIM                                  | Random uniform     | Percentiles 1-100                                        |
| INPARMLAG, INPARMSOC, INPARMEUR                                                   | Random categorical | Poverty indicators                                       |
| INPPOPIIV, INPSAMHH, INPSAMAOW                                                    | Codelist           | Hardcoded probs                                          |
| INPSTUDFIN                                                                        | Random categorical | Student finance indicator                                |

### INHATAB (1 file, 29 columns)

Household income register. Five income aggregates are
StatLine-calibrated.

| Column                                                                                 | Level              | Source                               |
|----------------------------------------------------------------------------------------|--------------------|--------------------------------------|
| RINPERSOONSHKW                                                                         | Constant           | Always `"R"`                         |
| RINPERSOONHKW                                                                          | Spine-derived      | Ref person from spine HH             |
| INHBESTINKH                                                                            | **StatLine**       | Disposable income mean/sd (83932NED) |
| INHBRUTINKH                                                                            | **StatLine**       | Gross income mean/sd                 |
| INHGESTINKH                                                                            | **StatLine**       | Standardised income mean/sd          |
| INHPRIMINKH                                                                            | **StatLine**       | Primary income mean/sd               |
| INHBELIH                                                                               | **StatLine**       | Taxable income mean/sd               |
| INHP100HBEST, INHP100HBESTES, INHP100HBRUT, INHP100HGEST, INHP100HGESTES, INHP100HPRIM | Random uniform     | Income percentiles 1-100             |
| INHAHL, INHAHLMI                                                                       | Random numeric     | Hardcoded mean/sd                    |
| INHARMEUR, INHARMEURL, INHARMLAG, INHARMLAGL, INHARMSOC, INHARMSOCL                    | Random numeric     | Poverty thresholds                   |
| INHPOPIIV, INHSAMHH, INHSAMAOW                                                         | Codelist           | Hardcoded probs                      |
| INHBBIHJ                                                                               | Random categorical | Income class                         |
| INHEHALGR                                                                              | Random categorical | Income source group                  |

### HOOGSTEOPLTAB (1 file, 16 columns)

Highest attained education level. Education distributions are
StatLine-calibrated.

| Column                             | Level              | Source                                               |
|------------------------------------|--------------------|------------------------------------------------------|
| RINPERSOONS                        | Constant           | Always `"R"`                                         |
| RINPERSOON                         | Spine-derived      | Person identifier                                    |
| OPLNIVSOI2021AGG4HBmetNIRWO        | **StatLine**       | `opl_niveau_hb` (82275NED) – 18 education categories |
| OPLNIVSOI2021AGG4HGmetNIRWO        | **StatLine**       | `opl_niveau_hg` (82275NED)                           |
| RICHTSOI2021SCEDF2013HBNIRWO       | Codelist           | Study direction (hardcoded probs)                    |
| RICHTSOI2021SCEDF2013HGNIRWO       | Codelist           | Study direction (hardcoded probs)                    |
| BRONOPLARCHIEFHB, BRONOPLARCHIEFHG | Codelist           | Data source indicator                                |
| RGEBB                              | Codelist           | Registration region                                  |
| OPLNRHB, OPLNRHG                   | Random categorical | Education record number                              |
| GEWICHTHOOGSTEOPL                  | Random numeric     | Survey weight                                        |
| OPLNIVSOI2016AGG4HBMETNIRWO        | Constant           | `"----"` (discontinued)                              |
| OPLNIVSOI2016AGG4HGMETNIRWO        | Constant           | `"----"` (discontinued)                              |
| RICHTdetailISCEDF2013HBmetNIRWO    | Constant           | `"----"` (discontinued)                              |
| RICHTdetailISCEDF2013HGmetNIRWO    | Constant           | `"----"` (discontinued)                              |

### SECMBUS (1 file, 15 columns)

Socioeconomic category, monthly periods. The main SEC code is
StatLine-calibrated.

| Column                | Level              | Source                             |
|-----------------------|--------------------|------------------------------------|
| RINPERSOONS           | Constant           | Always `"R"`                       |
| RINPERSOON            | Spine-derived      | Person identifier                  |
| AANVSECM              | Spine-derived      | Period start date                  |
| EINDSECM              | Spine-derived      | Period end date                    |
| SECM                  | **StatLine**       | `secm_dist` – 17 SEC monthly codes |
| ONDERWIJSNR_crypt     | Random ID          | Encrypted education number         |
| XKOPPEL\* (9 columns) | Random categorical | Cross-register linkage flags       |

### VEHTAB (1 file, 20 columns)

| Column                                   | Level          | Source                         |
|------------------------------------------|----------------|--------------------------------|
| RINPERSOONSHKW                           | Constant       | Always `"R"` (labelled)        |
| RINPERSOONHKW                            | Spine-derived  | Ref person from woonbase HH    |
| VEHP100WELVAART                          | Spine-derived  | Income percentile from spine   |
| VEHP100HVERM                             | Spine-derived  | Wealth percentile from spine   |
| VEHW1000VERH                             | Spine-derived  | Total wealth from spine VERMHH |
| VEHW1110BANK – VEHW5000SVRM (15 columns) | Random numeric | Hardcoded mean/sd              |

VEHTAB row count is calibrated to the woonbase household count.
Percentile and total wealth columns inherit calibration from the spine.
All 15 wealth component columns are independent random draws – they do
**not** sum to the total, and are not calibrated to any CBS source.

### BETAB (1 file, 7 columns)

Business register. SBI sector and size class are StatLine-calibrated.

| Column       | Level         | Source                                |
|--------------|---------------|---------------------------------------|
| BEID         | Spine-derived | Business identifier from SPOLIS       |
| SBI2008VJJJJ | **StatLine**  | `sbi2008_dist` – 27 SBI 2008 codes    |
| SBI2025VJJJJ | **StatLine**  | Same distribution as SBI2008          |
| GKSBS        | **StatLine**  | `gksbs_dist` – 13 EU SBS size classes |
| GEMHVJJJJ    | Spine-derived | Gemeente from spine                   |
| SBI1993VJJJJ | Constant      | `"-----"` (discontinued)              |
| GK           | Constant      | `"-"` (discontinued)                  |

### Energieverbruik (2 files, ~38 columns)

#### ENERGIEVERBRUIKTAB (annual totals, 20 columns)

| Column                    | Level          | Source                       |
|---------------------------|----------------|------------------------------|
| SOORTOBJECTNUMMER         | Spine-derived  | From woonbase obj spine      |
| RINOBJECTNUMMER           | Spine-derived  | From woonbase obj spine      |
| WONINGT                   | Constant       | `" "` (empty since 2019)     |
| WOONR                     | Constant       | `" "` (empty since 2019)     |
| STADSW                    | Codelist       | Hardcoded 94%/6%             |
| GAS                       | **StatLine**   | `gas_mean/sd` from params    |
| ELEK                      | **StatLine**   | `elek_mean/sd` from params   |
| GASBRON                   | Codelist       | Hardcoded probs              |
| ELEKBRON                  | Codelist       | Hardcoded probs              |
| ELEKTERUG                 | Random numeric | Hardcoded mean/sd            |
| ELEKNETTO                 | Random numeric | Hardcoded mean/sd            |
| GASSJV                    | Random numeric | Hardcoded mean/sd            |
| WARMTESCHATTING           | Random numeric | Hardcoded mean/sd            |
| ZONPV                     | **StatLine**   | `solar_pv_share` from params |
| ZONVERMOGEN1JAN           | Random numeric | Hardcoded mean/sd            |
| ZONVERMOGEN31DEC          | Random numeric | Hardcoded mean/sd            |
| ZONPVBRON                 | Codelist       | Hardcoded probs              |
| HOOFDVERWARMING31DEC      | Codelist       | Hardcoded probs              |
| WONINGBEWONING10PROFIELEN | Codelist       | Hardcoded probs              |
| KBHOOFDVERWARMING31DEC    | Codelist       | Hardcoded probs              |

#### ENERGIEVERBRUIKMAAND (monthly smart meter, 18 columns)

Monthly gas and electricity readings from smart meters, with delivery
and return flows. All monthly columns are random numeric with hardcoded
parameters.

### Zonnestroominstallaties (1 file, 28 columns)

Solar PV installations linked to dwellings. Panel capacity is
StatLine-calibrated.

| Column                                       | Level          | Source                                 |
|----------------------------------------------|----------------|----------------------------------------|
| RINOBJECTNUMMER                              | Spine-derived  | From woonbase obj spine                |
| SOORTOBJECTNUMMER                            | Spine-derived  | From woonbase obj spine                |
| EAN_installatie_crypt, EAN_aansluiting_crypt | Random ID      | Encrypted meter IDs                    |
| Type                                         | Codelist       | Rooftop / field / water                |
| Vermogen_panelen                             | **StatLine**   | `panel_capacity_mean/sd` from params   |
| Vermogen_omvormer                            | Random numeric | Hardcoded mean/sd                      |
| Jaarproductie                                | Random numeric | Derived from capacity + specific yield |
| Maandproductie_01 – Maandproductie_12        | Random numeric | Monthly production                     |
| Prod_waargenomen                             | Codelist       | Observed / estimated                   |
| Actief_op_31_12, Hele_jaar_actief            | Codelist       | Activity indicators                    |
| Datum_in, Datum_uit                          | Constant       | Empty (active installations)           |
| PC4, GWB                                     | Random         | Postal code / neighbourhood            |

### Network datasets (3 datasets, 5 columns each)

Burennetwerktab, Colleganetwerktab, and Familienetwerktab share an
identical structure. Relations are generated from the population spine.

| Column             | Level         | Source                    |
|--------------------|---------------|---------------------------|
| RINPERSOONS        | Constant      | Always `"R"`              |
| RINPERSOON         | Spine-derived | Person identifier (ego)   |
| RINPERSOONSRELATIE | Constant      | Always `"R"`              |
| RINPERSOONRELATIE  | Spine-derived | Person identifier (alter) |
| RELATIE            | Codelist      | Relation type             |

**Relation types per dataset:**

| Dataset           | Relations/person | Types                                   |
|-------------------|------------------|-----------------------------------------|
| Burennetwerktab   | ~30              | 2 (neighbour, community member)         |
| Colleganetwerktab | ~20              | 1 (colleague)                           |
| Familienetwerktab | ~12              | 22 (biological, adoptive, in-law, step) |

## Validation scripts

The `analysis/` folder contains per-dataset tests and minimal demos:

**Tests:**

| Script                   | What it validates                                                        |
|--------------------------|--------------------------------------------------------------------------|
| `test_woonbase.R`        | Structure, cross-file joins, haven labels, spine distributions           |
| `test_rdw.R`             | RINKENTEKEN consistency, calibrated fuel/weight/VKT, year shifts         |
| `test_spolis.R`          | Identifier links, wage columns, fleet size                               |
| `test_vehtab.R`          | HH identifiers, spine-derived percentiles, wealth components             |
| `test_energieverbruik.R` | Object identifiers, calibrated gas/elek/solar, year shifts               |
| `test_gba.R`             | GBA structure, cross-file RINPERSOON, labels, woonbase cross-link        |
| `test_cross_datasets.R`  | Full cross-dataset join: woonbase + GBA + RDW + SPOLIS + VEHTAB + energy |
| `test_columns_pdf.R`     | Column names vs CBS PDF documentation                                    |
| `test_parquet_export.R`  | Export/read round-trip, labels, col_select                               |

**Demos:**

| Script                 | What it shows                                              |
|------------------------|------------------------------------------------------------|
| `demo_woonbase.R`      | Population pyramid, HH type by age, income vs WOZ heatmap  |
| `demo_rdw.R`           | EV adoption curve, fuel stacked area, weight vs km scatter |
| `demo_autobelasting.R` | Cross-dataset policy analysis: car tax by income           |

Run all tests:

``` r
for (f in list.files("analysis", pattern = "^test_", full.names = TRUE)) {
  cat(sprintf("\n>>> %s <<<\n", f))
  source(f, local = TRUE)
}
```

## Updating parameters

All datasets with calibrated parameters ship with pre-computed values.
To refresh from CBS StatLine (requires `cbsodataR`):

``` r
# Woonbase -- queries 37230ned and 71486ned
woonbase_update_params(years = 2016:2025)

# RDW -- queries 85237NED, 85236NED, 85404NED
rdw_update_params(years = 2019:2025)

# SPOLIS -- queries 85275NED
spolis_update_params(years = 2010:2025)
```

VEHTAB and ENERGIEVERBRUIKTAB parameters are currently maintained
manually in their respective `params.yaml` files.
