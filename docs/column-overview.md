# Column Overview

Overview of all simulated columns

## GBA Bevolkingsregister

<details>
<summary><code>GBAPERSOONKTAB</code></summary>

| Column | Source | Spatial | Calibration | Codelist |
|--------|--------|---------|-------------|----------|
| `RINPERSOONS` | spine-derived | NL |  | [rinpersoons](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/gba/codelists.yaml) |
| `RINPERSOON` | spine-derived | NL |  |  |
| `GBAGESLACHT` | spine-derived | NL |  | [geslacht](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/gba/codelists.yaml) |
| `GBAGEBOORTEJAAR` | spine-derived | NL |  |  |
| `GBAGEBOORTEMAAND` | random: uniform [1, 12] |  |  | [geboortemaand](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/gba/codelists.yaml) |
| `GBAGEBOORTEDAG` | value: 01 |  |  |  |

</details>

<details>
<summary><code>GBAADRESOBJECTBUS</code></summary>

| Column | Source | Spatial | Calibration | Codelist |
|--------|--------|---------|-------------|----------|
| `RINPERSOONS` | spine-derived | NL |  | [rinpersoons](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/gba/codelists.yaml) |
| `RINPERSOON` | spine-derived | NL |  |  |
| `SOORTOBJECTNUMMER` | spine-derived | gemeente |  | [soortobjectnummer](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/gba/codelists.yaml) |
| `RINOBJECTNUMMER` | spine-derived | gemeente |  |  |
| `GBADATUMAANVANGADRESHOUDING` | spine-derived | NL |  |  |
| `GBADATUMEINDEADRESHOUDING` | value: 99999999 |  |  |  |
| `GBAGEMEENTEVANINSCHRIJVING` | computed | gemeente |  |  |
| `GBAAANTALINGESCHREVENENOPNUMMERAANDUIDING` | random: normal (mean=2.2, sd=1.5) |  |  |  |

</details>

<details>
<summary><code>GBAHUISHOUDENSBUS</code></summary>

| Column | Source | Spatial | Calibration | Codelist |
|--------|--------|---------|-------------|----------|
| `RINPERSOONS` | spine-derived | NL |  | [rinpersoons](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/gba/codelists.yaml) |
| `RINPERSOON` | spine-derived | NL |  |  |
| `HUESSION` | spine-derived | NL |  |  |
| `DAESSION` | spine-derived | NL |  |  |
| `TYPHH` | spine-derived | NL |  | [typhh](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/gba/codelists.yaml) |
| `PLESSION` | spine-derived | NL |  | [plhh](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/gba/codelists.yaml) |
| `AANESSION` | spine-derived | NL |  |  |
| `REFESSION` | spine-derived | NL |  |  |

</details>

## CBS Woonbase

<details>
<summary><code>WoonbaseSleutelbestand</code></summary>

