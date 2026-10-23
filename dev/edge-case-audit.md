# Edge-case audit: simulated vs real file structure

**Status:** the gaps below were fixed after this audit (RDW vehicle
structure, INHATAB special codes and losses, energy register rules, vacant
dwellings and unknown classes). Tests in `test-rdw.R`, `test-energy.R`,
`test-dwellings.R` and `test-new-datasets.R` keep them fixed. The INHATAB
percentile codes (-1 unknown, -2 institutional) are confirmed in the INHATAB
documentation.

Checked 2023 files (woonbase n = 50,000) against the CBS variable
documentation (`vignettes/articles/cbs-variable-reference.Rmd`). Focus: what
makes code that runs on simulated data fail or silently differ on the real
data. Date: 2026-10-23.

## Matches the real structure

- Column names of RDWNPACT, VERKEERSPRESTATIE, INHATAB, INPATAB, ENERGIEVERBRUIK.
- Keys: every RDW plate is in VERKEERSPRESTATIE; INPATAB household keys are
  all in INHATAB; INHATAB has one row per key; energy objects are woonbase
  objects.
- RINPERSOONS has K/S/R origins in RDW; WONINGT/WOONR are empty from 2019;
  ZONPV and ZONVERMOGEN agree.
- Personal income components (INPPERS*, INPWINST) can be negative.

## Gaps that hide bugs in user code

| File | Real data | Simulated | Code that breaks on real data |
|------|-----------|-----------|-------------------------------|
| RDWNPACT | Contains dropped (`uitval`) and business-stock (`bedrijfsvoorraad`) vehicles | Only `actief` vehicles | Filtering on "personenauto" without "actief" counts dropped cars |
| RDWNPACT | Owners often have several vehicles | Every owner has exactly one | Joins to persons that assume one car per person; counts of cars per household |
| VERKEERSPRESTATIE | Only passenger cars of natural persons | Every vehicle, incl. trucks and company cars | Code that assumes all VP plates are cars |
| VERKEERSPRESTATIE | `VPGEWICHT` varies; must always be applied | All weights about 1 | Unweighted means look right here, are biased on real data |
| VERKEERSPRESTATIE | `VPGEWICHT`, `VPDGNWEG` numeric (F) | character | Arithmetic needs `as.numeric()` here but not there |
| RDWNPACT | `AANTALCYLCORVRTG` numeric (F2) | character | Same |
| RDWNPACT | `KLEURCODEVRTG` 99 = NVT for non-cars | never 99 | Colour tables of all vehicles |
| INHATAB | Household income can be negative (self-employed losses) | minimum 4,500 | `log(income)`, ratios, classes starting at 0 |
| INHATAB | Percentile columns use negative codes for unknown/institutional (as in VEHTAB: -1, -2) | always 1–100 | Means/medians of percentile columns, `between(p, 1, 100)` assumptions *(to confirm against the INHATAB documentation)* |
| INPATAB | No hard floor on losses | Losses floored at exactly -50,000 | Tail statistics |
| ENERGIEVERBRUIK | `GAS`, `ELEK` empty when information is insufficient | never empty | `mean(GAS)` without `na.rm = TRUE` returns NA |
| ENERGIEVERBRUIK | `ELEKNETTO = max(ELEK - ELEKTERUG, 0)` | negative in 7% of rows | Net demand averages |
| ENERGIEVERBRUIK | `ELEKTERUG` capped at 2 × `ELEK` | cap violated in 1% | — |
| ENERGIEVERBRUIK | `GAS = 0` concentrated in heat-pump, district-heating and vacant dwellings | about 12% zero in every `GASBRON` group | Share of gas-free dwellings |
| ENERGIEVERBRUIK | All nine `HOOFDVERWARMING31DEC` types | 4 of 9 | Tables by heating type |
| Woonbase | Vacant dwellings (no household); `Onbekend` floor area/WOZ classes | every dwelling occupied; no `Onbekend` | Joins dwelling → household; class tables |

## Bugs found in the quality vignettes by this audit

- cars: `grepl("personenauto", ...)` keeps dropped and business-stock cars on real data.
- cars: mean annual kilometres is unweighted; `VPGEWICHT` is required.
- energy: means of `GAS`, `ELEK` without `na.rm = TRUE`.
- energy: the text claims `ELEKNETTO = ELEK - ELEKTERUG`; the real definition caps at 0.
