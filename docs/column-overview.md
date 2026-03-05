# Column Overview

Overview of all simulated columns

<details>
<summary><strong>CBS Woonbase</strong> — 182 columns across 9 files (0 statline-calibrated)</summary>

<details>
<summary><code>WOONBASEEKHuishoudensWV</code> — 31 columns (0 statline-calibrated)</summary>

| Column | Level | Spatial | Source | Codelist |
|--------|-------|---------|--------|----------|
| `RINPERSOONS` | spine-derived | NL | spine.hh.RINPERSOONS_Ref |  |
| `RINPERSOON` | spine-derived | NL | spine.hh.RINPERSOON_Ref |  |
| `AGHT1JAN, AGHT31DEC` | codelist-hardcoded |  | codelist: AGHT | [AGHT](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `AGIAH1JAN, AGIAH31DEC` | codelist-hardcoded |  | codelist: AGIAH | [AGIAH](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `AGTSH1JAN, AGTSH31DEC` | codelist-hardcoded |  | codelist: AGTSH | [AGTSH](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `AOWHT1JAN, AOWHT31DEC` | codelist-hardcoded |  | codelist: AOWHT | [AOWHT](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `ARMOEDE1JAN, ARMOEDE31DEC` | random-uniform |  | uniform [50, 500] |  |
| `ARMSOC1JAN, ARMSOC31DEC` | random-uniform |  | uniform [50, 500] |  |
| `BBIHJ1JAN, BBIHJ31DEC` | random-uniform |  | uniform [1, 20] |  |
| `BELIAGHT1JAN, BELIAGHT31DEC` | random-uniform |  | uniform [5000, 80000] |  |
| `BELIAGIAH1JAN, BELIAGIAH31DEC` | random-uniform |  | uniform [5000, 80000] |  |
| `BELIAGTSH1JAN, BELIAGTSH31DEC` | random-uniform |  | uniform [5000, 80000] |  |
| `BELIH1JAN, BELIH31DEC` | spine-derived | NL | spine.hh.BELIH |  |
| `BESTINKH1JAN, BESTINKH31DEC` | spine-derived | NL | spine.hh.BESTINKH |  |
| `BETAALBUDGET1JAN, BETAALBUDGET31DEC` | random-uniform |  | uniform [-10000, 60000] |  |
| `BETAALRESERVE1JAN, BETAALRESERVE31DEC` | random-uniform |  | uniform [-5000, 50000] |  |
| `CORBETAALBUDGET1JAN, CORBETAALBUDGET31DEC` | codelist-hardcoded |  | hardcoded probs |  |
| `EHALGR1JAN, EHALGR31DEC` | random-uniform |  | uniform [1, 30] |  |
| `GESTINKH1JAN, GESTINKH31DEC` | spine-derived | NL | spine.hh.GESTINKH |  |
| `LEERGROND1JAN, LEERGROND31DEC` | random-uniform |  | uniform [0, 50000] |  |
| `P100HBEST1JAN, P100HBEST31DEC` | spine-derived | NL | spine.hh.P100HBEST |  |
| `P100HGEST1JAN, P100HGEST31DEC` | spine-derived | NL | spine.hh.P100HGEST |  |
| `P100HVERM1JAN, P100HVERM31DEC` | spine-derived | NL | spine.hh.P100HVERM |  |
| `P100WELVAART1JAN, P100WELVAART31DEC` | spine-derived | NL | spine.hh.P100WELVAART |  |
| `POPFEC1JAN, POPFEC31DEC` | codelist-hardcoded |  | codelist: POPFEC | [POPFEC](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `POPIIV1JAN, POPIIV31DEC` | codelist-hardcoded |  | codelist: POPIIV | [POPIIV](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `POPIIVWONING1JAN, POPIIVWONING31DEC` | random-uniform |  | uniform [0, 10] |  |
| `VERMHH1JAN, VERMHH31DEC` | spine-derived | NL | spine.hh.VERMHH |  |
| `VROMHH1JAN, VROMHH31DEC` | spine-derived | NL | spine.hh.VROMHH |  |
| `W1000VERH1JAN, W1000VERH31DEC` | random-uniform |  | uniform [0, 500000] |  |
| `VERSCHILIIV1JAN, VERSCHILIIV31DEC` | codelist-hardcoded |  | codelist: VERSCHILIIV | [VERSCHILIIV](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |

</details>

<details>
<summary><code>ExtraKenmerkenPanden</code> — 18 columns (0 statline-calibrated)</summary>

| Column | Level | Spatial | Source | Codelist |
|--------|-------|---------|--------|----------|
| `PandID` | spine-derived | NL | spine.obj.PandID1Jan |  |
| `PandAantalVbos1Jan, PandAantalVbos31Dec` | random-uniform |  | uniform [1, 20] |  |
| `PandAantalWoning1Jan, PandAantalWoning31Dec` | random-uniform |  | uniform [0, 15] |  |
| `PandAantalNietWoning1Jan, PandAantalNietWoning31Dec` | random-uniform |  | uniform [0, 5] |  |
| `PandOppTotWoning1Jan, PandOppTotWoning31Dec` | random-uniform |  | uniform [0, 5000] |  |
| `PandOppTotNietWoning1Jan, PandOppTotNietWoning31Dec` | random-uniform |  | uniform [0, 3000] |  |
| `PandOppGemWoning1Jan, PandOppGemWoning31Dec` | random-uniform |  | uniform [30, 250] |  |
| `PandOppGemNietWoning1Jan, PandOppGemNietWoning31Dec` | random-uniform |  | uniform [30, 500] |  |
| `PandWinkelfunctie1Jan, PandWinkelfunctie31Dec` | codelist-hardcoded |  | codelist: PANDFUNCTIE | [PANDFUNCTIE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `PandKantoorfunctie1Jan, PandKantoorfunctie31Dec` | codelist-hardcoded |  | codelist: PANDFUNCTIE | [PANDFUNCTIE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `PandIndustriefunctie1Jan, PandIndustriefunctie31Dec` | codelist-hardcoded |  | codelist: PANDFUNCTIE | [PANDFUNCTIE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `PandBijeenkomstfunctie1Jan, PandBijeenkomstfunctie31Dec` | codelist-hardcoded |  | codelist: PANDFUNCTIE | [PANDFUNCTIE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `PandGezondheidszorgfunctie1Jan, PandGezondheidszorgfunctie31Dec` | codelist-hardcoded |  | codelist: PANDFUNCTIE | [PANDFUNCTIE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `PandAnderefunctie1Jan, PandAnderefunctie31Dec` | codelist-hardcoded |  | codelist: PANDFUNCTIE | [PANDFUNCTIE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `PandTransformatie1Jan, PandTransformatie31Dec` | codelist-hardcoded |  | codelist: PANDTRANSFORMATIE | [PANDTRANSFORMATIE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `PandHoogte` | random-uniform |  | uniform [3, 60] |  |
| `PandAantalVerdiepingen` | random-uniform |  | uniform [1, 15] |  |
| `PandDaktype` | codelist-hardcoded |  | codelist: PANDDAKTYPE | [PANDDAKTYPE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |

</details>

<details>
<summary><code>WoonbaseKenmerkenHuishoudens</code> — 9 columns (0 statline-calibrated)</summary>

| Column | Level | Spatial | Source | Codelist |
|--------|-------|---------|--------|----------|
| `HUISHOUDNR1Jan, HUISHOUDNR31Dec` | spine-derived | NL | spine.hh.HUISHOUDNR |  |
| `DatumAanvangHH1Jan, DatumAanvangHH31Dec` | spine-derived | NL | spine.hh.DATUMAANVANGHH |  |
| `IMPUTATIECODEHH1Jan, IMPUTATIECODEHH31Dec` | spine-derived | NL | spine.hh.IMPUTATIECODEHH | [IMPUTATIECODEHH](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `RefPersoonHH1Jan, RefPersoonHH31Dec` | spine-derived | NL | spine.hh.REFPERSOONHH_Ref | [REFPERSOONHH](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `RINPERSOON` | spine-derived | NL | spine.hh.RINPERSOON_Ref |  |
| `RINPERSOONS` | spine-derived | NL | spine.hh.RINPERSOONS_Ref |  |
| `TYPHH1Jan, TYPHH31Dec` | spine-derived | NL | spine.hh.TYPHH | [TYPHH](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `AantalKinderenPerHuishouden1Jan, AantalKinderenPerHuishouden31Dec` | spine-derived | NL | spine.hh.AantalKinderenPerHuishouden |  |
| `AantalPersonenPerHuishouden1Jan, AantalPersonenPerHuishouden31Dec` | spine-derived | NL | spine.hh.AantalPersonenPerHuishouden |  |

</details>

<details>
<summary><code>WoonbaseKenmerkenWoonruimten</code> — 13 columns (0 statline-calibrated)</summary>

| Column | Level | Spatial | Source | Codelist |
|--------|-------|---------|--------|----------|
| `RINOBJECTNUMMER` | spine-derived | gemeente | spine.obj.RINOBJECTNUMMER |  |
| `SOORTOBJECTNUMMER` | spine-derived | gemeente | spine.obj.SOORTOBJECTNUMMER |  |
| `GEMEENTECODEJJJJ1Jan, GEMEENTECODEJJJJ31Dec` | spine-derived | gemeente | spine.obj.GemeenteCodeJJJJ{sfx} |  |
| `WIJKCODEJJJJ1Jan, WIJKCODEJJJJ31Dec` | spine-derived | gemeente | spine.obj.WijkCodeJJJJ{sfx} |  |
| `BUURTCODEJJJJ1Jan, BUURTCODEJJJJ31Dec` | spine-derived | gemeente | spine.obj.BuurtCodeJJJJ{sfx} |  |
| `Indicator_VBOIsNieuwbouw` | spine-derived | NL | spine.obj.Indicator_VBOIsNieuwbouw1Jan | [INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `Indicator_VBOIsNieuwbouwJJJJ-1` | spine-derived | NL | spine.obj.Indicator_VBOIsNieuwbouw1Jan | [INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `VSLSoort1Jan, VSLSoort31Dec` | spine-derived | NL | spine.obj.VSLSoort{sfx} | [VSLSOORT](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `VBOWoningType1Jan, VBOWoningType31Dec` | spine-derived | NL | spine.obj.VBOWoningType{sfx} | [WONINGTYPE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `VBOBouwjaar1Jan, VBOBouwjaar31Dec` | spine-derived | NL | spine.obj.VBOBouwjaar{sfx} |  |
| `VBOOppervlakte1Jan, VBOOppervlakte31Dec` | spine-derived | NL | spine.obj.VBOOppervlakte{sfx} |  |
| `WOZWaardeObjectBAG1Jan, WOZWaardeObjectBAG31Dec` | spine-derived | gemeente | spine.obj.WOZWaardeObjectBAG{sfx} |  |
| `VBOStatus1Jan, VBOStatus31Dec` | spine-derived | NL | spine.obj.VBOStatus{sfx} | [VBOSTATUS](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |

</details>

<details>
<summary><code>WoonbaseKenmerkenPersonen</code> — 17 columns (0 statline-calibrated)</summary>

| Column | Level | Spatial | Source | Codelist |
|--------|-------|---------|--------|----------|
| `RINPERSOON` | spine-derived | NL | spine.pers.RINPERSOON |  |
| `RINPERSOONS` | spine-derived | NL | spine.pers.RINPERSOONS |  |
| `GBABurgerlijkeStaat1Jan, GBABurgerlijkeStaat31Dec` | spine-derived | NL | spine.pers.GBABurgerlijkeStaat |  |
| `GBAGeboorteJaar1Jan, GBAGeboorteJaar31Dec` | spine-derived | NL | spine.pers.GBAGeboorteJaar |  |
| `GBAGeslachtsAanduiding1Jan, GBAGeslachtsAanduiding31Dec` | spine-derived | NL | spine.pers.GBAGeslachtsAanduiding | [GESLACHT](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `GEMEENTECODEJJJJ1Jan, GEMEENTECODEJJJJ31Dec` | spine-derived | gemeente | spine.pers.GemeenteCodeJJJJ{sfx} |  |
| `WIJKCODEJJJJ1Jan, WIJKCODEJJJJ31Dec` | spine-derived | gemeente | spine.pers.WijkCodeJJJJ{sfx} |  |
| `BUURTCODEJJJJ1Jan, BUURTCODEJJJJ31Dec` | spine-derived | gemeente | spine.pers.BuurtCodeJJJJ{sfx} |  |
| `PLHH1Jan, PLHH31Dec` | spine-derived | NL | spine.pers.PLHH | [PLHH](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `RINOBJECTNUMMER1Jan, RINOBJECTNUMMER31Dec` | spine-derived | gemeente | spine.pers.RINOBJECTNUMMER |  |
| `SOORTOBJECTNUMMER1Jan, SOORTOBJECTNUMMER31Dec` | spine-derived | gemeente | spine.pers.SOORTOBJECTNUMMER |  |
| `AanvangWoonduur1Jan, AanvangWoonduur31Dec` | spine-derived | NL | spine.pers.AanvangWoonduur |  |
| `OPLNIVSOI2016AGG4HBMETNIRWO1Jan, OPLNIVSOI2016AGG4HBMETNIRWO31Dec` | codelist-hardcoded |  | hardcoded probs |  |
| `OPLNIVSOI2016AGG4HGMETNIRWO1Jan, OPLNIVSOI2016AGG4HGMETNIRWO31Dec` | codelist-hardcoded |  | hardcoded probs |  |
| `OPLNIVSOI2021AGG4HBMETNIRWO1Jan, OPLNIVSOI2021AGG4HBMETNIRWO31Dec` | codelist-hardcoded |  | hardcoded probs |  |
| `OPLNIVSOI2021AGG4HGMETNIRWO1Jan, OPLNIVSOI2021AGG4HGMETNIRWO31Dec` | codelist-hardcoded |  | hardcoded probs |  |
| `GEWICHTHOOGSTEOPL1Jan, GEWICHTHOOGSTEOPL31Dec` | random-uniform |  | uniform [0.5, 1.5] |  |

</details>

<details>
<summary><code>WoonbasePopulatieHuishoudens</code> — 21 columns (0 statline-calibrated)</summary>

| Column | Level | Spatial | Source | Codelist |
|--------|-------|---------|--------|----------|
| `HUISHOUDNR1Jan, HUISHOUDNR31Dec` | spine-derived | NL | spine.hh.HUISHOUDNR |  |
| `DATUMAANVANGHH1Jan, DATUMAANVANGHH31Dec` | spine-derived | NL | spine.hh.DATUMAANVANGHH |  |
| `IMPUTATIECODEHH1Jan, IMPUTATIECODEHH31Dec` | spine-derived | NL | spine.hh.IMPUTATIECODEHH | [IMPUTATIECODEHH](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `RINPERSOONS` | spine-derived | NL | spine.hh.RINPERSOONS_Ref |  |
| `RINPERSOON` | spine-derived | NL | spine.hh.RINPERSOON_Ref |  |
| `RINOBJECTNUMMER1Jan, RINOBJECTNUMMER31Dec` | spine-derived | gemeente | spine.hh.RINOBJECTNUMMER |  |
| `SOORTOBJECTNUMMER1Jan, SOORTOBJECTNUMMER31Dec` | spine-derived | gemeente | spine.hh.SOORTOBJECTNUMMER |  |
| `TYPHH1Jan, TYPHH31Dec` | spine-derived | NL | spine.hh.TYPHH | [TYPHH](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `AantalPersonenPerHuishouden1Jan, AantalPersonenPerHuishouden31Dec` | spine-derived | NL | spine.hh.AantalPersonenPerHuishouden |  |
| `AantalKinderenPerHuishouden1Jan, AantalKinderenPerHuishouden31Dec` | spine-derived | NL | spine.hh.AantalKinderenPerHuishouden |  |
| `LeeftijdRefPersoon1Jan, LeeftijdRefPersoon31Dec` | spine-derived | NL | spine.hh.LeeftijdRefPersoon |  |
| `PLHHRefPersoon1Jan, PLHHRefPersoon31Dec` | spine-derived | NL | spine.hh.PLHH_Ref | [PLHH](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `GBAGeslachtsaanduidingRefPersoon1Jan, GBAGeslachtsaanduidingRefPersoon31Dec` | spine-derived | NL | spine.hh.GBAGeslachtsAanduiding_Ref | [GESLACHT](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `GemeenteCodeJJJJ1Jan, GemeenteCodeJJJJ31Dec` | spine-derived | gemeente | spine.hh.GemeenteCodeJJJJ{sfx} |  |
| `VSLSoort1Jan, VSLSoort31Dec` | spine-derived | NL | spine.hh.VSLSoort{sfx} | [VSLSOORT](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `WOZWaardeObjectBAGKlasse1Jan, WOZWaardeObjectBAGKlasse31Dec` | spine-derived | gemeente | spine.hh.WOZWaardeObjectBAGKlasse{sfx} | [WOZKLASSE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `VBOBouwJaarKlasse1Jan, VBOBouwJaarKlasse31Dec` | spine-derived | NL | spine.hh.VBOBouwJaarKlasse{sfx} | [BOUWJAARKLASSE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `VBOOppervlakteKlasse1Jan, VBOOppervlakteKlasse31Dec` | spine-derived | NL | spine.hh.VBOOppervlakteKlasse{sfx} | [OPPKLASSE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `VBOWoningType1Jan, VBOWoningType31Dec` | spine-derived | NL | spine.hh.VBOWoningType{sfx} | [WONINGTYPE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `TypeEigenaar1Jan, TypeEigenaar31Dec` | spine-derived | NL | spine.hh.TypeEigenaar{sfx} | [TYPEIGENAAR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `Indicator_HHIsAanwezig1Jan, Indicator_HHIsAanwezig31Dec` | constant |  | value: 1 | [INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |

</details>

<details>
<summary><code>WoonbasePopulatieWoonruimten</code> — 26 columns (0 statline-calibrated)</summary>

| Column | Level | Spatial | Source | Codelist |
|--------|-------|---------|--------|----------|
| `SOORTOBJECTNUMMER` | spine-derived | gemeente | spine.obj.SOORTOBJECTNUMMER |  |
| `RINOBJECTNUMMER` | spine-derived | gemeente | spine.obj.RINOBJECTNUMMER |  |
| `PandID1Jan, PandID31Dec` | spine-derived | NL | spine.obj.PandID{sfx} |  |
| `VSLSoort1Jan, VSLSoort31Dec` | spine-derived | NL | spine.obj.VSLSoort{sfx} | [VSLSOORT](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `HUISHOUDNR1Jan, HUISHOUDNR31Dec` | spine-derived | NL | spine.obj.HUISHOUDNR |  |
| `DATUMAANVANGHH{sfx_lower}` | spine-derived | NL | spine.obj.DATUMAANVANGHH |  |
| `RINPERSOONS_Ref{sfx_lower}` | spine-derived | NL | spine.obj.RINPERSOONS_Ref2 |  |
| `RINPERSOON_Ref{sfx_lower}` | spine-derived | NL | spine.obj.RINPERSOON_Ref2 |  |
| `VBOWoningType1Jan, VBOWoningType31Dec` | spine-derived | NL | spine.obj.VBOWoningType{sfx} | [WONINGTYPE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `VBOBouwJaarKlasse1Jan, VBOBouwJaarKlasse31Dec` | spine-derived | NL | spine.obj.VBOBouwJaarKlasse{sfx} | [BOUWJAARKLASSE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `VBOOppervlakteKlasse1Jan, VBOOppervlakteKlasse31Dec` | spine-derived | NL | spine.obj.VBOOppervlakteKlasse{sfx} | [OPPKLASSE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `WOZWaardeObjectBAGKlasse1Jan, WOZWaardeObjectBAGKlasse31Dec` | spine-derived | gemeente | spine.obj.WOZWaardeObjectBAGKlasse{sfx} | [WOZKLASSE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `TypeEigenaar1Jan, TypeEigenaar31Dec` | spine-derived | NL | spine.obj.TypeEigenaar{sfx} | [TYPEIGENAAR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `AantalPersonenPerVSLKlasse1Jan, AantalPersonenPerVSLKlasse31Dec` | computed |  | computed.AantalPersonenPerVSLKlasse | [PERSKLASSE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `AantalHuishoudensPerVSLKlasse1Jan, AantalHuishoudensPerVSLKlasse31Dec` | constant |  | value: 1 | [HHKLASSE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `AantalKinderenPerVSL1Jan, AantalKinderenPerVSL31Dec` | spine-derived | NL | spine.obj.AantalKinderenPerVSL |  |
| `LeeftijdJongsteKindPerVSL1Jan, LeeftijdJongsteKindPerVSL31Dec` | spine-derived | NL | spine.obj.LeeftijdJongsteKindPerVSL |  |
| `TYPHH1Jan, TYPHH31Dec` | spine-derived | NL | spine.obj.TYPHH | [TYPHH](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `GemeenteCodeJJJJ1Jan, GemeenteCodeJJJJ31Dec` | spine-derived | gemeente | spine.obj.GemeenteCodeJJJJ{sfx} |  |
| `Indicator_VBOIsAanwezig1Jan, Indicator_VBOIsAanwezig31Dec` | spine-derived | NL | spine.obj.Indicator_VBOIsAanwezig{sfx} | [INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `Indicator_VSLIsAanwezig1Jan, Indicator_VSLIsAanwezig31Dec` | spine-derived | NL | spine.obj.Indicator_VSLIsAanwezig{sfx} | [INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `Indicator_VBOIsGesloopt` | spine-derived | NL | spine.obj.Indicator_VBOIsGesloopt | [INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `Indicator_VSLIsOntrokken` | spine-derived | NL | spine.obj.Indicator_VSLIsOntrokken | [INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `Indicator_VBOIsTransformatie` | spine-derived | NL | spine.obj.Indicator_VBOIsTransformatie | [INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `Indicator_VBOIsNieuwbouw` | spine-derived | NL | spine.obj.Indicator_VBOIsNieuwbouw | [INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `Indicator_VSLIsNieuw` | spine-derived | NL | spine.obj.Indicator_VSLIsNieuw | [INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |

</details>

<details>
<summary><code>WoonbasePopulatiePersonen</code> — 31 columns (0 statline-calibrated)</summary>

| Column | Level | Spatial | Source | Codelist |
|--------|-------|---------|--------|----------|
| `RINPERSOON` | spine-derived | NL | spine.pers.RINPERSOON |  |
| `RINPERSOONS` | spine-derived | NL | spine.pers.RINPERSOONS |  |
| `RefPersoonHH1Jan, RefPersoonHH31Dec` | spine-derived | NL | spine.pers.REFPERSOONHH | [REFPERSOONHH](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `HUISHOUDNR1Jan, HUISHOUDNR31Dec` | spine-derived | NL | spine.pers.HUISHOUDNR |  |
| `DATUMAANVANGHH1Jan, DATUMAANVANGHH31Dec` | spine-derived | NL | spine.pers.DATUMAANVANGHH |  |
| `IMPUTATIECODEHH1Jan, IMPUTATIECODEHH31Dec` | spine-derived | NL | spine.pers.IMPUTATIECODEHH | [IMPUTATIECODEHH](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `RINOBJECTNUMMER1Jan, RINOBJECTNUMMER31Dec` | spine-derived | gemeente | spine.pers.RINOBJECTNUMMER |  |
| `SOORTOBJECTNUMMER1Jan, SOORTOBJECTNUMMER31Dec` | spine-derived | gemeente | spine.pers.SOORTOBJECTNUMMER |  |
| `Indicator_PersoonIsGeboren` | spine-derived | NL | spine.pers.Indicator_PersoonIsGeboren | [INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `Indicator_PersoonIsOverleden` | spine-derived | NL | spine.pers.Indicator_PersoonIsOverleden | [INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `Indicator_PersoonIsGeemigreerd` | spine-derived | NL | spine.pers.Indicator_PersoonIsGeemigreerd | [INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `Indicator_PersoonIsAdministratiefAfgevoerd` | spine-derived | NL | spine.pers.Indicator_PersoonIsAdministratiefAfgevoerd | [INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `Indicator_PersoonIsGeimmigreerd` | spine-derived | NL | spine.pers.Indicator_PersoonIsGeimmigreerd | [INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `Indicator_PersoonIsAdministratiefOpgenomen` | spine-derived | NL | spine.pers.Indicator_PersoonIsAdministratiefOpgenomen | [INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `Indicator_PersoonIsVerhuisd` | spine-derived | NL | spine.pers.Indicator_PersoonIsVerhuisd | [INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `Indicator_PersoonIsAanwezig1Jan` | spine-derived | NL | spine.pers.Indicator_PersoonIsAanwezig1Jan | [INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `Indicator_PersoonIsAanwezig31Dec` | spine-derived | NL | spine.pers.Indicator_PersoonIsAanwezig31Dec | [INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `AantalKeerVerhuisd` | spine-derived | NL | spine.pers.AantalKeerVerhuisd |  |
| `PLHH1Jan, PLHH31Dec` | spine-derived | NL | spine.pers.PLHH | [PLHH](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `TYPHH1Jan, TYPHH31Dec` | spine-derived | NL | spine.pers.TYPHH | [TYPHH](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `GBAGeslachtsAanduiding1Jan, GBAGeslachtsAanduiding31Dec` | spine-derived | NL | spine.pers.GBAGeslachtsAanduiding | [GESLACHT](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `GBAGeboorteJaar1Jan, GBAGeboorteJaar31Dec` | spine-derived | NL | spine.pers.GBAGeboorteJaar |  |
| `GBABurgerlijkeStaat1Jan, GBABurgerlijkeStaat31Dec` | spine-derived | NL | spine.pers.GBABurgerlijkeStaat |  |
| `AantalPersonenPerHuishouden1Jan, AantalPersonenPerHuishouden31Dec` | spine-derived | NL | spine.pers.AantalPersonenPerHuishouden |  |
| `GemeenteCodeJJJJ1Jan, GemeenteCodeJJJJ31Dec` | spine-derived | gemeente | spine.pers.GemeenteCodeJJJJ{sfx} |  |
| `VSLSoort1Jan, VSLSoort31Dec` | spine-derived | NL | spine.pers.VSLSoort{sfx} | [VSLSOORT](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `TypeEigenaar1Jan, TypeEigenaar31Dec` | spine-derived | NL | spine.pers.TypeEigenaar{sfx} | [TYPEIGENAAR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `VBOWoningType1Jan, VBOWoningType31Dec` | spine-derived | NL | spine.pers.VBOWoningType{sfx} | [WONINGTYPE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `VBOBouwJaarKlasse1Jan, VBOBouwJaarKlasse31Dec` | spine-derived | NL | spine.pers.VBOBouwJaarKlasse{sfx} | [BOUWJAARKLASSE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `VBOOppervlakteKlasse1Jan, VBOOppervlakteKlasse31Dec` | spine-derived | NL | spine.pers.VBOOppervlakteKlasse{sfx} | [OPPKLASSE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `WOZWaardeObjectBAGKlasse1Jan, WOZWaardeObjectBAGKlasse31Dec` | spine-derived | gemeente | spine.pers.WOZWaardeObjectBAGKlasse{sfx} | [WOZKLASSE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |

</details>

<details>
<summary><code>WoonbaseSleutelbestand</code> — 16 columns (0 statline-calibrated)</summary>

| Column | Level | Spatial | Source | Codelist |
|--------|-------|---------|--------|----------|
| `RINPERSOONS` | spine-derived | NL | spine.pers.RINPERSOONS |  |
| `RINPERSOON` | spine-derived | NL | spine.pers.RINPERSOON |  |
| `REFPERSOONHH` | spine-derived | NL | spine.pers.REFPERSOONHH | [REFPERSOONHH](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `PLHH` | spine-derived | NL | spine.pers.PLHH | [PLHH](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `HUISHOUDNR` | spine-derived | NL | spine.pers.HUISHOUDNR |  |
| `DATUMAANVANGHH` | spine-derived | NL | spine.pers.DATUMAANVANGHH |  |
| `TYPHH` | spine-derived | NL | spine.pers.TYPHH | [TYPHH](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `IMPUTATIECODEHH` | spine-derived | NL | spine.pers.IMPUTATIECODEHH | [IMPUTATIECODEHH](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `SOORTOBJECTNUMMER` | spine-derived | gemeente | spine.pers.SOORTOBJECTNUMMER |  |
| `RINOBJECTNUMMER` | spine-derived | gemeente | spine.pers.RINOBJECTNUMMER |  |
| `INVOORRAAD` | constant |  | value: 1 | [INVOORRAAD](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `VBOVOORRAADTYPE` | constant |  | value: 0 | [VBOVOORRAADTYPE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `BEGINGELDIGHEID` | constant |  | template: {jan1} |  |
| `EINDGELDIGHEID` | constant |  | template: {dec31} |  |
| `REDENBEGINGELDIGHEID` | codelist-hardcoded |  | hardcoded probs |  |
| `REDENEINDGELDIGHEID` | constant |  | value: NVT |  |

</details>

</details>

<details>
<summary><strong>RDW Motorvoertuigenpark</strong> — 19 columns across 2 files (6 statline-calibrated)</summary>

<details>
<summary><code>RDWNPACT</code> — 13 columns (5 statline-calibrated)</summary>

| Column | Level | Spatial | Source | Codelist |
|--------|-------|---------|--------|----------|
| `RINPERSOONS` | codelist-hardcoded |  | codelist: RINPERSOONS_RDW | [RINPERSOONS_RDW](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/rdw/codelists.yaml) |
| `RINPERSOON` | spine-derived | NL | spine.pers.RINPERSOON |  |
| `RINKENTEKEN` | spine-derived | NL | spine.pers.RINKENTEKEN |  |
| `KLEURCODEVRTG` | statline-calibrated | NL | params: kleur_p (85237NED, 85236NED, 85404NED) | [KLEURCODE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/rdw/codelists.yaml) |
| `EERSTETOELDAT1VRTG` | statline-calibrated | NL | params: bouwjaar_p (85237NED, 85236NED, 85404NED) |  |
| `SRTREFVRTG` | codelist-hardcoded |  | codelist: SRTREF | [SRTREF](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/rdw/codelists.yaml) |
| `VRTGSOORT` | statline-calibrated | NL | params: vrtgsoort_p (85237NED, 85236NED, 85404NED) | [VRTGSOORT](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/rdw/codelists.yaml) |
| `BRANDSTCODECORVRTG` | statline-calibrated | NL | params: brandstof_p (85237NED, 85236NED, 85404NED) | [BRANDSTOF](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/rdw/codelists.yaml) |
| `MASSALEEGCORVRTG` | statline-calibrated | NL | params: gewicht_mean (85237NED, 85236NED, 85404NED) |  |
| `MAXLAADVERMCORVRTG` | random-uniform |  | uniform [0, 3000] |  |
| `AANTALCYLCORVRTG` | codelist-hardcoded |  | hardcoded probs |  |
| `CYLININHOUDCORVRTG` | random-normal |  | normal (mean=1600, sd=600) |  |
| `SOORTBROMFIETSCOR` | codelist-hardcoded |  | codelist: SOORTBROMFIETS | [SOORTBROMFIETS](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/rdw/codelists.yaml) |

</details>

<details>
<summary><code>VERKEERSPRESTATIE</code> — 6 columns (1 statline-calibrated)</summary>

| Column | Level | Spatial | Source | Codelist |
|--------|-------|---------|--------|----------|
| `RINKENTEKEN` | spine-derived | NL | spine.pers.RINKENTEKEN |  |
| `RinpersoonsVP` | codelist-hardcoded |  | codelist: RINPERSOONS_RDW | [RINPERSOONS_RDW](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/rdw/codelists.yaml) |
| `RinpersoonVP` | spine-derived | NL | spine.pers.RINPERSOON |  |
| `VPGEWICHT` | codelist-hardcoded |  | hardcoded probs |  |
| `VPDGNWEG` | codelist-hardcoded |  | hardcoded probs |  |
| `VPJAARKM` | statline-calibrated | NL | params: jaarkm_mean (85237NED, 85236NED, 85404NED) |  |

</details>

</details>

<details>
<summary><strong>Banen en lonen (SPOLISBUS)</strong> — 133 columns across 1 files (12 statline-calibrated)</summary>

<details>
<summary><code>SPOLISBUS</code> — 133 columns (12 statline-calibrated)</summary>

| Column | Level | Spatial | Source | Codelist |
|--------|-------|---------|--------|----------|
| `RINPERSOONS` | codelist-hardcoded |  | codelist: RINPERSOONS_SPOLIS | [RINPERSOONS_SPOLIS](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `RINPERSOON` | spine-derived | NL | spine.pers.RINPERSOON |  |
| `IKVID` | random-id |  | random hex, width=32 |  |
| `SDATUMAANVANGIKO` | constant |  | template: {jan1} |  |
| `SDATUMEINDEIKO` | constant |  | template: {dec31} |  |
| `SAANTSV` | random-normal |  | normal (mean=18, sd=6) |  |
| `SAANTVERLU` | random-normal |  | normal (mean=130, sd=40) |  |
| `SAUTOZAAK` | statline-calibrated | NL | params: autozaak_mean (81431NED) |  |
| `SBAANDAGEN` | codelist-hardcoded |  | hardcoded probs |  |
| `SBASISLOON` | statline-calibrated | NL | params: basisloon_mean (81431NED) |  |
| `SBASISUREN` | statline-calibrated | NL | params: basisuren_mean (81431NED) |  |
| `SBEDRALINWWB` | random-normal |  | normal (mean=0, sd=50) |  |
| `SBEDRRCHTAL` | random-normal |  | normal (mean=0, sd=20) |  |
| `SBEDRZDAFTR` | random-normal |  | normal (mean=0, sd=10) |  |
| `SBIJDRZVW` | random-normal |  | normal (mean=180, sd=100) |  |
| `SBIJZONDEREBELONING` | statline-calibrated | NL | params: bijzbeloning_mean (81431NED) |  |
| `SEXTRSAL` | random-normal |  | normal (mean=50, sd=200) |  |
| `SINCIDENTSAL` | random-normal |  | normal (mean=20, sd=100) |  |
| `SINGLBPH` | random-normal |  | normal (mean=100, sd=200) |  |
| `SLNINGLD` | statline-calibrated | NL | params: loon_mean (81431NED) |  |
| `SLNLBPH` | statline-calibrated | NL | params: lnlbph_mean (81431NED) |  |
| `SLNOWRK` | random-normal |  | normal (mean=50, sd=200) |  |
| `SLNSV` | statline-calibrated | NL | params: lnsv_mean (81431NED) |  |
| `SLNTABBB` | random-normal |  | normal (mean=0, sd=50) |  |
| `SLVLPREG` | random-normal |  | normal (mean=0, sd=50) |  |
| `SLVLPREGTOEG` | random-normal |  | normal (mean=0, sd=50) |  |
| `SOPGRCHTEXTRSAL` | random-normal |  | normal (mean=0, sd=100) |  |
| `SOPGRCHTVAKBSL` | random-normal |  | normal (mean=0, sd=50) |  |
| `SOVERWERKUREN` | random-normal |  | normal (mean=3, sd=8) |  |
| `SPENSIOENPREMIE` | random-normal |  | normal (mean=250, sd=200) |  |
| `SPRAWF` | random-normal |  | normal (mean=90, sd=60) |  |
| `SPRUFO` | random-normal |  | normal (mean=15, sd=30) |  |
| `SPRWAOAOF` | random-normal |  | normal (mean=20, sd=30) |  |
| `SPRWAOAOK` | random-normal |  | normal (mean=15, sd=25) |  |
| `SPRWGF` | random-normal |  | normal (mean=30, sd=40) |  |
| `SREGULIEREUREN` | statline-calibrated | NL | params: reguliereuren_mean (81431NED) |  |
| `SREISK` | random-normal |  | normal (mean=50, sd=80) |  |
| `SVAKBSL` | random-normal |  | normal (mean=200, sd=150) |  |
| `SVERGZVW` | random-normal |  | normal (mean=180, sd=120) |  |
| `SVERRARBKRT` | random-normal |  | normal (mean=10, sd=30) |  |
| `SVERSTRAANV` | random-normal |  | normal (mean=5, sd=20) |  |
| `SVOLTIJDDAGEN` | random-normal |  | normal (mean=22, sd=6) |  |
| `SWGBIJDRKO` | random-normal |  | normal (mean=0, sd=30) |  |
| `SWRDLN` | random-normal |  | normal (mean=100, sd=300) |  |
| `SWRDPRGEBRAUT` | random-normal |  | normal (mean=50, sd=200) |  |
| `SWRKNBIJDRAUT` | random-normal |  | normal (mean=10, sd=50) |  |
| `SCAO_crypt` | random-id |  | random hex, width=32 |  |
| `SCDAARD` | codelist-hardcoded |  | codelist: SCDAARD | [SCDAARD](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SCDAGH` | codelist-hardcoded |  | codelist: SCDAGH | [SCDAGH](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SCDINCINKVERM` | codelist-hardcoded |  | codelist: SCDINCINKVERM | [SCDINCINKVERM](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SCDINVLVPL1` | codelist-hardcoded |  | codelist: SCDINVLVPL | [SCDINVLVPL](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SCDINVLVPL2` | codelist-hardcoded |  | codelist: SCDINVLVPL | [SCDINVLVPL](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SCDINVLVPL3` | codelist-hardcoded |  | codelist: SCDINVLVPL | [SCDINVLVPL](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SCDRDNGNBIJT` | codelist-hardcoded |  | codelist: SCDRDNGNBIJT | [SCDRDNGNBIJT](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SCDZVW` | codelist-hardcoded |  | codelist: SCDZVW | [SCDZVW](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SCONTRACTSOORT` | codelist-hardcoded |  | codelist: SCONTRACTSOORT | [SCONTRACTSOORT](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SDATUMAANVANGIKVORG` | constant |  | template: {jan1} |  |
| `SFSINDFZ` | codelist-hardcoded |  | codelist: SFSINDFZ | [SFSINDFZ](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SINDLHKORT` | codelist-hardcoded |  | codelist: JN_INDICATOR | [JN_INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SINDSA03` | codelist-hardcoded |  | codelist: JN_INDICATOR | [JN_INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SINDSA43` | codelist-hardcoded |  | codelist: JN_INDICATOR | [JN_INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SINDSA71` | codelist-hardcoded |  | codelist: JN_INDICATOR | [JN_INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SINDSA72` | codelist-hardcoded |  | codelist: JN_INDICATOR | [JN_INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SINDVAKBN` | codelist-hardcoded |  | codelist: JN_INDICATOR | [JN_INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SINDZW` | codelist-hardcoded |  | codelist: JN_INDICATOR | [JN_INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SINLEGLEVENSLOOP` | codelist-hardcoded |  | codelist: JN_INDICATOR | [JN_INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SOVERWERK` | codelist-hardcoded |  | codelist: INDICATOR_01 | [INDICATOR_01](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SPOLISDIENSTVERBAND` | statline-calibrated | NL | params: dienstverband_p (81431NED) | [SPOLISDIENSTVERBAND](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SRISGRP` | codelist-hardcoded |  | codelist: SRISGRP | [SRISGRP](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SSRTIV` | codelist-hardcoded |  | codelist: SSRTIV | [SSRTIV](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SWEKARBDUURKLASSE` | statline-calibrated | NL | params: wekarbduur_p (81431NED) | [SWEKARBDUURKLASSE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SARBEIDSRELATIE` | codelist-hardcoded |  | codelist: SARBEIDSRELATIE | [SARBEIDSRELATIE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SAUTOVANDEZAAK` | codelist-hardcoded |  | codelist: SAUTOVANDEZAAK | [SAUTOVANDEZAAK](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SBEID` | random-id |  | random hex, width=8 |  |
| `SCAOSECTOR` | codelist-hardcoded |  | codelist: SCAOSECTOR | [SCAOSECTOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SDATUMAANVANGIKV` | constant |  | template: {jan1} |  |
| `SDATUMEINDEIKV` | constant |  | template: {dec31} |  |
| `SINDWAO` | codelist-hardcoded |  | codelist: JN_INDICATOR | [JN_INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SINDWW` | codelist-hardcoded |  | codelist: JN_INDICATOR | [JN_INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SLBTAB` | codelist-hardcoded |  | codelist: SLBTAB | [SLBTAB](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SLHNR_crypt` | random-id |  | random hex, width=32 |  |
| `SSECT` | statline-calibrated | NL | params: ssect_p (81431NED) | [SSECT](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SSOORTBAAN` | statline-calibrated | NL | params: soortbaan_p (81431NED) | [SSOORTBAAN](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `STIJDVAKTYPE` | codelist-hardcoded |  | codelist: STIJDVAKTYPE | [STIJDVAKTYPE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SPRWGAWHK` | random-normal |  | normal (mean=15, sd=25) |  |
| `SWGHZVW` | random-normal |  | normal (mean=180, sd=120) |  |
| `SPRGEDIFFWHK` | random-normal |  | normal (mean=10, sd=20) |  |
| `SINDTIJDHK` | codelist-hardcoded |  | codelist: INDICATOR_01 | [INDICATOR_01](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SIMPUTATIE` | codelist-hardcoded |  | codelist: INDICATOR_01 | [INDICATOR_01](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SINDPRKJONGRWEN` | codelist-hardcoded |  | codelist: INDICATOR_01 | [INDICATOR_01](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SINDPKAGH` | codelist-hardcoded |  | codelist: INDICATOR_01 | [INDICATOR_01](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SINDPKNWARBVOUDWN` | codelist-hardcoded |  | codelist: INDICATOR_01 | [INDICATOR_01](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SINDPMA` | codelist-hardcoded |  | codelist: INDICATOR_01 | [INDICATOR_01](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SCTRCTLN` | random-normal |  | normal (mean=2800, sd=1200) |  |
| `SAANTCTRCTURENPWK` | random-normal |  | normal (mean=32, sd=8) |  |
| `SBEDRRNTKSTVPERSL` | random-normal |  | normal (mean=0, sd=20) |  |
| `SINDWAARNEMING` | codelist-hardcoded |  | codelist: INDICATOR_01 | [INDICATOR_01](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SModelramingPensioenpremieWn` | random-normal |  | normal (mean=100, sd=80) |  |
| `SModelramingPensioenpremieWg` | random-normal |  | normal (mean=200, sd=150) |  |
| `SModelramingVutpremieWn` | random-normal |  | normal (mean=10, sd=30) |  |
| `SModelramingVutpremieWg` | random-normal |  | normal (mean=20, sd=50) |  |
| `SModelramingSFpremieWg` | random-normal |  | normal (mean=15, sd=40) |  |
| `SIndAvrLkvOudrWn` | codelist-hardcoded |  | codelist: INDICATOR_01 | [INDICATOR_01](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SIndAvrLkvAgWn` | codelist-hardcoded |  | codelist: INDICATOR_01 | [INDICATOR_01](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SIndAvrLkvDgBafSb` | codelist-hardcoded |  | codelist: INDICATOR_01 | [INDICATOR_01](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SIndAvrLkvHpAgWn` | codelist-hardcoded |  | codelist: INDICATOR_01 | [INDICATOR_01](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `CdRdnEindArbov` | codelist-hardcoded |  | codelist: CDRDNEINDARB | [CDRDNEINDARB](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `CdCaoInl_crypt` | random-id |  | random hex, width=32 |  |
| `IndArbovOnbepTd` | codelist-hardcoded |  | codelist: INDICATOR_01 | [INDICATOR_01](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `IndSchriftArbov` | codelist-hardcoded |  | codelist: INDICATOR_01 | [INDICATOR_01](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `IndOprov` | codelist-hardcoded |  | codelist: INDICATOR_01 | [INDICATOR_01](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `IndJrurennrm` | codelist-hardcoded |  | codelist: INDICATOR_01 | [INDICATOR_01](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `PRLNUFO` | random-normal |  | normal (mean=10, sd=25) |  |
| `PRLNAWFANWLg` | random-normal |  | normal (mean=30, sd=30) |  |
| `PRLNAWFANWHg` | random-normal |  | normal (mean=50, sd=40) |  |
| `PRLNAWFANWHz` | random-normal |  | normal (mean=0, sd=10) |  |
| `PrAwfLg` | random-normal |  | normal (mean=10, sd=15) |  |
| `PrAwfHg` | random-normal |  | normal (mean=15, sd=20) |  |
| `PrAwfHz` | random-normal |  | normal (mean=0, sd=5) |  |
| `INDPUBAANONBEPTD` | codelist-hardcoded |  | codelist: INDICATOR_01 | [INDICATOR_01](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `OPBAVWB` | random-normal |  | normal (mean=5, sd=15) |  |
| `OPNAVWB` | random-normal |  | normal (mean=5, sd=15) |  |
| `PRLNAOFANWHG` | random-normal |  | normal (mean=10, sd=20) |  |
| `PRLNAOFANWLG` | random-normal |  | normal (mean=5, sd=10) |  |
| `PRLNAOFANWUIT` | random-normal |  | normal (mean=0, sd=5) |  |
| `PRAOFHG` | random-normal |  | normal (mean=5, sd=10) |  |
| `PRAOFLG` | random-normal |  | normal (mean=3, sd=8) |  |
| `PRAOFUIT` | random-normal |  | normal (mean=0, sd=5) |  |
| `OPSLWKO` | random-normal |  | normal (mean=5, sd=15) |  |
| `PRLNWHKANW` | random-normal |  | normal (mean=10, sd=20) |  |
| `PRLNAWFANWUIT` | random-normal |  | normal (mean=0, sd=5) |  |
| `PRAWFUIT` | random-normal |  | normal (mean=0, sd=5) |  |
| `INDDEELNTIJDSPF` | codelist-hardcoded |  | codelist: INDICATOR_01 | [INDICATOR_01](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |

</details>

</details>

<details>
<summary><strong>Vermogens van huishoudens (VEHTAB)</strong> — 20 columns across 1 files (15 statline-calibrated)</summary>

<details>
<summary><code>VEH</code> — 20 columns (15 statline-calibrated)</summary>

| Column | Level | Spatial | Source | Codelist |
|--------|-------|---------|--------|----------|
| `RINPERSOONSHKW` | constant |  | value: R | [RINPERSOONSHKW](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/vehtab/codelists.yaml) |
| `RINPERSOONHKW` | spine-derived | NL | spine.hh.RINPERSOON_Ref |  |
| `VEHP100WELVAART` | spine-derived | NL | spine.hh.P100WELVAART |  |
| `VEHP100HVERM` | spine-derived | NL | spine.hh.P100HVERM |  |
| `VEHW1000VERH` | spine-derived | NL | spine.hh.VERMHH |  |
| `VEHW1100BEZH` | statline-calibrated | NL | params: bezh_mean (83834NED) |  |
| `VEHW1110FINH` | statline-calibrated | NL | params: finh_mean (83834NED) |  |
| `VEHW1111BANH` | statline-calibrated | NL | params: banh_mean (83834NED) |  |
| `VEHW1112EFFH` | statline-calibrated | NL | params: effh_mean (83834NED) |  |
| `VEHW1120ONRH` | statline-calibrated | NL | params: onrh_mean (83834NED) |  |
| `VEHW1121WONH` | statline-calibrated | NL | params: wonh_mean (83834NED) |  |
| `VEHW1122OGOH` | statline-calibrated | NL | params: ogoh_mean (83834NED) |  |
| `VEHW1130ONDH` | statline-calibrated | NL | params: ondh_mean (83834NED) |  |
| `VEHW1140ABEH` | statline-calibrated | NL | params: abeh_mean (83834NED) |  |
| `VEHW1150OVEH` | statline-calibrated | NL | params: oveh_mean (83834NED) |  |
| `VEHW1200STOH` | statline-calibrated | NL | params: stoh_mean (83834NED) |  |
| `VEHW1210SHYH` | statline-calibrated | NL | params: shyh_mean (83834NED) |  |
| `VEHW1220SSTH` | statline-calibrated | NL | params: ssth_mean (83834NED) |  |
| `VEHW1230SOVH` | statline-calibrated | NL | params: sovh_mean (83834NED) |  |
| `VEHWVEREXEWH` | statline-calibrated | NL | params: verexewh_mean (83834NED) |  |

</details>

</details>

<details>
<summary><strong>Energieverbruik particuliere woningen (ENERGIEVERBRUIKTAB)</strong> — 20 columns across 1 files (4 statline-calibrated)</summary>

<details>
<summary><code>ENERGIEVERBRUIK</code> — 20 columns (4 statline-calibrated)</summary>

| Column | Level | Spatial | Source | Codelist |
|--------|-------|---------|--------|----------|
| `SOORTOBJECTNUMMER` | spine-derived | gemeente | spine.obj.SOORTOBJECTNUMMER | [SOORTOBJECTNUMMER](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/energieverbruik/codelists.yaml) |
| `RINOBJECTNUMMER` | spine-derived | gemeente | spine.obj.RINOBJECTNUMMER |  |
| `WONINGT` | constant |  | value:   |  |
| `WOONR` | constant |  | value:   |  |
| `STADSW` | statline-calibrated | NL | params: stadsverwarming_categorical (Kerncijfers wijken en buurten) | [STADSW](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/energieverbruik/codelists.yaml) |
| `GAS` | statline-calibrated | NL | params: gas_mean (Kerncijfers wijken en buurten) |  |
| `ELEK` | statline-calibrated | NL | params: elek_mean (Kerncijfers wijken en buurten) |  |
| `GASBRON` | codelist-hardcoded |  | codelist: GASBRON | [GASBRON](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/energieverbruik/codelists.yaml) |
| `ELEKBRON` | codelist-hardcoded |  | codelist: ELEKBRON | [ELEKBRON](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/energieverbruik/codelists.yaml) |
| `ELEKTERUG` | random-normal |  | normal (mean=500, sd=1200) |  |
| `ELEKNETTO` | random-normal |  | normal (mean=2400, sd=1200) |  |
| `GASSJV` | random-normal |  | normal (mean=1100, sd=620) |  |
| `WARMTESCHATTING` | random-normal |  | normal (mean=35, sd=20) |  |
| `ZONPV` | statline-calibrated | NL | params: solar_pv_categorical (Kerncijfers wijken en buurten) | [ZONPV](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/energieverbruik/codelists.yaml) |
| `ZONVERMOGEN1JAN` | random-normal |  | normal (mean=2.5, sd=3) |  |
| `ZONVERMOGEN31DEC` | random-normal |  | normal (mean=2.8, sd=3.2) |  |
| `ZONPVBRON` | codelist-hardcoded |  | codelist: ZONPVBRON | [ZONPVBRON](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/energieverbruik/codelists.yaml) |
| `HOOFDVERWARMING31DEC` | codelist-hardcoded |  | codelist: HOOFDVERWARMING31DEC | [HOOFDVERWARMING31DEC](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/energieverbruik/codelists.yaml) |
| `WONINGBEWONING10PROFIELEN` | codelist-hardcoded |  | codelist: WONINGBEWONING10PROFIELEN | [WONINGBEWONING10PROFIELEN](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/energieverbruik/codelists.yaml) |
| `KBHOOFDVERWARMING31DEC` | codelist-hardcoded |  | codelist: KBHOOFDVERWARMING31DEC | [KBHOOFDVERWARMING31DEC](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/energieverbruik/codelists.yaml) |

</details>

</details>

<details>
<summary><strong>GBA Bevolkingsregister</strong> — 22 columns across 3 files (0 statline-calibrated)</summary>

<details>
<summary><code>GBAADRESOBJECTBUS</code> — 8 columns (0 statline-calibrated)</summary>

| Column | Level | Spatial | Source | Codelist |
|--------|-------|---------|--------|----------|
| `RINPERSOONS` | spine-derived | NL | spine.pers.RINPERSOONS | [rinpersoons](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/gba/codelists.yaml) |
| `RINPERSOON` | spine-derived | NL | spine.pers.RINPERSOON |  |
| `SOORTOBJECTNUMMER` | spine-derived | gemeente | spine.pers.SOORTOBJECTNUMMER | [soortobjectnummer](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/gba/codelists.yaml) |
| `RINOBJECTNUMMER` | spine-derived | gemeente | spine.pers.RINOBJECTNUMMER |  |
| `GBADATUMAANVANGADRESHOUDING` | spine-derived | NL | spine.pers.AanvangWoonduur |  |
| `GBADATUMEINDEADRESHOUDING` | constant |  | value: 99999999 |  |
| `GBAGEMEENTEVANINSCHRIJVING` | computed | gemeente | computed.GemeenteCodeJJJJ1Jan |  |
| `GBAAANTALINGESCHREVENENOPNUMMERAANDUIDING` | random-normal |  | normal (mean=2.2, sd=1.5) |  |

</details>

<details>
<summary><code>GBAHUISHOUDENSBUS</code> — 8 columns (0 statline-calibrated)</summary>

| Column | Level | Spatial | Source | Codelist |
|--------|-------|---------|--------|----------|
| `RINPERSOONS` | spine-derived | NL | spine.pers.RINPERSOONS | [rinpersoons](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/gba/codelists.yaml) |
| `RINPERSOON` | spine-derived | NL | spine.pers.RINPERSOON |  |
| `HUESSION` | spine-derived | NL | spine.pers.HUISHOUDNR |  |
| `DAESSION` | spine-derived | NL | spine.pers.DATUMAANVANGHH |  |
| `TYPHH` | spine-derived | NL | spine.pers.TYPHH | [typhh](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/gba/codelists.yaml) |
| `PLESSION` | spine-derived | NL | spine.pers.PLHH | [plhh](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/gba/codelists.yaml) |
| `AANESSION` | spine-derived | NL | spine.pers.AantalPersonenPerHuishouden |  |
| `REFESSION` | spine-derived | NL | spine.pers.REFPERSOONHH |  |

</details>

<details>
<summary><code>GBAPERSOONKTAB</code> — 6 columns (0 statline-calibrated)</summary>

| Column | Level | Spatial | Source | Codelist |
|--------|-------|---------|--------|----------|
| `RINPERSOONS` | spine-derived | NL | spine.pers.RINPERSOONS | [rinpersoons](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/gba/codelists.yaml) |
| `RINPERSOON` | spine-derived | NL | spine.pers.RINPERSOON |  |
| `GBAGESLACHT` | spine-derived | NL | spine.pers.GBAGeslachtsAanduiding | [geslacht](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/gba/codelists.yaml) |
| `GBAGEBOORTEJAAR` | spine-derived | NL | spine.pers.GBAGeboorteJaar |  |
| `GBAGEBOORTEMAAND` | random-uniform |  | uniform [1, 12] | [geboortemaand](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/gba/codelists.yaml) |
| `GBAGEBOORTEDAG` | constant |  | value: 01 |  |

</details>

</details>