| Column | Source | Spatial | Calibration | Codelist |
|--------|--------|---------|-------------|----------|
| `RINPERSOONS` | spine-derived | NL |  |  |
| `RINPERSOON` | spine-derived | NL |  |  |
| `REFPERSOONHH` | spine-derived | NL |  | [REFPERSOONHH](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `PLHH` | spine-derived | NL |  | [PLHH](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `HUISHOUDNR` | spine-derived | NL |  |  |
| `DATUMAANVANGHH` | spine-derived | NL |  |  |
| `TYPHH` | spine-derived | NL |  | [TYPHH](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `IMPUTATIECODEHH` | spine-derived | NL |  | [IMPUTATIECODEHH](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `SOORTOBJECTNUMMER` | spine-derived | gemeente |  |  |
| `RINOBJECTNUMMER` | spine-derived | gemeente |  |  |
| `INVOORRAAD` | value: 1 |  |  | [INVOORRAAD](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `VBOVOORRAADTYPE` | value: 0 |  |  | [VBOVOORRAADTYPE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `BEGINGELDIGHEID` | template: {jan1} |  |  |  |
| `EINDGELDIGHEID` | template: {dec31} |  |  |  |
| `REDENBEGINGELDIGHEID` | random: hardcoded probs |  |  |  |
| `REDENEINDGELDIGHEID` | value: NVT |  |  |  |

</details>

<details>
<summary><code>WoonbaseKenmerkenPersonen</code></summary>

| Column | Source | Spatial | Calibration | Codelist |
|--------|--------|---------|-------------|----------|
| `RINPERSOON` | spine-derived | NL |  |  |
| `RINPERSOONS` | spine-derived | NL |  |  |
| `GBABurgerlijkeStaat1Jan, GBABurgerlijkeStaat31Dec` | spine-derived | NL |  |  |
| `GBAGeboorteJaar1Jan, GBAGeboorteJaar31Dec` | spine-derived | NL |  |  |
| `GBAGeslachtsAanduiding1Jan, GBAGeslachtsAanduiding31Dec` | spine-derived | NL |  | [GESLACHT](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `GEMEENTECODEJJJJ1Jan, GEMEENTECODEJJJJ31Dec` | spine-derived | gemeente |  |  |
| `WIJKCODEJJJJ1Jan, WIJKCODEJJJJ31Dec` | spine-derived | gemeente |  |  |
| `BUURTCODEJJJJ1Jan, BUURTCODEJJJJ31Dec` | spine-derived | gemeente |  |  |
| `PLHH1Jan, PLHH31Dec` | spine-derived | NL |  | [PLHH](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `RINOBJECTNUMMER1Jan, RINOBJECTNUMMER31Dec` | spine-derived | gemeente |  |  |
| `SOORTOBJECTNUMMER1Jan, SOORTOBJECTNUMMER31Dec` | spine-derived | gemeente |  |  |
| `AanvangWoonduur1Jan, AanvangWoonduur31Dec` | spine-derived | NL |  |  |
| `OPLNIVSOI2016AGG4HBMETNIRWO1Jan, OPLNIVSOI2016AGG4HBMETNIRWO31Dec` | random: hardcoded probs |  |  |  |
| `OPLNIVSOI2016AGG4HGMETNIRWO1Jan, OPLNIVSOI2016AGG4HGMETNIRWO31Dec` | random: hardcoded probs |  |  |  |
| `OPLNIVSOI2021AGG4HBMETNIRWO1Jan, OPLNIVSOI2021AGG4HBMETNIRWO31Dec` | random: hardcoded probs |  |  |  |
| `OPLNIVSOI2021AGG4HGMETNIRWO1Jan, OPLNIVSOI2021AGG4HGMETNIRWO31Dec` | random: hardcoded probs |  |  |  |
| `GEWICHTHOOGSTEOPL1Jan, GEWICHTHOOGSTEOPL31Dec` | random: uniform [0.5, 1.5] |  |  |  |

</details>

<details>
<summary><code>WoonbaseKenmerkenHuishoudens</code></summary>

| Column | Source | Spatial | Calibration | Codelist |
|--------|--------|---------|-------------|----------|
| `HUISHOUDNR1Jan, HUISHOUDNR31Dec` | spine-derived | NL |  |  |
| `DatumAanvangHH1Jan, DatumAanvangHH31Dec` | spine-derived | NL |  |  |
| `IMPUTATIECODEHH1Jan, IMPUTATIECODEHH31Dec` | spine-derived | NL |  | [IMPUTATIECODEHH](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `RefPersoonHH1Jan, RefPersoonHH31Dec` | spine-derived | NL |  | [REFPERSOONHH](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `RINPERSOON` | spine-derived | NL |  |  |
| `RINPERSOONS` | spine-derived | NL |  |  |
| `TYPHH1Jan, TYPHH31Dec` | spine-derived | NL |  | [TYPHH](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `AantalKinderenPerHuishouden1Jan, AantalKinderenPerHuishouden31Dec` | spine-derived | NL |  |  |
| `AantalPersonenPerHuishouden1Jan, AantalPersonenPerHuishouden31Dec` | spine-derived | NL |  |  |

</details>

<details>
<summary><code>WoonbaseKenmerkenWoonruimten</code></summary>

| Column | Source | Spatial | Calibration | Codelist |
|--------|--------|---------|-------------|----------|
| `RINOBJECTNUMMER` | spine-derived | gemeente |  |  |
| `SOORTOBJECTNUMMER` | spine-derived | gemeente |  |  |
| `GEMEENTECODEJJJJ1Jan, GEMEENTECODEJJJJ31Dec` | spine-derived | gemeente |  |  |
| `WIJKCODEJJJJ1Jan, WIJKCODEJJJJ31Dec` | spine-derived | gemeente |  |  |
| `BUURTCODEJJJJ1Jan, BUURTCODEJJJJ31Dec` | spine-derived | gemeente |  |  |
| `Indicator_VBOIsNieuwbouw` | spine-derived | NL |  | [INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `Indicator_VBOIsNieuwbouwJJJJ-1` | spine-derived | NL |  | [INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `VSLSoort1Jan, VSLSoort31Dec` | spine-derived | NL |  | [VSLSOORT](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `VBOWoningType1Jan, VBOWoningType31Dec` | spine-derived | NL |  | [WONINGTYPE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `VBOBouwjaar1Jan, VBOBouwjaar31Dec` | spine-derived | NL |  |  |
| `VBOOppervlakte1Jan, VBOOppervlakte31Dec` | spine-derived | NL |  |  |
| `WOZWaardeObjectBAG1Jan, WOZWaardeObjectBAG31Dec` | spine-derived | gemeente |  |  |
| `VBOStatus1Jan, VBOStatus31Dec` | spine-derived | NL |  | [VBOSTATUS](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |

</details>

<details>
<summary><code>WoonbasePopulatiePersonen</code></summary>

| Column | Source | Spatial | Calibration | Codelist |
|--------|--------|---------|-------------|----------|
| `RINPERSOON` | spine-derived | NL |  |  |
| `RINPERSOONS` | spine-derived | NL |  |  |
| `RefPersoonHH1Jan, RefPersoonHH31Dec` | spine-derived | NL |  | [REFPERSOONHH](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `HUISHOUDNR1Jan, HUISHOUDNR31Dec` | spine-derived | NL |  |  |
| `DATUMAANVANGHH1Jan, DATUMAANVANGHH31Dec` | spine-derived | NL |  |  |
| `IMPUTATIECODEHH1Jan, IMPUTATIECODEHH31Dec` | spine-derived | NL |  | [IMPUTATIECODEHH](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `RINOBJECTNUMMER1Jan, RINOBJECTNUMMER31Dec` | spine-derived | gemeente |  |  |
| `SOORTOBJECTNUMMER1Jan, SOORTOBJECTNUMMER31Dec` | spine-derived | gemeente |  |  |
| `Indicator_PersoonIsGeboren` | spine-derived | NL |  | [INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `Indicator_PersoonIsOverleden` | spine-derived | NL |  | [INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `Indicator_PersoonIsGeemigreerd` | spine-derived | NL |  | [INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `Indicator_PersoonIsAdministratiefAfgevoerd` | spine-derived | NL |  | [INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `Indicator_PersoonIsGeimmigreerd` | spine-derived | NL |  | [INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `Indicator_PersoonIsAdministratiefOpgenomen` | spine-derived | NL |  | [INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `Indicator_PersoonIsVerhuisd` | spine-derived | NL |  | [INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `Indicator_PersoonIsAanwezig1Jan` | spine-derived | NL |  | [INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `Indicator_PersoonIsAanwezig31Dec` | spine-derived | NL |  | [INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `AantalKeerVerhuisd` | spine-derived | NL |  |  |
| `PLHH1Jan, PLHH31Dec` | spine-derived | NL |  | [PLHH](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `TYPHH1Jan, TYPHH31Dec` | spine-derived | NL |  | [TYPHH](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `GBAGeslachtsAanduiding1Jan, GBAGeslachtsAanduiding31Dec` | spine-derived | NL |  | [GESLACHT](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `GBAGeboorteJaar1Jan, GBAGeboorteJaar31Dec` | spine-derived | NL |  |  |
| `GBABurgerlijkeStaat1Jan, GBABurgerlijkeStaat31Dec` | spine-derived | NL |  |  |
| `AantalPersonenPerHuishouden1Jan, AantalPersonenPerHuishouden31Dec` | spine-derived | NL |  |  |
| `GemeenteCodeJJJJ1Jan, GemeenteCodeJJJJ31Dec` | spine-derived | gemeente |  |  |
| `VSLSoort1Jan, VSLSoort31Dec` | spine-derived | NL |  | [VSLSOORT](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `TypeEigenaar1Jan, TypeEigenaar31Dec` | spine-derived | NL |  | [TYPEIGENAAR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `VBOWoningType1Jan, VBOWoningType31Dec` | spine-derived | NL |  | [WONINGTYPE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `VBOBouwJaarKlasse1Jan, VBOBouwJaarKlasse31Dec` | spine-derived | NL |  | [BOUWJAARKLASSE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `VBOOppervlakteKlasse1Jan, VBOOppervlakteKlasse31Dec` | spine-derived | NL |  | [OPPKLASSE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `WOZWaardeObjectBAGKlasse1Jan, WOZWaardeObjectBAGKlasse31Dec` | spine-derived | gemeente |  | [WOZKLASSE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |

</details>

<details>
<summary><code>WoonbasePopulatieHuishoudens</code></summary>

| Column | Source | Spatial | Calibration | Codelist |
|--------|--------|---------|-------------|----------|
| `HUISHOUDNR1Jan, HUISHOUDNR31Dec` | spine-derived | NL |  |  |
| `DATUMAANVANGHH1Jan, DATUMAANVANGHH31Dec` | spine-derived | NL |  |  |
| `IMPUTATIECODEHH1Jan, IMPUTATIECODEHH31Dec` | spine-derived | NL |  | [IMPUTATIECODEHH](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `RINPERSOONS` | spine-derived | NL |  |  |
| `RINPERSOON` | spine-derived | NL |  |  |
| `RINOBJECTNUMMER1Jan, RINOBJECTNUMMER31Dec` | spine-derived | gemeente |  |  |
| `SOORTOBJECTNUMMER1Jan, SOORTOBJECTNUMMER31Dec` | spine-derived | gemeente |  |  |
| `TYPHH1Jan, TYPHH31Dec` | spine-derived | NL |  | [TYPHH](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `AantalPersonenPerHuishouden1Jan, AantalPersonenPerHuishouden31Dec` | spine-derived | NL |  |  |
| `AantalKinderenPerHuishouden1Jan, AantalKinderenPerHuishouden31Dec` | spine-derived | NL |  |  |
| `LeeftijdRefPersoon1Jan, LeeftijdRefPersoon31Dec` | spine-derived | NL |  |  |
| `PLHHRefPersoon1Jan, PLHHRefPersoon31Dec` | spine-derived | NL |  | [PLHH](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `GBAGeslachtsaanduidingRefPersoon1Jan, GBAGeslachtsaanduidingRefPersoon31Dec` | spine-derived | NL |  | [GESLACHT](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `GemeenteCodeJJJJ1Jan, GemeenteCodeJJJJ31Dec` | spine-derived | gemeente |  |  |
| `VSLSoort1Jan, VSLSoort31Dec` | spine-derived | NL |  | [VSLSOORT](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `WOZWaardeObjectBAGKlasse1Jan, WOZWaardeObjectBAGKlasse31Dec` | spine-derived | gemeente |  | [WOZKLASSE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `VBOBouwJaarKlasse1Jan, VBOBouwJaarKlasse31Dec` | spine-derived | NL |  | [BOUWJAARKLASSE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `VBOOppervlakteKlasse1Jan, VBOOppervlakteKlasse31Dec` | spine-derived | NL |  | [OPPKLASSE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `VBOWoningType1Jan, VBOWoningType31Dec` | spine-derived | NL |  | [WONINGTYPE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `TypeEigenaar1Jan, TypeEigenaar31Dec` | spine-derived | NL |  | [TYPEIGENAAR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `Indicator_HHIsAanwezig1Jan, Indicator_HHIsAanwezig31Dec` | value: 1 |  |  | [INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |

</details>

<details>
<summary><code>WoonbasePopulatieWoonruimten</code></summary>

| Column | Source | Spatial | Calibration | Codelist |
|--------|--------|---------|-------------|----------|
| `SOORTOBJECTNUMMER` | spine-derived | gemeente |  |  |
| `RINOBJECTNUMMER` | spine-derived | gemeente |  |  |
| `PandID1Jan, PandID31Dec` | spine-derived | NL |  |  |
| `VSLSoort1Jan, VSLSoort31Dec` | spine-derived | NL |  | [VSLSOORT](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `HUISHOUDNR1Jan, HUISHOUDNR31Dec` | spine-derived | NL |  |  |
| `DATUMAANVANGHH{sfx_lower}` | spine-derived | NL |  |  |
| `RINPERSOONS_Ref{sfx_lower}` | spine-derived | NL |  |  |
| `RINPERSOON_Ref{sfx_lower}` | spine-derived | NL |  |  |
| `VBOWoningType1Jan, VBOWoningType31Dec` | spine-derived | NL |  | [WONINGTYPE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `VBOBouwJaarKlasse1Jan, VBOBouwJaarKlasse31Dec` | spine-derived | NL |  | [BOUWJAARKLASSE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `VBOOppervlakteKlasse1Jan, VBOOppervlakteKlasse31Dec` | spine-derived | NL |  | [OPPKLASSE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `WOZWaardeObjectBAGKlasse1Jan, WOZWaardeObjectBAGKlasse31Dec` | spine-derived | gemeente |  | [WOZKLASSE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `TypeEigenaar1Jan, TypeEigenaar31Dec` | spine-derived | NL |  | [TYPEIGENAAR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `AantalPersonenPerVSLKlasse1Jan, AantalPersonenPerVSLKlasse31Dec` | computed |  |  | [PERSKLASSE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `AantalHuishoudensPerVSLKlasse1Jan, AantalHuishoudensPerVSLKlasse31Dec` | value: 1 |  |  | [HHKLASSE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `AantalKinderenPerVSL1Jan, AantalKinderenPerVSL31Dec` | spine-derived | NL |  |  |
| `LeeftijdJongsteKindPerVSL1Jan, LeeftijdJongsteKindPerVSL31Dec` | spine-derived | NL |  |  |
| `TYPHH1Jan, TYPHH31Dec` | spine-derived | NL |  | [TYPHH](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `GemeenteCodeJJJJ1Jan, GemeenteCodeJJJJ31Dec` | spine-derived | gemeente |  |  |
| `Indicator_VBOIsAanwezig1Jan, Indicator_VBOIsAanwezig31Dec` | spine-derived | NL |  | [INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `Indicator_VSLIsAanwezig1Jan, Indicator_VSLIsAanwezig31Dec` | spine-derived | NL |  | [INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `Indicator_VBOIsGesloopt` | spine-derived | NL |  | [INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `Indicator_VSLIsOntrokken` | spine-derived | NL |  | [INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `Indicator_VBOIsTransformatie` | spine-derived | NL |  | [INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `Indicator_VBOIsNieuwbouw` | spine-derived | NL |  | [INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `Indicator_VSLIsNieuw` | spine-derived | NL |  | [INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |

</details>

<details>
<summary><code>WOONBASEEKHuishoudensWV</code></summary>

| Column | Source | Spatial | Calibration | Codelist |
|--------|--------|---------|-------------|----------|
| `RINPERSOONS` | spine-derived | NL |  |  |
| `RINPERSOON` | spine-derived | NL |  |  |
| `AGHT1JAN, AGHT31DEC` | random: codelist: AGHT |  |  | [AGHT](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `AGIAH1JAN, AGIAH31DEC` | random: codelist: AGIAH |  |  | [AGIAH](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `AGTSH1JAN, AGTSH31DEC` | random: codelist: AGTSH |  |  | [AGTSH](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `AOWHT1JAN, AOWHT31DEC` | random: codelist: AOWHT |  |  | [AOWHT](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `ARMOEDE1JAN, ARMOEDE31DEC` | random: uniform [50, 500] |  |  |  |
| `ARMSOC1JAN, ARMSOC31DEC` | random: uniform [50, 500] |  |  |  |
| `BBIHJ1JAN, BBIHJ31DEC` | random: uniform [1, 20] |  |  |  |
| `BELIAGHT1JAN, BELIAGHT31DEC` | random: uniform [5000, 80000] |  |  |  |
| `BELIAGIAH1JAN, BELIAGIAH31DEC` | random: uniform [5000, 80000] |  |  |  |
| `BELIAGTSH1JAN, BELIAGTSH31DEC` | random: uniform [5000, 80000] |  |  |  |
| `BELIH1JAN, BELIH31DEC` | spine-derived | NL |  |  |
| `BESTINKH1JAN, BESTINKH31DEC` | spine-derived | NL |  |  |
| `BETAALBUDGET1JAN, BETAALBUDGET31DEC` | random: uniform [-10000, 60000] |  |  |  |
| `BETAALRESERVE1JAN, BETAALRESERVE31DEC` | random: uniform [-5000, 50000] |  |  |  |
| `CORBETAALBUDGET1JAN, CORBETAALBUDGET31DEC` | random: hardcoded probs |  |  |  |
| `EHALGR1JAN, EHALGR31DEC` | random: uniform [1, 30] |  |  |  |
| `GESTINKH1JAN, GESTINKH31DEC` | spine-derived | NL |  |  |
| `LEERGROND1JAN, LEERGROND31DEC` | random: uniform [0, 50000] |  |  |  |
| `P100HBEST1JAN, P100HBEST31DEC` | spine-derived | NL |  |  |
| `P100HGEST1JAN, P100HGEST31DEC` | spine-derived | NL |  |  |
| `P100HVERM1JAN, P100HVERM31DEC` | spine-derived | NL |  |  |
| `P100WELVAART1JAN, P100WELVAART31DEC` | spine-derived | NL |  |  |
| `POPFEC1JAN, POPFEC31DEC` | random: codelist: POPFEC |  |  | [POPFEC](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `POPIIV1JAN, POPIIV31DEC` | random: codelist: POPIIV |  |  | [POPIIV](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `POPIIVWONING1JAN, POPIIVWONING31DEC` | random: uniform [0, 10] |  |  |  |
| `VERMHH1JAN, VERMHH31DEC` | spine-derived | NL |  |  |
| `VROMHH1JAN, VROMHH31DEC` | spine-derived | NL |  |  |
| `W1000VERH1JAN, W1000VERH31DEC` | random: uniform [0, 500000] |  |  |  |
| `VERSCHILIIV1JAN, VERSCHILIIV31DEC` | random: codelist: VERSCHILIIV |  |  | [VERSCHILIIV](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |

</details>

<details>
<summary><code>ExtraKenmerkenPandenTAB</code></summary>

| Column | Source | Spatial | Calibration | Codelist |
|--------|--------|---------|-------------|----------|
| `PandID` | spine-derived | NL |  |  |
| `PandAantalVbos1Jan, PandAantalVbos31Dec` | random: uniform [1, 20] |  |  |  |
| `PandAantalWoning1Jan, PandAantalWoning31Dec` | random: uniform [0, 15] |  |  |  |
| `PandAantalNietWoning1Jan, PandAantalNietWoning31Dec` | random: uniform [0, 5] |  |  |  |
| `PandOppTotWoning1Jan, PandOppTotWoning31Dec` | random: uniform [0, 5000] |  |  |  |
| `PandOppTotNietWoning1Jan, PandOppTotNietWoning31Dec` | random: uniform [0, 3000] |  |  |  |
| `PandOppGemWoning1Jan, PandOppGemWoning31Dec` | random: uniform [30, 250] |  |  |  |
| `PandOppGemNietWoning1Jan, PandOppGemNietWoning31Dec` | random: uniform [30, 500] |  |  |  |
| `PandWinkelfunctie1Jan, PandWinkelfunctie31Dec` | random: codelist: PANDFUNCTIE |  |  | [PANDFUNCTIE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `PandKantoorfunctie1Jan, PandKantoorfunctie31Dec` | random: codelist: PANDFUNCTIE |  |  | [PANDFUNCTIE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `PandIndustriefunctie1Jan, PandIndustriefunctie31Dec` | random: codelist: PANDFUNCTIE |  |  | [PANDFUNCTIE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `PandBijeenkomstfunctie1Jan, PandBijeenkomstfunctie31Dec` | random: codelist: PANDFUNCTIE |  |  | [PANDFUNCTIE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `PandGezondheidszorgfunctie1Jan, PandGezondheidszorgfunctie31Dec` | random: codelist: PANDFUNCTIE |  |  | [PANDFUNCTIE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `PandAnderefunctie1Jan, PandAnderefunctie31Dec` | random: codelist: PANDFUNCTIE |  |  | [PANDFUNCTIE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `PandTransformatie1Jan, PandTransformatie31Dec` | random: codelist: PANDTRANSFORMATIE |  |  | [PANDTRANSFORMATIE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |
| `PandHoogte` | random: uniform [3, 60] |  |  |  |
| `PandAantalVerdiepingen` | random: uniform [1, 15] |  |  |  |
| `PandDaktype` | random: codelist: PANDDAKTYPE |  |  | [PANDDAKTYPE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/woonbase/codelists.yaml) |

</details>

## RDW Motorvoertuigenpark

<details>
<summary><code>RDWNPACTTAB</code></summary>

| Column | Source | Spatial | Calibration | Codelist |
|--------|--------|---------|-------------|----------|
| `RINPERSOONS` | random: codelist: RINPERSOONS_RDW |  |  | [RINPERSOONS_RDW](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/rdw/codelists.yaml) |
| `RINPERSOON` | spine-derived | NL |  |  |
| `RINKENTEKEN` | spine-derived | NL |  |  |
| `KLEURCODEVRTG` | params: kleur_p | NL | [85237NED](https://opendata.cbs.nl/statline/#/CBS/nl/dataset/85237NED), [85236NED](https://opendata.cbs.nl/statline/#/CBS/nl/dataset/85236NED), [85404NED](https://opendata.cbs.nl/statline/#/CBS/nl/dataset/85404NED) | [KLEURCODE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/rdw/codelists.yaml) |
| `EERSTETOELDAT1VRTG` | params: bouwjaar_p | NL | [85237NED](https://opendata.cbs.nl/statline/#/CBS/nl/dataset/85237NED), [85236NED](https://opendata.cbs.nl/statline/#/CBS/nl/dataset/85236NED), [85404NED](https://opendata.cbs.nl/statline/#/CBS/nl/dataset/85404NED) |  |
| `SRTREFVRTG` | random: codelist: SRTREF |  |  | [SRTREF](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/rdw/codelists.yaml) |
| `VRTGSOORT` | params: vrtgsoort_p | NL | [85237NED](https://opendata.cbs.nl/statline/#/CBS/nl/dataset/85237NED), [85236NED](https://opendata.cbs.nl/statline/#/CBS/nl/dataset/85236NED), [85404NED](https://opendata.cbs.nl/statline/#/CBS/nl/dataset/85404NED) | [VRTGSOORT](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/rdw/codelists.yaml) |
| `BRANDSTCODECORVRTG` | params: brandstof_p | NL | [85237NED](https://opendata.cbs.nl/statline/#/CBS/nl/dataset/85237NED), [85236NED](https://opendata.cbs.nl/statline/#/CBS/nl/dataset/85236NED), [85404NED](https://opendata.cbs.nl/statline/#/CBS/nl/dataset/85404NED) | [BRANDSTOF](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/rdw/codelists.yaml) |
| `MASSALEEGCORVRTG` | params: gewicht_mean | NL | [85237NED](https://opendata.cbs.nl/statline/#/CBS/nl/dataset/85237NED), [85236NED](https://opendata.cbs.nl/statline/#/CBS/nl/dataset/85236NED), [85404NED](https://opendata.cbs.nl/statline/#/CBS/nl/dataset/85404NED) |  |
| `MAXLAADVERMCORVRTG` | random: uniform [0, 3000] |  |  |  |
| `AANTALCYLCORVRTG` | random: hardcoded probs |  |  |  |
| `CYLININHOUDCORVRTG` | random: normal (mean=1600, sd=600) |  |  |  |
| `SOORTBROMFIETSCOR` | random: codelist: SOORTBROMFIETS |  |  | [SOORTBROMFIETS](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/rdw/codelists.yaml) |

</details>

<details>
<summary><code>VERKEERSPRESTATIETAB</code></summary>

| Column | Source | Spatial | Calibration | Codelist |
|--------|--------|---------|-------------|----------|
| `RINKENTEKEN` | spine-derived | NL |  |  |
| `RinpersoonsVP` | random: codelist: RINPERSOONS_RDW |  |  | [RINPERSOONS_RDW](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/rdw/codelists.yaml) |
| `RinpersoonVP` | spine-derived | NL |  |  |
| `VPGEWICHT` | random: hardcoded probs |  |  |  |
| `VPDGNWEG` | random: hardcoded probs |  |  |  |
| `VPJAARKM` | params: jaarkm_mean | NL | [85237NED](https://opendata.cbs.nl/statline/#/CBS/nl/dataset/85237NED), [85236NED](https://opendata.cbs.nl/statline/#/CBS/nl/dataset/85236NED), [85404NED](https://opendata.cbs.nl/statline/#/CBS/nl/dataset/85404NED) |  |

</details>

## Banen en lonen

<details>
<summary><code>SPOLISBUS</code></summary>

| Column | Source | Spatial | Calibration | Codelist |
|--------|--------|---------|-------------|----------|
| `RINPERSOONS` | random: codelist: RINPERSOONS_SPOLIS |  |  | [RINPERSOONS_SPOLIS](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `RINPERSOON` | spine-derived | NL |  |  |
| `IKVID` | spine-derived | NL |  |  |
| `SDATUMAANVANGIKO` | spine-derived | NL |  |  |
| `SDATUMEINDEIKO` | spine-derived | NL |  |  |
| `SAANTSV` | random: normal (mean=18, sd=6) |  |  |  |
| `SAANTVERLU` | random: normal (mean=130, sd=40) |  |  |  |
| `SAUTOZAAK` | params: autozaak_mean | NL | [81431NED](https://opendata.cbs.nl/statline/#/CBS/nl/dataset/81431NED) |  |
| `SBAANDAGEN` | random: hardcoded probs |  |  |  |
| `SBASISLOON` | params: basisloon_mean | NL | [81431NED](https://opendata.cbs.nl/statline/#/CBS/nl/dataset/81431NED) |  |
| `SBASISUREN` | params: basisuren_mean | NL | [81431NED](https://opendata.cbs.nl/statline/#/CBS/nl/dataset/81431NED) |  |
| `SBEDRALINWWB` | random: normal (mean=0, sd=50) |  |  |  |
| `SBEDRRCHTAL` | random: normal (mean=0, sd=20) |  |  |  |
| `SBEDRZDAFTR` | random: normal (mean=0, sd=10) |  |  |  |
| `SBIJDRZVW` | random: normal (mean=180, sd=100) |  |  |  |
| `SBIJZONDEREBELONING` | params: bijzbeloning_mean | NL | [81431NED](https://opendata.cbs.nl/statline/#/CBS/nl/dataset/81431NED) |  |
| `SEXTRSAL` | random: normal (mean=50, sd=200) |  |  |  |
| `SINCIDENTSAL` | random: normal (mean=20, sd=100) |  |  |  |
| `SINGLBPH` | random: normal (mean=100, sd=200) |  |  |  |
| `SLNINGLD` | params: loon_mean | NL | [81431NED](https://opendata.cbs.nl/statline/#/CBS/nl/dataset/81431NED) |  |
| `SLNLBPH` | params: lnlbph_mean | NL | [81431NED](https://opendata.cbs.nl/statline/#/CBS/nl/dataset/81431NED) |  |
| `SLNOWRK` | random: normal (mean=50, sd=200) |  |  |  |
| `SLNSV` | params: lnsv_mean | NL | [81431NED](https://opendata.cbs.nl/statline/#/CBS/nl/dataset/81431NED) |  |
| `SLNTABBB` | random: normal (mean=0, sd=50) |  |  |  |
| `SLVLPREG` | random: normal (mean=0, sd=50) |  |  |  |
| `SLVLPREGTOEG` | random: normal (mean=0, sd=50) |  |  |  |
| `SOPGRCHTEXTRSAL` | random: normal (mean=0, sd=100) |  |  |  |
| `SOPGRCHTVAKBSL` | random: normal (mean=0, sd=50) |  |  |  |
| `SOVERWERKUREN` | random: normal (mean=3, sd=8) |  |  |  |
| `SPENSIOENPREMIE` | random: normal (mean=250, sd=200) |  |  |  |
| `SPRAWF` | random: normal (mean=90, sd=60) |  |  |  |
| `SPRUFO` | random: normal (mean=15, sd=30) |  |  |  |
| `SPRWAOAOF` | random: normal (mean=20, sd=30) |  |  |  |
| `SPRWAOAOK` | random: normal (mean=15, sd=25) |  |  |  |
| `SPRWGF` | random: normal (mean=30, sd=40) |  |  |  |
| `SREGULIEREUREN` | params: reguliereuren_mean | NL | [81431NED](https://opendata.cbs.nl/statline/#/CBS/nl/dataset/81431NED) |  |
| `SREISK` | random: normal (mean=50, sd=80) |  |  |  |
| `SVAKBSL` | random: normal (mean=200, sd=150) |  |  |  |
| `SVERGZVW` | random: normal (mean=180, sd=120) |  |  |  |
| `SVERRARBKRT` | random: normal (mean=10, sd=30) |  |  |  |
| `SVERSTRAANV` | random: normal (mean=5, sd=20) |  |  |  |
| `SVOLTIJDDAGEN` | random: normal (mean=22, sd=6) |  |  |  |
| `SWGBIJDRKO` | random: normal (mean=0, sd=30) |  |  |  |
| `SWRDLN` | random: normal (mean=100, sd=300) |  |  |  |
| `SWRDPRGEBRAUT` | random: normal (mean=50, sd=200) |  |  |  |
| `SWRKNBIJDRAUT` | random: normal (mean=10, sd=50) |  |  |  |
| `SCAO_crypt` | random hex, width=32 |  |  |  |
| `SCDAARD` | random: codelist: SCDAARD |  |  | [SCDAARD](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SCDAGH` | random: codelist: SCDAGH |  |  | [SCDAGH](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SCDINCINKVERM` | random: codelist: SCDINCINKVERM |  |  | [SCDINCINKVERM](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SCDINVLVPL1` | random: codelist: SCDINVLVPL |  |  | [SCDINVLVPL](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SCDINVLVPL2` | random: codelist: SCDINVLVPL |  |  | [SCDINVLVPL](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SCDINVLVPL3` | random: codelist: SCDINVLVPL |  |  | [SCDINVLVPL](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SCDRDNGNBIJT` | random: codelist: SCDRDNGNBIJT |  |  | [SCDRDNGNBIJT](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SCDZVW` | random: codelist: SCDZVW |  |  | [SCDZVW](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SCONTRACTSOORT` | random: codelist: SCONTRACTSOORT |  |  | [SCONTRACTSOORT](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SDATUMAANVANGIKVORG` | spine-derived | NL |  |  |
| `SFSINDFZ` | random: codelist: SFSINDFZ |  |  | [SFSINDFZ](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SINDLHKORT` | random: codelist: JN_INDICATOR |  |  | [JN_INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SINDSA03` | random: codelist: JN_INDICATOR |  |  | [JN_INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SINDSA43` | random: codelist: JN_INDICATOR |  |  | [JN_INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SINDSA71` | random: codelist: JN_INDICATOR |  |  | [JN_INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SINDSA72` | random: codelist: JN_INDICATOR |  |  | [JN_INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SINDVAKBN` | random: codelist: JN_INDICATOR |  |  | [JN_INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SINDZW` | random: codelist: JN_INDICATOR |  |  | [JN_INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SINLEGLEVENSLOOP` | random: codelist: JN_INDICATOR |  |  | [JN_INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SOVERWERK` | random: codelist: INDICATOR_01 |  |  | [INDICATOR_01](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SPOLISDIENSTVERBAND` | params: dienstverband_p | NL | [81431NED](https://opendata.cbs.nl/statline/#/CBS/nl/dataset/81431NED) | [SPOLISDIENSTVERBAND](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SRISGRP` | random: codelist: SRISGRP |  |  | [SRISGRP](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SSRTIV` | random: codelist: SSRTIV |  |  | [SSRTIV](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SWEKARBDUURKLASSE` | params: wekarbduur_p | NL | [81431NED](https://opendata.cbs.nl/statline/#/CBS/nl/dataset/81431NED) | [SWEKARBDUURKLASSE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SARBEIDSRELATIE` | random: codelist: SARBEIDSRELATIE |  |  | [SARBEIDSRELATIE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SAUTOVANDEZAAK` | random: codelist: SAUTOVANDEZAAK |  |  | [SAUTOVANDEZAAK](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SBEID` | spine-derived | NL |  |  |
| `SCAOSECTOR` | random: codelist: SCAOSECTOR |  |  | [SCAOSECTOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SDATUMAANVANGIKV` | spine-derived | NL |  |  |
| `SDATUMEINDEIKV` | spine-derived | NL |  |  |
| `SINDWAO` | random: codelist: JN_INDICATOR |  |  | [JN_INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SINDWW` | random: codelist: JN_INDICATOR |  |  | [JN_INDICATOR](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SLBTAB` | random: codelist: SLBTAB |  |  | [SLBTAB](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SLHNR_crypt` | random hex, width=32 |  |  |  |
| `SSECT` | params: ssect_p | NL | [81431NED](https://opendata.cbs.nl/statline/#/CBS/nl/dataset/81431NED) | [SSECT](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SSOORTBAAN` | params: soortbaan_p | NL | [81431NED](https://opendata.cbs.nl/statline/#/CBS/nl/dataset/81431NED) | [SSOORTBAAN](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `STIJDVAKTYPE` | random: codelist: STIJDVAKTYPE |  |  | [STIJDVAKTYPE](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SPRWGAWHK` | random: normal (mean=15, sd=25) |  |  |  |
| `SWGHZVW` | random: normal (mean=180, sd=120) |  |  |  |
| `SPRGEDIFFWHK` | random: normal (mean=10, sd=20) |  |  |  |
| `SINDTIJDHK` | random: codelist: INDICATOR_01 |  |  | [INDICATOR_01](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SIMPUTATIE` | random: codelist: INDICATOR_01 |  |  | [INDICATOR_01](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SINDPRKJONGRWEN` | random: codelist: INDICATOR_01 |  |  | [INDICATOR_01](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SINDPKAGH` | random: codelist: INDICATOR_01 |  |  | [INDICATOR_01](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SINDPKNWARBVOUDWN` | random: codelist: INDICATOR_01 |  |  | [INDICATOR_01](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SINDPMA` | random: codelist: INDICATOR_01 |  |  | [INDICATOR_01](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SCTRCTLN` | random: normal (mean=2800, sd=1200) |  |  |  |
| `SAANTCTRCTURENPWK` | random: normal (mean=32, sd=8) |  |  |  |
| `SBEDRRNTKSTVPERSL` | random: normal (mean=0, sd=20) |  |  |  |
| `SINDWAARNEMING` | random: codelist: INDICATOR_01 |  |  | [INDICATOR_01](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SModelramingPensioenpremieWn` | random: normal (mean=100, sd=80) |  |  |  |
| `SModelramingPensioenpremieWg` | random: normal (mean=200, sd=150) |  |  |  |
| `SModelramingVutpremieWn` | random: normal (mean=10, sd=30) |  |  |  |
| `SModelramingVutpremieWg` | random: normal (mean=20, sd=50) |  |  |  |
| `SModelramingSFpremieWg` | random: normal (mean=15, sd=40) |  |  |  |
| `SIndAvrLkvOudrWn` | random: codelist: INDICATOR_01 |  |  | [INDICATOR_01](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SIndAvrLkvAgWn` | random: codelist: INDICATOR_01 |  |  | [INDICATOR_01](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SIndAvrLkvDgBafSb` | random: codelist: INDICATOR_01 |  |  | [INDICATOR_01](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `SIndAvrLkvHpAgWn` | random: codelist: INDICATOR_01 |  |  | [INDICATOR_01](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `CdRdnEindArbov` | random: codelist: CDRDNEINDARB |  |  | [CDRDNEINDARB](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `CdCaoInl_crypt` | random hex, width=32 |  |  |  |
| `IndArbovOnbepTd` | random: codelist: INDICATOR_01 |  |  | [INDICATOR_01](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `IndSchriftArbov` | random: codelist: INDICATOR_01 |  |  | [INDICATOR_01](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `IndOprov` | random: codelist: INDICATOR_01 |  |  | [INDICATOR_01](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `IndJrurennrm` | random: codelist: INDICATOR_01 |  |  | [INDICATOR_01](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `PRLNUFO` | random: normal (mean=10, sd=25) |  |  |  |
| `PRLNAWFANWLg` | random: normal (mean=30, sd=30) |  |  |  |
| `PRLNAWFANWHg` | random: normal (mean=50, sd=40) |  |  |  |
| `PRLNAWFANWHz` | random: normal (mean=0, sd=10) |  |  |  |
| `PrAwfLg` | random: normal (mean=10, sd=15) |  |  |  |
| `PrAwfHg` | random: normal (mean=15, sd=20) |  |  |  |
| `PrAwfHz` | random: normal (mean=0, sd=5) |  |  |  |
| `INDPUBAANONBEPTD` | random: codelist: INDICATOR_01 |  |  | [INDICATOR_01](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |
| `OPBAVWB` | random: normal (mean=5, sd=15) |  |  |  |
| `OPNAVWB` | random: normal (mean=5, sd=15) |  |  |  |
| `PRLNAOFANWHG` | random: normal (mean=10, sd=20) |  |  |  |
| `PRLNAOFANWLG` | random: normal (mean=5, sd=10) |  |  |  |
| `PRLNAOFANWUIT` | random: normal (mean=0, sd=5) |  |  |  |
| `PRAOFHG` | random: normal (mean=5, sd=10) |  |  |  |
| `PRAOFLG` | random: normal (mean=3, sd=8) |  |  |  |
| `PRAOFUIT` | random: normal (mean=0, sd=5) |  |  |  |
| `OPSLWKO` | random: normal (mean=5, sd=15) |  |  |  |
| `PRLNWHKANW` | random: normal (mean=10, sd=20) |  |  |  |
| `PRLNAWFANWUIT` | random: normal (mean=0, sd=5) |  |  |  |
| `PRAWFUIT` | random: normal (mean=0, sd=5) |  |  |  |
| `INDDEELNTIJDSPF` | random: codelist: INDICATOR_01 |  |  | [INDICATOR_01](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/spolis/codelists.yaml) |

</details>

## Vermogens van huishoudens

<details>
<summary><code>VEHTAB</code></summary>

| Column | Source | Spatial | Calibration | Codelist |
|--------|--------|---------|-------------|----------|
| `RINPERSOONSHKW` | value: R |  |  | [RINPERSOONSHKW](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/vehtab/codelists.yaml) |
| `RINPERSOONHKW` | spine-derived | NL |  |  |
| `VEHP100WELVAART` | spine-derived | NL |  |  |
| `VEHP100HVERM` | spine-derived | NL |  |  |
| `VEHW1000VERH` | spine-derived | NL |  |  |
| `VEHW1100BEZH` | params: bezh_mean | NL | [83834NED](https://opendata.cbs.nl/statline/#/CBS/nl/dataset/83834NED) |  |
| `VEHW1110FINH` | params: finh_mean | NL | [83834NED](https://opendata.cbs.nl/statline/#/CBS/nl/dataset/83834NED) |  |
| `VEHW1111BANH` | params: banh_mean | NL | [83834NED](https://opendata.cbs.nl/statline/#/CBS/nl/dataset/83834NED) |  |
| `VEHW1112EFFH` | params: effh_mean | NL | [83834NED](https://opendata.cbs.nl/statline/#/CBS/nl/dataset/83834NED) |  |
| `VEHW1120ONRH` | params: onrh_mean | NL | [83834NED](https://opendata.cbs.nl/statline/#/CBS/nl/dataset/83834NED) |  |
| `VEHW1121WONH` | params: wonh_mean | NL | [83834NED](https://opendata.cbs.nl/statline/#/CBS/nl/dataset/83834NED) |  |
| `VEHW1122OGOH` | params: ogoh_mean | NL | [83834NED](https://opendata.cbs.nl/statline/#/CBS/nl/dataset/83834NED) |  |
| `VEHW1130ONDH` | params: ondh_mean | NL | [83834NED](https://opendata.cbs.nl/statline/#/CBS/nl/dataset/83834NED) |  |
| `VEHW1140ABEH` | params: abeh_mean | NL | [83834NED](https://opendata.cbs.nl/statline/#/CBS/nl/dataset/83834NED) |  |
| `VEHW1150OVEH` | params: oveh_mean | NL | [83834NED](https://opendata.cbs.nl/statline/#/CBS/nl/dataset/83834NED) |  |
| `VEHW1200STOH` | params: stoh_mean | NL | [83834NED](https://opendata.cbs.nl/statline/#/CBS/nl/dataset/83834NED) |  |
| `VEHW1210SHYH` | params: shyh_mean | NL | [83834NED](https://opendata.cbs.nl/statline/#/CBS/nl/dataset/83834NED) |  |
| `VEHW1220SSTH` | params: ssth_mean | NL | [83834NED](https://opendata.cbs.nl/statline/#/CBS/nl/dataset/83834NED) |  |
| `VEHW1230SOVH` | params: sovh_mean | NL | [83834NED](https://opendata.cbs.nl/statline/#/CBS/nl/dataset/83834NED) |  |
| `VEHWVEREXEWH` | params: verexewh_mean | NL | [83834NED](https://opendata.cbs.nl/statline/#/CBS/nl/dataset/83834NED) |  |

</details>

## Energieverbruik particuliere woningen

<details>
<summary><code>ENERGIEVERBRUIKTAB</code></summary>

| Column | Source | Spatial | Calibration | Codelist |
|--------|--------|---------|-------------|----------|
| `SOORTOBJECTNUMMER` | spine-derived | gemeente |  | [SOORTOBJECTNUMMER](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/energieverbruik/codelists.yaml) |
| `RINOBJECTNUMMER` | spine-derived | gemeente |  |  |
| `WONINGT` | value:   |  |  |  |
| `WOONR` | value:   |  |  |  |
| `STADSW` | params: stadsverwarming_categorical | NL |  | [STADSW](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/energieverbruik/codelists.yaml) |
| `GAS` | params: gas_mean | NL |  |  |
| `ELEK` | params: elek_mean | NL |  |  |
| `GASBRON` | random: codelist: GASBRON |  |  | [GASBRON](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/energieverbruik/codelists.yaml) |
| `ELEKBRON` | random: codelist: ELEKBRON |  |  | [ELEKBRON](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/energieverbruik/codelists.yaml) |
| `ELEKTERUG` | random: normal (mean=500, sd=1200) |  |  |  |
| `ELEKNETTO` | random: normal (mean=2400, sd=1200) |  |  |  |
| `GASSJV` | random: normal (mean=1100, sd=620) |  |  |  |
| `WARMTESCHATTING` | random: normal (mean=35, sd=20) |  |  |  |
| `ZONPV` | params: solar_pv_categorical | NL |  | [ZONPV](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/energieverbruik/codelists.yaml) |
| `ZONVERMOGEN1JAN` | random: normal (mean=2.5, sd=3) |  |  |  |
| `ZONVERMOGEN31DEC` | random: normal (mean=2.8, sd=3.2) |  |  |  |
| `ZONPVBRON` | random: codelist: ZONPVBRON |  |  | [ZONPVBRON](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/energieverbruik/codelists.yaml) |
| `HOOFDVERWARMING31DEC` | random: codelist: HOOFDVERWARMING31DEC |  |  | [HOOFDVERWARMING31DEC](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/energieverbruik/codelists.yaml) |
| `WONINGBEWONING10PROFIELEN` | random: codelist: WONINGBEWONING10PROFIELEN |  |  | [WONINGBEWONING10PROFIELEN](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/energieverbruik/codelists.yaml) |
| `KBHOOFDVERWARMING31DEC` | random: codelist: KBHOOFDVERWARMING31DEC |  |  | [KBHOOFDVERWARMING31DEC](https://github.com/joris-klingen/simcbsradata/blob/main/inst/config/datasets/energieverbruik/codelists.yaml) |

</details>

