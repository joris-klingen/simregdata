# Column Overview

Auto-generated overview of all simulated columns, their calibration level, and data source.

Generated: 2026-03-05

## Summary by calibration level

| Level | Count |
|-------|------:|
| spine-derived | 159 |
| codelist-hardcoded | 82 |
| random-normal | 70 |
| statline-calibrated | 37 |
| random-uniform | 24 |
| constant | 17 |
| random-id | 5 |
| computed | 2 |

**Total columns:** 396

<details>
<summary><strong>CBS Woonbase</strong> — 182 columns across 9 files (0 statline-calibrated)</summary>

<details>
<summary><code>WOONBASEEKHuishoudensWV</code> — 31 columns (0 statline-calibrated)</summary>

| Column | Level | Source | Codelist |
|--------|-------|--------|----------|
| `RINPERSOONS` | spine-derived | spine.hh.RINPERSOONS_Ref |  |
| `RINPERSOON` | spine-derived | spine.hh.RINPERSOON_Ref |  |
| `AGHT{sfx}` | codelist-hardcoded | codelist: AGHT | [AGHT](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `AGIAH{sfx}` | codelist-hardcoded | codelist: AGIAH | [AGIAH](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `AGTSH{sfx}` | codelist-hardcoded | codelist: AGTSH | [AGTSH](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `AOWHT{sfx}` | codelist-hardcoded | codelist: AOWHT | [AOWHT](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `ARMOEDE{sfx}` | random-uniform | uniform [50, 500] |  |
| `ARMSOC{sfx}` | random-uniform | uniform [50, 500] |  |
| `BBIHJ{sfx}` | random-uniform | uniform [1, 20] |  |
| `BELIAGHT{sfx}` | random-uniform | uniform [5000, 80000] |  |
| `BELIAGIAH{sfx}` | random-uniform | uniform [5000, 80000] |  |
| `BELIAGTSH{sfx}` | random-uniform | uniform [5000, 80000] |  |
| `BELIH{sfx}` | spine-derived | spine.hh.BELIH |  |
| `BESTINKH{sfx}` | spine-derived | spine.hh.BESTINKH |  |
| `BETAALBUDGET{sfx}` | random-uniform | uniform [-10000, 60000] |  |
| `BETAALRESERVE{sfx}` | random-uniform | uniform [-5000, 50000] |  |
| `CORBETAALBUDGET{sfx}` | codelist-hardcoded | hardcoded probs |  |
| `EHALGR{sfx}` | random-uniform | uniform [1, 30] |  |
| `GESTINKH{sfx}` | spine-derived | spine.hh.GESTINKH |  |
| `LEERGROND{sfx}` | random-uniform | uniform [0, 50000] |  |
| `P100HBEST{sfx}` | spine-derived | spine.hh.P100HBEST |  |
| `P100HGEST{sfx}` | spine-derived | spine.hh.P100HGEST |  |
| `P100HVERM{sfx}` | spine-derived | spine.hh.P100HVERM |  |
| `P100WELVAART{sfx}` | spine-derived | spine.hh.P100WELVAART |  |
| `POPFEC{sfx}` | codelist-hardcoded | codelist: POPFEC | [POPFEC](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `POPIIV{sfx}` | codelist-hardcoded | codelist: POPIIV | [POPIIV](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `POPIIVWONING{sfx}` | random-uniform | uniform [0, 10] |  |
| `VERMHH{sfx}` | spine-derived | spine.hh.VERMHH |  |
| `VROMHH{sfx}` | spine-derived | spine.hh.VROMHH |  |
| `W1000VERH{sfx}` | random-uniform | uniform [0, 500000] |  |
| `VERSCHILIIV{sfx}` | codelist-hardcoded | codelist: VERSCHILIIV | [VERSCHILIIV](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |

</details>

<details>
<summary><code>ExtraKenmerkenPanden</code> — 18 columns (0 statline-calibrated)</summary>

| Column | Level | Source | Codelist |
|--------|-------|--------|----------|
| `PandID` | spine-derived | spine.obj.PandID1Jan |  |
| `PandAantalVbos{sfx}` | random-uniform | uniform [1, 20] |  |
| `PandAantalWoning{sfx}` | random-uniform | uniform [0, 15] |  |
| `PandAantalNietWoning{sfx}` | random-uniform | uniform [0, 5] |  |
| `PandOppTotWoning{sfx}` | random-uniform | uniform [0, 5000] |  |
| `PandOppTotNietWoning{sfx}` | random-uniform | uniform [0, 3000] |  |
| `PandOppGemWoning{sfx}` | random-uniform | uniform [30, 250] |  |
| `PandOppGemNietWoning{sfx}` | random-uniform | uniform [30, 500] |  |
| `PandWinkelfunctie{sfx}` | codelist-hardcoded | codelist: PANDFUNCTIE | [PANDFUNCTIE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `PandKantoorfunctie{sfx}` | codelist-hardcoded | codelist: PANDFUNCTIE | [PANDFUNCTIE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `PandIndustriefunctie{sfx}` | codelist-hardcoded | codelist: PANDFUNCTIE | [PANDFUNCTIE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `PandBijeenkomstfunctie{sfx}` | codelist-hardcoded | codelist: PANDFUNCTIE | [PANDFUNCTIE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `PandGezondheidszorgfunctie{sfx}` | codelist-hardcoded | codelist: PANDFUNCTIE | [PANDFUNCTIE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `PandAnderefunctie{sfx}` | codelist-hardcoded | codelist: PANDFUNCTIE | [PANDFUNCTIE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `PandTransformatie{sfx}` | codelist-hardcoded | codelist: PANDTRANSFORMATIE | [PANDTRANSFORMATIE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `PandHoogte` | random-uniform | uniform [3, 60] |  |
| `PandAantalVerdiepingen` | random-uniform | uniform [1, 15] |  |
| `PandDaktype` | codelist-hardcoded | codelist: PANDDAKTYPE | [PANDDAKTYPE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |

</details>

<details>
<summary><code>WoonbaseKenmerkenHuishoudens</code> — 9 columns (0 statline-calibrated)</summary>

| Column | Level | Source | Codelist |
|--------|-------|--------|----------|
| `HUISHOUDNR{sfx}` | spine-derived | spine.hh.HUISHOUDNR |  |
| `DatumAanvangHH{sfx}` | spine-derived | spine.hh.DATUMAANVANGHH |  |
| `IMPUTATIECODEHH{sfx}` | spine-derived | spine.hh.IMPUTATIECODEHH | [IMPUTATIECODEHH](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `RefPersoonHH{sfx}` | spine-derived | spine.hh.REFPERSOONHH_Ref | [REFPERSOONHH](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `RINPERSOON` | spine-derived | spine.hh.RINPERSOON_Ref |  |
| `RINPERSOONS` | spine-derived | spine.hh.RINPERSOONS_Ref |  |
| `TYPHH{sfx}` | spine-derived | spine.hh.TYPHH | [TYPHH](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `AantalKinderenPerHuishouden{sfx}` | spine-derived | spine.hh.AantalKinderenPerHuishouden |  |
| `AantalPersonenPerHuishouden{sfx}` | spine-derived | spine.hh.AantalPersonenPerHuishouden |  |

</details>

<details>
<summary><code>WoonbaseKenmerkenWoonruimten</code> — 13 columns (0 statline-calibrated)</summary>

| Column | Level | Source | Codelist |
|--------|-------|--------|----------|
| `RINOBJECTNUMMER` | spine-derived | spine.obj.RINOBJECTNUMMER |  |
| `SOORTOBJECTNUMMER` | spine-derived | spine.obj.SOORTOBJECTNUMMER |  |
| `GEMEENTECODEJJJJ{sfx}` | spine-derived | spine.obj.GemeenteCodeJJJJ{sfx} |  |
| `WIJKCODEJJJJ{sfx}` | spine-derived | spine.obj.WijkCodeJJJJ{sfx} |  |
| `BUURTCODEJJJJ{sfx}` | spine-derived | spine.obj.BuurtCodeJJJJ{sfx} |  |
| `Indicator_VBOIsNieuwbouw` | spine-derived | spine.obj.Indicator_VBOIsNieuwbouw1Jan | [INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `Indicator_VBOIsNieuwbouwJJJJ-1` | spine-derived | spine.obj.Indicator_VBOIsNieuwbouw1Jan | [INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `VSLSoort{sfx}` | spine-derived | spine.obj.VSLSoort{sfx} | [VSLSOORT](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `VBOWoningType{sfx}` | spine-derived | spine.obj.VBOWoningType{sfx} | [WONINGTYPE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `VBOBouwjaar{sfx}` | spine-derived | spine.obj.VBOBouwjaar{sfx} |  |
| `VBOOppervlakte{sfx}` | spine-derived | spine.obj.VBOOppervlakte{sfx} |  |
| `WOZWaardeObjectBAG{sfx}` | spine-derived | spine.obj.WOZWaardeObjectBAG{sfx} |  |
| `VBOStatus{sfx}` | spine-derived | spine.obj.VBOStatus{sfx} | [VBOSTATUS](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |

</details>

<details>
<summary><code>WoonbaseKenmerkenPersonen</code> — 17 columns (0 statline-calibrated)</summary>

| Column | Level | Source | Codelist |
|--------|-------|--------|----------|
| `RINPERSOON` | spine-derived | spine.pers.RINPERSOON |  |
| `RINPERSOONS` | spine-derived | spine.pers.RINPERSOONS |  |
| `GBABurgerlijkeStaat{sfx}` | spine-derived | spine.pers.GBABurgerlijkeStaat |  |
| `GBAGeboorteJaar{sfx}` | spine-derived | spine.pers.GBAGeboorteJaar |  |
| `GBAGeslachtsAanduiding{sfx}` | spine-derived | spine.pers.GBAGeslachtsAanduiding | [GESLACHT](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `GEMEENTECODEJJJJ{sfx}` | spine-derived | spine.pers.GemeenteCodeJJJJ{sfx} |  |
| `WIJKCODEJJJJ{sfx}` | spine-derived | spine.pers.WijkCodeJJJJ{sfx} |  |
| `BUURTCODEJJJJ{sfx}` | spine-derived | spine.pers.BuurtCodeJJJJ{sfx} |  |
| `PLHH{sfx}` | spine-derived | spine.pers.PLHH | [PLHH](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `RINOBJECTNUMMER{sfx}` | spine-derived | spine.pers.RINOBJECTNUMMER |  |
| `SOORTOBJECTNUMMER{sfx}` | spine-derived | spine.pers.SOORTOBJECTNUMMER |  |
| `AanvangWoonduur{sfx}` | spine-derived | spine.pers.AanvangWoonduur |  |
| `OPLNIVSOI2016AGG4HBMETNIRWO{sfx}` | codelist-hardcoded | hardcoded probs |  |
| `OPLNIVSOI2016AGG4HGMETNIRWO{sfx}` | codelist-hardcoded | hardcoded probs |  |
| `OPLNIVSOI2021AGG4HBMETNIRWO{sfx}` | codelist-hardcoded | hardcoded probs |  |
| `OPLNIVSOI2021AGG4HGMETNIRWO{sfx}` | codelist-hardcoded | hardcoded probs |  |
| `GEWICHTHOOGSTEOPL{sfx}` | random-uniform | uniform [0.5, 1.5] |  |

</details>

<details>
<summary><code>WoonbasePopulatieHuishoudens</code> — 21 columns (0 statline-calibrated)</summary>

| Column | Level | Source | Codelist |
|--------|-------|--------|----------|
| `HUISHOUDNR{sfx}` | spine-derived | spine.hh.HUISHOUDNR |  |
| `DATUMAANVANGHH{sfx}` | spine-derived | spine.hh.DATUMAANVANGHH |  |
| `IMPUTATIECODEHH{sfx}` | spine-derived | spine.hh.IMPUTATIECODEHH | [IMPUTATIECODEHH](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `RINPERSOONS` | spine-derived | spine.hh.RINPERSOONS_Ref |  |
| `RINPERSOON` | spine-derived | spine.hh.RINPERSOON_Ref |  |
| `RINOBJECTNUMMER{sfx}` | spine-derived | spine.hh.RINOBJECTNUMMER |  |
| `SOORTOBJECTNUMMER{sfx}` | spine-derived | spine.hh.SOORTOBJECTNUMMER |  |
| `TYPHH{sfx}` | spine-derived | spine.hh.TYPHH | [TYPHH](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `AantalPersonenPerHuishouden{sfx}` | spine-derived | spine.hh.AantalPersonenPerHuishouden |  |
| `AantalKinderenPerHuishouden{sfx}` | spine-derived | spine.hh.AantalKinderenPerHuishouden |  |
| `LeeftijdRefPersoon{sfx}` | spine-derived | spine.hh.LeeftijdRefPersoon |  |
| `PLHHRefPersoon{sfx}` | spine-derived | spine.hh.PLHH_Ref | [PLHH](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `GBAGeslachtsaanduidingRefPersoon{sfx}` | spine-derived | spine.hh.GBAGeslachtsAanduiding_Ref | [GESLACHT](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `GemeenteCodeJJJJ{sfx}` | spine-derived | spine.hh.GemeenteCodeJJJJ{sfx} |  |
| `VSLSoort{sfx}` | spine-derived | spine.hh.VSLSoort{sfx} | [VSLSOORT](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `WOZWaardeObjectBAGKlasse{sfx}` | spine-derived | spine.hh.WOZWaardeObjectBAGKlasse{sfx} | [WOZKLASSE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `VBOBouwJaarKlasse{sfx}` | spine-derived | spine.hh.VBOBouwJaarKlasse{sfx} | [BOUWJAARKLASSE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `VBOOppervlakteKlasse{sfx}` | spine-derived | spine.hh.VBOOppervlakteKlasse{sfx} | [OPPKLASSE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `VBOWoningType{sfx}` | spine-derived | spine.hh.VBOWoningType{sfx} | [WONINGTYPE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `TypeEigenaar{sfx}` | spine-derived | spine.hh.TypeEigenaar{sfx} | [TYPEIGENAAR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `Indicator_HHIsAanwezig{sfx}` | constant | value: 1 | [INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |

</details>

<details>
<summary><code>WoonbasePopulatieWoonruimten</code> — 26 columns (0 statline-calibrated)</summary>

| Column | Level | Source | Codelist |
|--------|-------|--------|----------|
| `SOORTOBJECTNUMMER` | spine-derived | spine.obj.SOORTOBJECTNUMMER |  |
| `RINOBJECTNUMMER` | spine-derived | spine.obj.RINOBJECTNUMMER |  |
| `PandID{sfx}` | spine-derived | spine.obj.PandID{sfx} |  |
| `VSLSoort{sfx}` | spine-derived | spine.obj.VSLSoort{sfx} | [VSLSOORT](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `HUISHOUDNR{sfx}` | spine-derived | spine.obj.HUISHOUDNR |  |
| `DATUMAANVANGHH{sfx_lower}` | spine-derived | spine.obj.DATUMAANVANGHH |  |
| `RINPERSOONS_Ref{sfx_lower}` | spine-derived | spine.obj.RINPERSOONS_Ref2 |  |
| `RINPERSOON_Ref{sfx_lower}` | spine-derived | spine.obj.RINPERSOON_Ref2 |  |
| `VBOWoningType{sfx}` | spine-derived | spine.obj.VBOWoningType{sfx} | [WONINGTYPE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `VBOBouwJaarKlasse{sfx}` | spine-derived | spine.obj.VBOBouwJaarKlasse{sfx} | [BOUWJAARKLASSE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `VBOOppervlakteKlasse{sfx}` | spine-derived | spine.obj.VBOOppervlakteKlasse{sfx} | [OPPKLASSE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `WOZWaardeObjectBAGKlasse{sfx}` | spine-derived | spine.obj.WOZWaardeObjectBAGKlasse{sfx} | [WOZKLASSE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `TypeEigenaar{sfx}` | spine-derived | spine.obj.TypeEigenaar{sfx} | [TYPEIGENAAR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `AantalPersonenPerVSLKlasse{sfx}` | computed | computed.AantalPersonenPerVSLKlasse | [PERSKLASSE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `AantalHuishoudensPerVSLKlasse{sfx}` | constant | value: 1 | [HHKLASSE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `AantalKinderenPerVSL{sfx}` | spine-derived | spine.obj.AantalKinderenPerVSL |  |
| `LeeftijdJongsteKindPerVSL{sfx}` | spine-derived | spine.obj.LeeftijdJongsteKindPerVSL |  |
| `TYPHH{sfx}` | spine-derived | spine.obj.TYPHH | [TYPHH](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `GemeenteCodeJJJJ{sfx}` | spine-derived | spine.obj.GemeenteCodeJJJJ{sfx} |  |
| `Indicator_VBOIsAanwezig{sfx}` | spine-derived | spine.obj.Indicator_VBOIsAanwezig{sfx} | [INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `Indicator_VSLIsAanwezig{sfx}` | spine-derived | spine.obj.Indicator_VSLIsAanwezig{sfx} | [INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `Indicator_VBOIsGesloopt` | spine-derived | spine.obj.Indicator_VBOIsGesloopt | [INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `Indicator_VSLIsOntrokken` | spine-derived | spine.obj.Indicator_VSLIsOntrokken | [INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `Indicator_VBOIsTransformatie` | spine-derived | spine.obj.Indicator_VBOIsTransformatie | [INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `Indicator_VBOIsNieuwbouw` | spine-derived | spine.obj.Indicator_VBOIsNieuwbouw | [INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `Indicator_VSLIsNieuw` | spine-derived | spine.obj.Indicator_VSLIsNieuw | [INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |

</details>

<details>
<summary><code>WoonbasePopulatiePersonen</code> — 31 columns (0 statline-calibrated)</summary>

| Column | Level | Source | Codelist |
|--------|-------|--------|----------|
| `RINPERSOON` | spine-derived | spine.pers.RINPERSOON |  |
| `RINPERSOONS` | spine-derived | spine.pers.RINPERSOONS |  |
| `RefPersoonHH{sfx}` | spine-derived | spine.pers.REFPERSOONHH | [REFPERSOONHH](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `HUISHOUDNR{sfx}` | spine-derived | spine.pers.HUISHOUDNR |  |
| `DATUMAANVANGHH{sfx}` | spine-derived | spine.pers.DATUMAANVANGHH |  |
| `IMPUTATIECODEHH{sfx}` | spine-derived | spine.pers.IMPUTATIECODEHH | [IMPUTATIECODEHH](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `RINOBJECTNUMMER{sfx}` | spine-derived | spine.pers.RINOBJECTNUMMER |  |
| `SOORTOBJECTNUMMER{sfx}` | spine-derived | spine.pers.SOORTOBJECTNUMMER |  |
| `Indicator_PersoonIsGeboren` | spine-derived | spine.pers.Indicator_PersoonIsGeboren | [INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `Indicator_PersoonIsOverleden` | spine-derived | spine.pers.Indicator_PersoonIsOverleden | [INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `Indicator_PersoonIsGeemigreerd` | spine-derived | spine.pers.Indicator_PersoonIsGeemigreerd | [INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `Indicator_PersoonIsAdministratiefAfgevoerd` | spine-derived | spine.pers.Indicator_PersoonIsAdministratiefAfgevoerd | [INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `Indicator_PersoonIsGeimmigreerd` | spine-derived | spine.pers.Indicator_PersoonIsGeimmigreerd | [INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `Indicator_PersoonIsAdministratiefOpgenomen` | spine-derived | spine.pers.Indicator_PersoonIsAdministratiefOpgenomen | [INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `Indicator_PersoonIsVerhuisd` | spine-derived | spine.pers.Indicator_PersoonIsVerhuisd | [INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `Indicator_PersoonIsAanwezig1Jan` | spine-derived | spine.pers.Indicator_PersoonIsAanwezig1Jan | [INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `Indicator_PersoonIsAanwezig31Dec` | spine-derived | spine.pers.Indicator_PersoonIsAanwezig31Dec | [INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `AantalKeerVerhuisd` | spine-derived | spine.pers.AantalKeerVerhuisd |  |
| `PLHH{sfx}` | spine-derived | spine.pers.PLHH | [PLHH](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `TYPHH{sfx}` | spine-derived | spine.pers.TYPHH | [TYPHH](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `GBAGeslachtsAanduiding{sfx}` | spine-derived | spine.pers.GBAGeslachtsAanduiding | [GESLACHT](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `GBAGeboorteJaar{sfx}` | spine-derived | spine.pers.GBAGeboorteJaar |  |
| `GBABurgerlijkeStaat{sfx}` | spine-derived | spine.pers.GBABurgerlijkeStaat |  |
| `AantalPersonenPerHuishouden{sfx}` | spine-derived | spine.pers.AantalPersonenPerHuishouden |  |
| `GemeenteCodeJJJJ{sfx}` | spine-derived | spine.pers.GemeenteCodeJJJJ{sfx} |  |
| `VSLSoort{sfx}` | spine-derived | spine.pers.VSLSoort{sfx} | [VSLSOORT](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `TypeEigenaar{sfx}` | spine-derived | spine.pers.TypeEigenaar{sfx} | [TYPEIGENAAR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `VBOWoningType{sfx}` | spine-derived | spine.pers.VBOWoningType{sfx} | [WONINGTYPE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `VBOBouwJaarKlasse{sfx}` | spine-derived | spine.pers.VBOBouwJaarKlasse{sfx} | [BOUWJAARKLASSE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `VBOOppervlakteKlasse{sfx}` | spine-derived | spine.pers.VBOOppervlakteKlasse{sfx} | [OPPKLASSE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `WOZWaardeObjectBAGKlasse{sfx}` | spine-derived | spine.pers.WOZWaardeObjectBAGKlasse{sfx} | [WOZKLASSE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |

</details>

<details>
<summary><code>WoonbaseSleutelbestand</code> — 16 columns (0 statline-calibrated)</summary>

| Column | Level | Source | Codelist |
|--------|-------|--------|----------|
| `RINPERSOONS` | spine-derived | spine.pers.RINPERSOONS |  |
| `RINPERSOON` | spine-derived | spine.pers.RINPERSOON |  |
| `REFPERSOONHH` | spine-derived | spine.pers.REFPERSOONHH | [REFPERSOONHH](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `PLHH` | spine-derived | spine.pers.PLHH | [PLHH](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `HUISHOUDNR` | spine-derived | spine.pers.HUISHOUDNR |  |
| `DATUMAANVANGHH` | spine-derived | spine.pers.DATUMAANVANGHH |  |
| `TYPHH` | spine-derived | spine.pers.TYPHH | [TYPHH](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `IMPUTATIECODEHH` | spine-derived | spine.pers.IMPUTATIECODEHH | [IMPUTATIECODEHH](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `SOORTOBJECTNUMMER` | spine-derived | spine.pers.SOORTOBJECTNUMMER |  |
| `RINOBJECTNUMMER` | spine-derived | spine.pers.RINOBJECTNUMMER |  |
| `INVOORRAAD` | constant | value: 1 | [INVOORRAAD](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `VBOVOORRAADTYPE` | constant | value: 0 | [VBOVOORRAADTYPE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `BEGINGELDIGHEID` | constant | template: {jan1} |  |
| `EINDGELDIGHEID` | constant | template: {dec31} |  |
| `REDENBEGINGELDIGHEID` | codelist-hardcoded | hardcoded probs |  |
| `REDENEINDGELDIGHEID` | constant | value: NVT |  |

</details>

</details>

<details>
<summary><strong>RDW Motorvoertuigenpark</strong> — 19 columns across 2 files (6 statline-calibrated)</summary>

<details>
<summary><code>RDWNPACT</code> — 13 columns (5 statline-calibrated)</summary>

| Column | Level | Source | Codelist |
|--------|-------|--------|----------|
| `RINPERSOONS` | codelist-hardcoded | codelist: RINPERSOONS_RDW | [RINPERSOONS_RDW](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/rdw/codelists.yaml) |
| `RINPERSOON` | spine-derived | spine.pers.RINPERSOON |  |
| `RINKENTEKEN` | spine-derived | spine.pers.RINKENTEKEN |  |
| `KLEURCODEVRTG` | statline-calibrated | params: kleur_p (85237NED, 85236NED, 85404NED) | [KLEURCODE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/rdw/codelists.yaml) |
| `EERSTETOELDAT1VRTG` | statline-calibrated | params: bouwjaar_p (85237NED, 85236NED, 85404NED) |  |
| `SRTREFVRTG` | codelist-hardcoded | codelist: SRTREF | [SRTREF](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/rdw/codelists.yaml) |
| `VRTGSOORT` | statline-calibrated | params: vrtgsoort_p (85237NED, 85236NED, 85404NED) | [VRTGSOORT](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/rdw/codelists.yaml) |
| `BRANDSTCODECORVRTG` | statline-calibrated | params: brandstof_p (85237NED, 85236NED, 85404NED) | [BRANDSTOF](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/rdw/codelists.yaml) |
| `MASSALEEGCORVRTG` | statline-calibrated | params: gewicht_mean (85237NED, 85236NED, 85404NED) |  |
| `MAXLAADVERMCORVRTG` | random-uniform | uniform [0, 3000] |  |
| `AANTALCYLCORVRTG` | codelist-hardcoded | hardcoded probs |  |
| `CYLININHOUDCORVRTG` | random-normal | normal (mean=1600, sd=600) |  |
| `SOORTBROMFIETSCOR` | codelist-hardcoded | codelist: SOORTBROMFIETS | [SOORTBROMFIETS](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/rdw/codelists.yaml) |

</details>

<details>
<summary><code>VERKEERSPRESTATIE</code> — 6 columns (1 statline-calibrated)</summary>

| Column | Level | Source | Codelist |
|--------|-------|--------|----------|
| `RINKENTEKEN` | spine-derived | spine.pers.RINKENTEKEN |  |
| `RinpersoonsVP` | codelist-hardcoded | codelist: RINPERSOONS_RDW | [RINPERSOONS_RDW](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/rdw/codelists.yaml) |
| `RinpersoonVP` | spine-derived | spine.pers.RINPERSOON |  |
| `VPGEWICHT` | codelist-hardcoded | hardcoded probs |  |
| `VPDGNWEG` | codelist-hardcoded | hardcoded probs |  |
| `VPJAARKM` | statline-calibrated | params: jaarkm_mean (85237NED, 85236NED, 85404NED) |  |

</details>

</details>

<details>
<summary><strong>Banen en lonen (SPOLISBUS)</strong> — 133 columns across 1 files (12 statline-calibrated)</summary>

<details>
<summary><code>SPOLISBUS</code> — 133 columns (12 statline-calibrated)</summary>

| Column | Level | Source | Codelist |
|--------|-------|--------|----------|
| `RINPERSOONS` | codelist-hardcoded | codelist: RINPERSOONS_SPOLIS | [RINPERSOONS_SPOLIS](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `RINPERSOON` | spine-derived | spine.pers.RINPERSOON |  |
| `IKVID` | random-id | random hex, width=32 |  |
| `SDATUMAANVANGIKO` | constant | template: {jan1} |  |
| `SDATUMEINDEIKO` | constant | template: {dec31} |  |
| `SAANTSV` | random-normal | normal (mean=18, sd=6) |  |
| `SAANTVERLU` | random-normal | normal (mean=130, sd=40) |  |
| `SAUTOZAAK` | statline-calibrated | params: autozaak_mean (81431NED) |  |
| `SBAANDAGEN` | codelist-hardcoded | hardcoded probs |  |
| `SBASISLOON` | statline-calibrated | params: basisloon_mean (81431NED) |  |
| `SBASISUREN` | statline-calibrated | params: basisuren_mean (81431NED) |  |
| `SBEDRALINWWB` | random-normal | normal (mean=0, sd=50) |  |
| `SBEDRRCHTAL` | random-normal | normal (mean=0, sd=20) |  |
| `SBEDRZDAFTR` | random-normal | normal (mean=0, sd=10) |  |
| `SBIJDRZVW` | random-normal | normal (mean=180, sd=100) |  |
| `SBIJZONDEREBELONING` | statline-calibrated | params: bijzbeloning_mean (81431NED) |  |
| `SEXTRSAL` | random-normal | normal (mean=50, sd=200) |  |
| `SINCIDENTSAL` | random-normal | normal (mean=20, sd=100) |  |
| `SINGLBPH` | random-normal | normal (mean=100, sd=200) |  |
| `SLNINGLD` | statline-calibrated | params: loon_mean (81431NED) |  |
| `SLNLBPH` | statline-calibrated | params: lnlbph_mean (81431NED) |  |
| `SLNOWRK` | random-normal | normal (mean=50, sd=200) |  |
| `SLNSV` | statline-calibrated | params: lnsv_mean (81431NED) |  |
| `SLNTABBB` | random-normal | normal (mean=0, sd=50) |  |
| `SLVLPREG` | random-normal | normal (mean=0, sd=50) |  |
| `SLVLPREGTOEG` | random-normal | normal (mean=0, sd=50) |  |
| `SOPGRCHTEXTRSAL` | random-normal | normal (mean=0, sd=100) |  |
| `SOPGRCHTVAKBSL` | random-normal | normal (mean=0, sd=50) |  |
| `SOVERWERKUREN` | random-normal | normal (mean=3, sd=8) |  |
| `SPENSIOENPREMIE` | random-normal | normal (mean=250, sd=200) |  |
| `SPRAWF` | random-normal | normal (mean=90, sd=60) |  |
| `SPRUFO` | random-normal | normal (mean=15, sd=30) |  |
| `SPRWAOAOF` | random-normal | normal (mean=20, sd=30) |  |
| `SPRWAOAOK` | random-normal | normal (mean=15, sd=25) |  |
| `SPRWGF` | random-normal | normal (mean=30, sd=40) |  |
| `SREGULIEREUREN` | statline-calibrated | params: reguliereuren_mean (81431NED) |  |
| `SREISK` | random-normal | normal (mean=50, sd=80) |  |
| `SVAKBSL` | random-normal | normal (mean=200, sd=150) |  |
| `SVERGZVW` | random-normal | normal (mean=180, sd=120) |  |
| `SVERRARBKRT` | random-normal | normal (mean=10, sd=30) |  |
| `SVERSTRAANV` | random-normal | normal (mean=5, sd=20) |  |
| `SVOLTIJDDAGEN` | random-normal | normal (mean=22, sd=6) |  |
| `SWGBIJDRKO` | random-normal | normal (mean=0, sd=30) |  |
| `SWRDLN` | random-normal | normal (mean=100, sd=300) |  |
| `SWRDPRGEBRAUT` | random-normal | normal (mean=50, sd=200) |  |
| `SWRKNBIJDRAUT` | random-normal | normal (mean=10, sd=50) |  |
| `SCAO_crypt` | random-id | random hex, width=32 |  |
| `SCDAARD` | codelist-hardcoded | codelist: SCDAARD | [SCDAARD](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SCDAGH` | codelist-hardcoded | codelist: SCDAGH | [SCDAGH](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SCDINCINKVERM` | codelist-hardcoded | codelist: SCDINCINKVERM | [SCDINCINKVERM](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SCDINVLVPL1` | codelist-hardcoded | codelist: SCDINVLVPL | [SCDINVLVPL](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SCDINVLVPL2` | codelist-hardcoded | codelist: SCDINVLVPL | [SCDINVLVPL](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SCDINVLVPL3` | codelist-hardcoded | codelist: SCDINVLVPL | [SCDINVLVPL](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SCDRDNGNBIJT` | codelist-hardcoded | codelist: SCDRDNGNBIJT | [SCDRDNGNBIJT](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SCDZVW` | codelist-hardcoded | codelist: SCDZVW | [SCDZVW](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SCONTRACTSOORT` | codelist-hardcoded | codelist: SCONTRACTSOORT | [SCONTRACTSOORT](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SDATUMAANVANGIKVORG` | constant | template: {jan1} |  |
| `SFSINDFZ` | codelist-hardcoded | codelist: SFSINDFZ | [SFSINDFZ](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SINDLHKORT` | codelist-hardcoded | codelist: JN_INDICATOR | [JN_INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SINDSA03` | codelist-hardcoded | codelist: JN_INDICATOR | [JN_INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SINDSA43` | codelist-hardcoded | codelist: JN_INDICATOR | [JN_INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SINDSA71` | codelist-hardcoded | codelist: JN_INDICATOR | [JN_INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SINDSA72` | codelist-hardcoded | codelist: JN_INDICATOR | [JN_INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SINDVAKBN` | codelist-hardcoded | codelist: JN_INDICATOR | [JN_INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SINDZW` | codelist-hardcoded | codelist: JN_INDICATOR | [JN_INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SINLEGLEVENSLOOP` | codelist-hardcoded | codelist: JN_INDICATOR | [JN_INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SOVERWERK` | codelist-hardcoded | codelist: INDICATOR_01 | [INDICATOR_01](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SPOLISDIENSTVERBAND` | statline-calibrated | params: dienstverband_p (81431NED) | [SPOLISDIENSTVERBAND](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SRISGRP` | codelist-hardcoded | codelist: SRISGRP | [SRISGRP](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SSRTIV` | codelist-hardcoded | codelist: SSRTIV | [SSRTIV](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SWEKARBDUURKLASSE` | statline-calibrated | params: wekarbduur_p (81431NED) | [SWEKARBDUURKLASSE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SARBEIDSRELATIE` | codelist-hardcoded | codelist: SARBEIDSRELATIE | [SARBEIDSRELATIE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SAUTOVANDEZAAK` | codelist-hardcoded | codelist: SAUTOVANDEZAAK | [SAUTOVANDEZAAK](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SBEID` | random-id | random hex, width=8 |  |
| `SCAOSECTOR` | codelist-hardcoded | codelist: SCAOSECTOR | [SCAOSECTOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SDATUMAANVANGIKV` | constant | template: {jan1} |  |
| `SDATUMEINDEIKV` | constant | template: {dec31} |  |
| `SINDWAO` | codelist-hardcoded | codelist: JN_INDICATOR | [JN_INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SINDWW` | codelist-hardcoded | codelist: JN_INDICATOR | [JN_INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SLBTAB` | codelist-hardcoded | codelist: SLBTAB | [SLBTAB](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SLHNR_crypt` | random-id | random hex, width=32 |  |
| `SSECT` | statline-calibrated | params: ssect_p (81431NED) | [SSECT](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SSOORTBAAN` | statline-calibrated | params: soortbaan_p (81431NED) | [SSOORTBAAN](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `STIJDVAKTYPE` | codelist-hardcoded | codelist: STIJDVAKTYPE | [STIJDVAKTYPE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SPRWGAWHK` | random-normal | normal (mean=15, sd=25) |  |
| `SWGHZVW` | random-normal | normal (mean=180, sd=120) |  |
| `SPRGEDIFFWHK` | random-normal | normal (mean=10, sd=20) |  |
| `SINDTIJDHK` | codelist-hardcoded | codelist: INDICATOR_01 | [INDICATOR_01](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SIMPUTATIE` | codelist-hardcoded | codelist: INDICATOR_01 | [INDICATOR_01](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SINDPRKJONGRWEN` | codelist-hardcoded | codelist: INDICATOR_01 | [INDICATOR_01](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SINDPKAGH` | codelist-hardcoded | codelist: INDICATOR_01 | [INDICATOR_01](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SINDPKNWARBVOUDWN` | codelist-hardcoded | codelist: INDICATOR_01 | [INDICATOR_01](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SINDPMA` | codelist-hardcoded | codelist: INDICATOR_01 | [INDICATOR_01](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SCTRCTLN` | random-normal | normal (mean=2800, sd=1200) |  |
| `SAANTCTRCTURENPWK` | random-normal | normal (mean=32, sd=8) |  |
| `SBEDRRNTKSTVPERSL` | random-normal | normal (mean=0, sd=20) |  |
| `SINDWAARNEMING` | codelist-hardcoded | codelist: INDICATOR_01 | [INDICATOR_01](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SModelramingPensioenpremieWn` | random-normal | normal (mean=100, sd=80) |  |
| `SModelramingPensioenpremieWg` | random-normal | normal (mean=200, sd=150) |  |
| `SModelramingVutpremieWn` | random-normal | normal (mean=10, sd=30) |  |
| `SModelramingVutpremieWg` | random-normal | normal (mean=20, sd=50) |  |
| `SModelramingSFpremieWg` | random-normal | normal (mean=15, sd=40) |  |
| `SIndAvrLkvOudrWn` | codelist-hardcoded | codelist: INDICATOR_01 | [INDICATOR_01](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SIndAvrLkvAgWn` | codelist-hardcoded | codelist: INDICATOR_01 | [INDICATOR_01](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SIndAvrLkvDgBafSb` | codelist-hardcoded | codelist: INDICATOR_01 | [INDICATOR_01](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SIndAvrLkvHpAgWn` | codelist-hardcoded | codelist: INDICATOR_01 | [INDICATOR_01](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `CdRdnEindArbov` | codelist-hardcoded | codelist: CDRDNEINDARB | [CDRDNEINDARB](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `CdCaoInl_crypt` | random-id | random hex, width=32 |  |
| `IndArbovOnbepTd` | codelist-hardcoded | codelist: INDICATOR_01 | [INDICATOR_01](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `IndSchriftArbov` | codelist-hardcoded | codelist: INDICATOR_01 | [INDICATOR_01](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `IndOprov` | codelist-hardcoded | codelist: INDICATOR_01 | [INDICATOR_01](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `IndJrurennrm` | codelist-hardcoded | codelist: INDICATOR_01 | [INDICATOR_01](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `PRLNUFO` | random-normal | normal (mean=10, sd=25) |  |
| `PRLNAWFANWLg` | random-normal | normal (mean=30, sd=30) |  |
| `PRLNAWFANWHg` | random-normal | normal (mean=50, sd=40) |  |
| `PRLNAWFANWHz` | random-normal | normal (mean=0, sd=10) |  |
| `PrAwfLg` | random-normal | normal (mean=10, sd=15) |  |
| `PrAwfHg` | random-normal | normal (mean=15, sd=20) |  |
| `PrAwfHz` | random-normal | normal (mean=0, sd=5) |  |
| `INDPUBAANONBEPTD` | codelist-hardcoded | codelist: INDICATOR_01 | [INDICATOR_01](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `OPBAVWB` | random-normal | normal (mean=5, sd=15) |  |
| `OPNAVWB` | random-normal | normal (mean=5, sd=15) |  |
| `PRLNAOFANWHG` | random-normal | normal (mean=10, sd=20) |  |
| `PRLNAOFANWLG` | random-normal | normal (mean=5, sd=10) |  |
| `PRLNAOFANWUIT` | random-normal | normal (mean=0, sd=5) |  |
| `PRAOFHG` | random-normal | normal (mean=5, sd=10) |  |
| `PRAOFLG` | random-normal | normal (mean=3, sd=8) |  |
| `PRAOFUIT` | random-normal | normal (mean=0, sd=5) |  |
| `OPSLWKO` | random-normal | normal (mean=5, sd=15) |  |
| `PRLNWHKANW` | random-normal | normal (mean=10, sd=20) |  |
| `PRLNAWFANWUIT` | random-normal | normal (mean=0, sd=5) |  |
| `PRAWFUIT` | random-normal | normal (mean=0, sd=5) |  |
| `INDDEELNTIJDSPF` | codelist-hardcoded | codelist: INDICATOR_01 | [INDICATOR_01](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |

</details>

</details>

<details>
<summary><strong>Vermogens van huishoudens (VEHTAB)</strong> — 20 columns across 1 files (15 statline-calibrated)</summary>

<details>
<summary><code>VEH</code> — 20 columns (15 statline-calibrated)</summary>

| Column | Level | Source | Codelist |
|--------|-------|--------|----------|
| `RINPERSOONSHKW` | constant | value: R | [RINPERSOONSHKW](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/vehtab/codelists.yaml) |
| `RINPERSOONHKW` | spine-derived | spine.hh.RINPERSOON_Ref |  |
| `VEHP100WELVAART` | spine-derived | spine.hh.P100WELVAART |  |
| `VEHP100HVERM` | spine-derived | spine.hh.P100HVERM |  |
| `VEHW1000VERH` | spine-derived | spine.hh.VERMHH |  |
| `VEHW1100BEZH` | statline-calibrated | params: bezh_mean (83834NED) |  |
| `VEHW1110FINH` | statline-calibrated | params: finh_mean (83834NED) |  |
| `VEHW1111BANH` | statline-calibrated | params: banh_mean (83834NED) |  |
| `VEHW1112EFFH` | statline-calibrated | params: effh_mean (83834NED) |  |
| `VEHW1120ONRH` | statline-calibrated | params: onrh_mean (83834NED) |  |
| `VEHW1121WONH` | statline-calibrated | params: wonh_mean (83834NED) |  |
| `VEHW1122OGOH` | statline-calibrated | params: ogoh_mean (83834NED) |  |
| `VEHW1130ONDH` | statline-calibrated | params: ondh_mean (83834NED) |  |
| `VEHW1140ABEH` | statline-calibrated | params: abeh_mean (83834NED) |  |
| `VEHW1150OVEH` | statline-calibrated | params: oveh_mean (83834NED) |  |
| `VEHW1200STOH` | statline-calibrated | params: stoh_mean (83834NED) |  |
| `VEHW1210SHYH` | statline-calibrated | params: shyh_mean (83834NED) |  |
| `VEHW1220SSTH` | statline-calibrated | params: ssth_mean (83834NED) |  |
| `VEHW1230SOVH` | statline-calibrated | params: sovh_mean (83834NED) |  |
| `VEHWVEREXEWH` | statline-calibrated | params: verexewh_mean (83834NED) |  |

</details>

</details>

<details>
<summary><strong>Energieverbruik particuliere woningen (ENERGIEVERBRUIKTAB)</strong> — 20 columns across 1 files (4 statline-calibrated)</summary>

<details>
<summary><code>ENERGIEVERBRUIK</code> — 20 columns (4 statline-calibrated)</summary>

| Column | Level | Source | Codelist |
|--------|-------|--------|----------|
| `SOORTOBJECTNUMMER` | spine-derived | spine.obj.SOORTOBJECTNUMMER | [SOORTOBJECTNUMMER](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/energieverbruik/codelists.yaml) |
| `RINOBJECTNUMMER` | spine-derived | spine.obj.RINOBJECTNUMMER |  |
| `WONINGT` | constant | value:   |  |
| `WOONR` | constant | value:   |  |
| `STADSW` | statline-calibrated | params: stadsverwarming_categorical (Kerncijfers wijken en buurten) | [STADSW](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/energieverbruik/codelists.yaml) |
| `GAS` | statline-calibrated | params: gas_mean (Kerncijfers wijken en buurten) |  |
| `ELEK` | statline-calibrated | params: elek_mean (Kerncijfers wijken en buurten) |  |
| `GASBRON` | codelist-hardcoded | codelist: GASBRON | [GASBRON](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/energieverbruik/codelists.yaml) |
| `ELEKBRON` | codelist-hardcoded | codelist: ELEKBRON | [ELEKBRON](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/energieverbruik/codelists.yaml) |
| `ELEKTERUG` | random-normal | normal (mean=500, sd=1200) |  |
| `ELEKNETTO` | random-normal | normal (mean=2400, sd=1200) |  |
| `GASSJV` | random-normal | normal (mean=1100, sd=620) |  |
| `WARMTESCHATTING` | random-normal | normal (mean=35, sd=20) |  |
| `ZONPV` | statline-calibrated | params: solar_pv_categorical (Kerncijfers wijken en buurten) | [ZONPV](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/energieverbruik/codelists.yaml) |
| `ZONVERMOGEN1JAN` | random-normal | normal (mean=2.5, sd=3) |  |
| `ZONVERMOGEN31DEC` | random-normal | normal (mean=2.8, sd=3.2) |  |
| `ZONPVBRON` | codelist-hardcoded | codelist: ZONPVBRON | [ZONPVBRON](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/energieverbruik/codelists.yaml) |
| `HOOFDVERWARMING31DEC` | codelist-hardcoded | codelist: HOOFDVERWARMING31DEC | [HOOFDVERWARMING31DEC](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/energieverbruik/codelists.yaml) |
| `WONINGBEWONING10PROFIELEN` | codelist-hardcoded | codelist: WONINGBEWONING10PROFIELEN | [WONINGBEWONING10PROFIELEN](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/energieverbruik/codelists.yaml) |
| `KBHOOFDVERWARMING31DEC` | codelist-hardcoded | codelist: KBHOOFDVERWARMING31DEC | [KBHOOFDVERWARMING31DEC](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/energieverbruik/codelists.yaml) |

</details>

</details>

<details>
<summary><strong>GBA Bevolkingsregister</strong> — 22 columns across 3 files (0 statline-calibrated)</summary>

<details>
<summary><code>GBAADRESOBJECTBUS</code> — 8 columns (0 statline-calibrated)</summary>

| Column | Level | Source | Codelist |
|--------|-------|--------|----------|
| `RINPERSOONS` | spine-derived | spine.pers.RINPERSOONS | [rinpersoons](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/gba/codelists.yaml) |
| `RINPERSOON` | spine-derived | spine.pers.RINPERSOON |  |
| `SOORTOBJECTNUMMER` | spine-derived | spine.pers.SOORTOBJECTNUMMER | [soortobjectnummer](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/gba/codelists.yaml) |
| `RINOBJECTNUMMER` | spine-derived | spine.pers.RINOBJECTNUMMER |  |
| `GBADATUMAANVANGADRESHOUDING` | spine-derived | spine.pers.AanvangWoonduur |  |
| `GBADATUMEINDEADRESHOUDING` | constant | value: 99999999 |  |
| `GBAGEMEENTEVANINSCHRIJVING` | computed | computed.GemeenteCodeJJJJ1Jan |  |
| `GBAAANTALINGESCHREVENENOPNUMMERAANDUIDING` | random-normal | normal (mean=2.2, sd=1.5) |  |

</details>

<details>
<summary><code>GBAHUISHOUDENSBUS</code> — 8 columns (0 statline-calibrated)</summary>

| Column | Level | Source | Codelist |
|--------|-------|--------|----------|
| `RINPERSOONS` | spine-derived | spine.pers.RINPERSOONS | [rinpersoons](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/gba/codelists.yaml) |
| `RINPERSOON` | spine-derived | spine.pers.RINPERSOON |  |
| `HUESSION` | spine-derived | spine.pers.HUISHOUDNR |  |
| `DAESSION` | spine-derived | spine.pers.DATUMAANVANGHH |  |
| `TYPHH` | spine-derived | spine.pers.TYPHH | [typhh](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/gba/codelists.yaml) |
| `PLESSION` | spine-derived | spine.pers.PLHH | [plhh](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/gba/codelists.yaml) |
| `AANESSION` | spine-derived | spine.pers.AantalPersonenPerHuishouden |  |
| `REFESSION` | spine-derived | spine.pers.REFPERSOONHH |  |

</details>

<details>
<summary><code>GBAPERSOONKTAB</code> — 6 columns (0 statline-calibrated)</summary>

| Column | Level | Source | Codelist |
|--------|-------|--------|----------|
| `RINPERSOONS` | spine-derived | spine.pers.RINPERSOONS | [rinpersoons](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/gba/codelists.yaml) |
| `RINPERSOON` | spine-derived | spine.pers.RINPERSOON |  |
| `GBAGESLACHT` | spine-derived | spine.pers.GBAGeslachtsAanduiding | [geslacht](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/gba/codelists.yaml) |
| `GBAGEBOORTEJAAR` | spine-derived | spine.pers.GBAGeboorteJaar |  |
| `GBAGEBOORTEMAAND` | random-uniform | uniform [1, 12] | [geboortemaand](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/gba/codelists.yaml) |
| `GBAGEBOORTEDAG` | constant | value: 01 |  |

</details>

</details>

