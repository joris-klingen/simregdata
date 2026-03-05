# Column Overview

Auto-generated overview of all simulated columns, their calibration level, and data source.

Generated: 2026-03-05

## Summary by calibration level

| Level | Count |
|-------|------:|
| spine-derived | 161 |
| codelist-hardcoded | 89 |
| random-normal | 70 |
| statline-calibrated | 37 |
| random-uniform | 24 |
| constant | 18 |
| random-id | 5 |
| computed | 2 |

**Total columns:** 406

## woonbase

### ek_hh_welvaart

| Column | Level | Source |
|--------|-------|--------|
| `RINPERSOONS` | spine-derived | spine.hh.RINPERSOONS_Ref |
| `RINPERSOON` | spine-derived | spine.hh.RINPERSOON_Ref |
| `AGHT{sfx}` | codelist-hardcoded | codelist: AGHT |
| `AGIAH{sfx}` | codelist-hardcoded | codelist: AGIAH |
| `AGTSH{sfx}` | codelist-hardcoded | codelist: AGTSH |
| `AOWHT{sfx}` | codelist-hardcoded | codelist: AOWHT |
| `ARMOEDE{sfx}` | random-uniform | uniform [50, 500] |
| `ARMSOC{sfx}` | random-uniform | uniform [50, 500] |
| `BBIHJ{sfx}` | random-uniform | uniform [1, 20] |
| `BELIAGHT{sfx}` | random-uniform | uniform [5000, 80000] |
| `BELIAGIAH{sfx}` | random-uniform | uniform [5000, 80000] |
| `BELIAGTSH{sfx}` | random-uniform | uniform [5000, 80000] |
| `BELIH{sfx}` | spine-derived | spine.hh.BELIH |
| `BESTINKH{sfx}` | spine-derived | spine.hh.BESTINKH |
| `BETAALBUDGET{sfx}` | random-uniform | uniform [-10000, 60000] |
| `BETAALRESERVE{sfx}` | random-uniform | uniform [-5000, 50000] |
| `CORBETAALBUDGET{sfx}` | codelist-hardcoded | hardcoded probs |
| `EHALGR{sfx}` | random-uniform | uniform [1, 30] |
| `GESTINKH{sfx}` | spine-derived | spine.hh.GESTINKH |
| `LEERGROND{sfx}` | random-uniform | uniform [0, 50000] |
| `P100HBEST{sfx}` | spine-derived | spine.hh.P100HBEST |
| `P100HGEST{sfx}` | spine-derived | spine.hh.P100HGEST |
| `P100HVERM{sfx}` | spine-derived | spine.hh.P100HVERM |
| `P100WELVAART{sfx}` | spine-derived | spine.hh.P100WELVAART |
| `POPFEC{sfx}` | codelist-hardcoded | codelist: POPFEC |
| `POPIIV{sfx}` | codelist-hardcoded | codelist: POPIIV |
| `POPIIVWONING{sfx}` | random-uniform | uniform [0, 10] |
| `VERMHH{sfx}` | spine-derived | spine.hh.VERMHH |
| `VROMHH{sfx}` | spine-derived | spine.hh.VROMHH |
| `W1000VERH{sfx}` | random-uniform | uniform [0, 500000] |
| `VERSCHILIIV{sfx}` | codelist-hardcoded | codelist: VERSCHILIIV |

### ek_obj_panden

| Column | Level | Source |
|--------|-------|--------|
| `PandID` | spine-derived | spine.obj.PandID1Jan |
| `PandAantalVbos{sfx}` | random-uniform | uniform [1, 20] |
| `PandAantalWoning{sfx}` | random-uniform | uniform [0, 15] |
| `PandAantalNietWoning{sfx}` | random-uniform | uniform [0, 5] |
| `PandOppTotWoning{sfx}` | random-uniform | uniform [0, 5000] |
| `PandOppTotNietWoning{sfx}` | random-uniform | uniform [0, 3000] |
| `PandOppGemWoning{sfx}` | random-uniform | uniform [30, 250] |
| `PandOppGemNietWoning{sfx}` | random-uniform | uniform [30, 500] |
| `PandWinkelfunctie{sfx}` | codelist-hardcoded | codelist: PANDFUNCTIE |
| `PandKantoorfunctie{sfx}` | codelist-hardcoded | codelist: PANDFUNCTIE |
| `PandIndustriefunctie{sfx}` | codelist-hardcoded | codelist: PANDFUNCTIE |
| `PandBijeenkomstfunctie{sfx}` | codelist-hardcoded | codelist: PANDFUNCTIE |
| `PandGezondheidszorgfunctie{sfx}` | codelist-hardcoded | codelist: PANDFUNCTIE |
| `PandAnderefunctie{sfx}` | codelist-hardcoded | codelist: PANDFUNCTIE |
| `PandTransformatie{sfx}` | codelist-hardcoded | codelist: PANDTRANSFORMATIE |
| `PandHoogte` | random-uniform | uniform [3, 60] |
| `PandAantalVerdiepingen` | random-uniform | uniform [1, 15] |
| `PandDaktype` | codelist-hardcoded | codelist: PANDDAKTYPE |

### kenmerken_hh

| Column | Level | Source |
|--------|-------|--------|
| `HUISHOUDNR{sfx}` | spine-derived | spine.hh.HUISHOUDNR |
| `DatumAanvangHH{sfx}` | spine-derived | spine.hh.DATUMAANVANGHH |
| `IMPUTATIECODEHH{sfx}` | spine-derived | spine.hh.IMPUTATIECODEHH |
| `RefPersoonHH{sfx}` | spine-derived | spine.hh.REFPERSOONHH_Ref |
| `RINPERSOON` | spine-derived | spine.hh.RINPERSOON_Ref |
| `RINPERSOONS` | spine-derived | spine.hh.RINPERSOONS_Ref |
| `TYPHH{sfx}` | spine-derived | spine.hh.TYPHH |
| `AantalKinderenPerHuishouden{sfx}` | spine-derived | spine.hh.AantalKinderenPerHuishouden |
| `AantalPersonenPerHuishouden{sfx}` | spine-derived | spine.hh.AantalPersonenPerHuishouden |

### kenmerken_obj

| Column | Level | Source |
|--------|-------|--------|
| `RINOBJECTNUMMER` | spine-derived | spine.obj.RINOBJECTNUMMER |
| `SOORTOBJECTNUMMER` | spine-derived | spine.obj.SOORTOBJECTNUMMER |
| `GEMEENTECODEJJJJ{sfx}` | spine-derived | spine.obj.GemeenteCodeJJJJ{sfx} |
| `WIJKCODEJJJJ{sfx}` | spine-derived | spine.obj.WijkCodeJJJJ{sfx} |
| `BUURTCODEJJJJ{sfx}` | spine-derived | spine.obj.BuurtCodeJJJJ{sfx} |
| `Indicator_VBOIsNieuwbouw` | spine-derived | spine.obj.Indicator_VBOIsNieuwbouw1Jan |
| `Indicator_VBOIsNieuwbouwJJJJ-1` | spine-derived | spine.obj.Indicator_VBOIsNieuwbouw1Jan |
| `VSLSoort{sfx}` | spine-derived | spine.obj.VSLSoort{sfx} |
| `VBOWoningType{sfx}` | spine-derived | spine.obj.VBOWoningType{sfx} |
| `VBOBouwjaar{sfx}` | spine-derived | spine.obj.VBOBouwjaar{sfx} |
| `VBOOppervlakte{sfx}` | spine-derived | spine.obj.VBOOppervlakte{sfx} |
| `WOZWaardeObjectBAG{sfx}` | spine-derived | spine.obj.WOZWaardeObjectBAG{sfx} |
| `VBOStatus{sfx}` | spine-derived | spine.obj.VBOStatus{sfx} |

### kenmerken_pers

| Column | Level | Source |
|--------|-------|--------|
| `RINPERSOON` | spine-derived | spine.pers.RINPERSOON |
| `RINPERSOONS` | spine-derived | spine.pers.RINPERSOONS |
| `GBABurgerlijkeStaat{sfx}` | spine-derived | spine.pers.GBABurgerlijkeStaat |
| `GBAGeboorteJaar{sfx}` | spine-derived | spine.pers.GBAGeboorteJaar |
| `GBAGeslachtsAanduiding{sfx}` | spine-derived | spine.pers.GBAGeslachtsAanduiding |
| `GEMEENTECODEJJJJ{sfx}` | spine-derived | spine.pers.GemeenteCodeJJJJ{sfx} |
| `WIJKCODEJJJJ{sfx}` | spine-derived | spine.pers.WijkCodeJJJJ{sfx} |
| `BUURTCODEJJJJ{sfx}` | spine-derived | spine.pers.BuurtCodeJJJJ{sfx} |
| `PLHH{sfx}` | spine-derived | spine.pers.PLHH |
| `RINOBJECTNUMMER{sfx}` | spine-derived | spine.pers.RINOBJECTNUMMER |
| `SOORTOBJECTNUMMER{sfx}` | spine-derived | spine.pers.SOORTOBJECTNUMMER |
| `AanvangWoonduur{sfx}` | spine-derived | spine.pers.AanvangWoonduur |
| `OPLNIVSOI2016AGG4HBMETNIRWO{sfx}` | codelist-hardcoded | hardcoded probs |
| `OPLNIVSOI2016AGG4HGMETNIRWO{sfx}` | codelist-hardcoded | hardcoded probs |
| `OPLNIVSOI2021AGG4HBMETNIRWO{sfx}` | codelist-hardcoded | hardcoded probs |
| `OPLNIVSOI2021AGG4HGMETNIRWO{sfx}` | codelist-hardcoded | hardcoded probs |
| `GEWICHTHOOGSTEOPL{sfx}` | random-uniform | uniform [0.5, 1.5] |

### populatie_hh

| Column | Level | Source |
|--------|-------|--------|
| `HUISHOUDNR{sfx}` | spine-derived | spine.hh.HUISHOUDNR |
| `DATUMAANVANGHH{sfx}` | spine-derived | spine.hh.DATUMAANVANGHH |
| `IMPUTATIECODEHH{sfx}` | spine-derived | spine.hh.IMPUTATIECODEHH |
| `RINPERSOONS` | spine-derived | spine.hh.RINPERSOONS_Ref |
| `RINPERSOON` | spine-derived | spine.hh.RINPERSOON_Ref |
| `RINOBJECTNUMMER{sfx}` | spine-derived | spine.hh.RINOBJECTNUMMER |
| `SOORTOBJECTNUMMER{sfx}` | spine-derived | spine.hh.SOORTOBJECTNUMMER |
| `TYPHH{sfx}` | spine-derived | spine.hh.TYPHH |
| `AantalPersonenPerHuishouden{sfx}` | spine-derived | spine.hh.AantalPersonenPerHuishouden |
| `AantalKinderenPerHuishouden{sfx}` | spine-derived | spine.hh.AantalKinderenPerHuishouden |
| `LeeftijdRefPersoon{sfx}` | spine-derived | spine.hh.LeeftijdRefPersoon |
| `PLHHRefPersoon{sfx}` | spine-derived | spine.hh.PLHH_Ref |
| `GBAGeslachtsaanduidingRefPersoon{sfx}` | spine-derived | spine.hh.GBAGeslachtsAanduiding_Ref |
| `GemeenteCodeJJJJ{sfx}` | spine-derived | spine.hh.GemeenteCodeJJJJ{sfx} |
| `VSLSoort{sfx}` | spine-derived | spine.hh.VSLSoort{sfx} |
| `WOZWaardeObjectBAGKlasse{sfx}` | spine-derived | spine.hh.WOZWaardeObjectBAGKlasse{sfx} |
| `VBOBouwJaarKlasse{sfx}` | spine-derived | spine.hh.VBOBouwJaarKlasse{sfx} |
| `VBOOppervlakteKlasse{sfx}` | spine-derived | spine.hh.VBOOppervlakteKlasse{sfx} |
| `VBOWoningType{sfx}` | spine-derived | spine.hh.VBOWoningType{sfx} |
| `TypeEigenaar{sfx}` | spine-derived | spine.hh.TypeEigenaar{sfx} |
| `Indicator_HHIsAanwezig{sfx}` | constant | value: 1 |

### populatie_obj

| Column | Level | Source |
|--------|-------|--------|
| `SOORTOBJECTNUMMER` | spine-derived | spine.obj.SOORTOBJECTNUMMER |
| `RINOBJECTNUMMER` | spine-derived | spine.obj.RINOBJECTNUMMER |
| `PandID{sfx}` | spine-derived | spine.obj.PandID{sfx} |
| `VSLSoort{sfx}` | spine-derived | spine.obj.VSLSoort{sfx} |
| `HUISHOUDNR{sfx}` | spine-derived | spine.obj.HUISHOUDNR |
| `DATUMAANVANGHH{sfx_lower}` | spine-derived | spine.obj.DATUMAANVANGHH |
| `RINPERSOONS_Ref{sfx_lower}` | spine-derived | spine.obj.RINPERSOONS_Ref2 |
| `RINPERSOON_Ref{sfx_lower}` | spine-derived | spine.obj.RINPERSOON_Ref2 |
| `VBOWoningType{sfx}` | spine-derived | spine.obj.VBOWoningType{sfx} |
| `VBOBouwJaarKlasse{sfx}` | spine-derived | spine.obj.VBOBouwJaarKlasse{sfx} |
| `VBOOppervlakteKlasse{sfx}` | spine-derived | spine.obj.VBOOppervlakteKlasse{sfx} |
| `WOZWaardeObjectBAGKlasse{sfx}` | spine-derived | spine.obj.WOZWaardeObjectBAGKlasse{sfx} |
| `TypeEigenaar{sfx}` | spine-derived | spine.obj.TypeEigenaar{sfx} |
| `AantalPersonenPerVSLKlasse{sfx}` | computed | computed.AantalPersonenPerVSLKlasse |
| `AantalHuishoudensPerVSLKlasse{sfx}` | constant | value: 1 |
| `AantalKinderenPerVSL{sfx}` | spine-derived | spine.obj.AantalKinderenPerVSL |
| `LeeftijdJongsteKindPerVSL{sfx}` | spine-derived | spine.obj.LeeftijdJongsteKindPerVSL |
| `TYPHH{sfx}` | spine-derived | spine.obj.TYPHH |
| `GemeenteCodeJJJJ{sfx}` | spine-derived | spine.obj.GemeenteCodeJJJJ{sfx} |
| `Indicator_VBOIsAanwezig{sfx}` | spine-derived | spine.obj.Indicator_VBOIsAanwezig{sfx} |
| `Indicator_VSLIsAanwezig{sfx}` | spine-derived | spine.obj.Indicator_VSLIsAanwezig{sfx} |
| `Indicator_VBOIsGesloopt` | spine-derived | spine.obj.Indicator_VBOIsGesloopt |
| `Indicator_VSLIsOntrokken` | spine-derived | spine.obj.Indicator_VSLIsOntrokken |
| `Indicator_VBOIsTransformatie` | spine-derived | spine.obj.Indicator_VBOIsTransformatie |
| `Indicator_VBOIsNieuwbouw` | spine-derived | spine.obj.Indicator_VBOIsNieuwbouw |
| `Indicator_VSLIsNieuw` | spine-derived | spine.obj.Indicator_VSLIsNieuw |

### populatie_pers

| Column | Level | Source |
|--------|-------|--------|
| `RINPERSOON` | spine-derived | spine.pers.RINPERSOON |
| `RINPERSOONS` | spine-derived | spine.pers.RINPERSOONS |
| `RefPersoonHH{sfx}` | spine-derived | spine.pers.REFPERSOONHH |
| `HUISHOUDNR{sfx}` | spine-derived | spine.pers.HUISHOUDNR |
| `DATUMAANVANGHH{sfx}` | spine-derived | spine.pers.DATUMAANVANGHH |
| `IMPUTATIECODEHH{sfx}` | spine-derived | spine.pers.IMPUTATIECODEHH |
| `RINOBJECTNUMMER{sfx}` | spine-derived | spine.pers.RINOBJECTNUMMER |
| `SOORTOBJECTNUMMER{sfx}` | spine-derived | spine.pers.SOORTOBJECTNUMMER |
| `Indicator_PersoonIsGeboren` | spine-derived | spine.pers.Indicator_PersoonIsGeboren |
| `Indicator_PersoonIsOverleden` | spine-derived | spine.pers.Indicator_PersoonIsOverleden |
| `Indicator_PersoonIsGeemigreerd` | spine-derived | spine.pers.Indicator_PersoonIsGeemigreerd |
| `Indicator_PersoonIsAdministratiefAfgevoerd` | spine-derived | spine.pers.Indicator_PersoonIsAdministratiefAfgevoerd |
| `Indicator_PersoonIsGeimmigreerd` | spine-derived | spine.pers.Indicator_PersoonIsGeimmigreerd |
| `Indicator_PersoonIsAdministratiefOpgenomen` | spine-derived | spine.pers.Indicator_PersoonIsAdministratiefOpgenomen |
| `Indicator_PersoonIsVerhuisd` | spine-derived | spine.pers.Indicator_PersoonIsVerhuisd |
| `Indicator_PersoonIsAanwezig1Jan` | spine-derived | spine.pers.Indicator_PersoonIsAanwezig1Jan |
| `Indicator_PersoonIsAanwezig31Dec` | spine-derived | spine.pers.Indicator_PersoonIsAanwezig31Dec |
| `AantalKeerVerhuisd` | spine-derived | spine.pers.AantalKeerVerhuisd |
| `PLHH{sfx}` | spine-derived | spine.pers.PLHH |
| `TYPHH{sfx}` | spine-derived | spine.pers.TYPHH |
| `GBAGeslachtsAanduiding{sfx}` | spine-derived | spine.pers.GBAGeslachtsAanduiding |
| `GBAGeboorteJaar{sfx}` | spine-derived | spine.pers.GBAGeboorteJaar |
| `GBABurgerlijkeStaat{sfx}` | spine-derived | spine.pers.GBABurgerlijkeStaat |
| `AantalPersonenPerHuishouden{sfx}` | spine-derived | spine.pers.AantalPersonenPerHuishouden |
| `GemeenteCodeJJJJ{sfx}` | spine-derived | spine.pers.GemeenteCodeJJJJ{sfx} |
| `VSLSoort{sfx}` | spine-derived | spine.pers.VSLSoort{sfx} |
| `TypeEigenaar{sfx}` | spine-derived | spine.pers.TypeEigenaar{sfx} |
| `VBOWoningType{sfx}` | spine-derived | spine.pers.VBOWoningType{sfx} |
| `VBOBouwJaarKlasse{sfx}` | spine-derived | spine.pers.VBOBouwJaarKlasse{sfx} |
| `VBOOppervlakteKlasse{sfx}` | spine-derived | spine.pers.VBOOppervlakteKlasse{sfx} |
| `WOZWaardeObjectBAGKlasse{sfx}` | spine-derived | spine.pers.WOZWaardeObjectBAGKlasse{sfx} |

### sleutel

| Column | Level | Source |
|--------|-------|--------|
| `RINPERSOONS` | spine-derived | spine.pers.RINPERSOONS |
| `RINPERSOON` | spine-derived | spine.pers.RINPERSOON |
| `REFPERSOONHH` | spine-derived | spine.pers.REFPERSOONHH |
| `PLHH` | spine-derived | spine.pers.PLHH |
| `HUISHOUDNR` | spine-derived | spine.pers.HUISHOUDNR |
| `DATUMAANVANGHH` | spine-derived | spine.pers.DATUMAANVANGHH |
| `TYPHH` | spine-derived | spine.pers.TYPHH |
| `IMPUTATIECODEHH` | spine-derived | spine.pers.IMPUTATIECODEHH |
| `SOORTOBJECTNUMMER` | spine-derived | spine.pers.SOORTOBJECTNUMMER |
| `RINOBJECTNUMMER` | spine-derived | spine.pers.RINOBJECTNUMMER |
| `INVOORRAAD` | constant | value: 1 |
| `VBOVOORRAADTYPE` | constant | value: 0 |
| `BEGINGELDIGHEID` | constant | template: {jan1} |
| `EINDGELDIGHEID` | constant | template: {dec31} |
| `REDENBEGINGELDIGHEID` | codelist-hardcoded | hardcoded probs |
| `REDENEINDGELDIGHEID` | constant | value: NVT |

## rdw

### kentekens

| Column | Level | Source |
|--------|-------|--------|
| `RINPERSOONS` | codelist-hardcoded | codelist: RINPERSOONS_RDW |
| `RINPERSOON` | spine-derived | spine.pers.RINPERSOON |
| `RINKENTEKEN` | spine-derived | spine.pers.RINKENTEKEN |
| `KLEURCODEVRTG` | statline-calibrated | params: kleur_p (85237NED, 85236NED, 85404NED) |
| `EERSTETOELDAT1VRTG` | statline-calibrated | params: bouwjaar_p (85237NED, 85236NED, 85404NED) |
| `SRTREFVRTG` | codelist-hardcoded | codelist: SRTREF |
| `VRTGSOORT` | statline-calibrated | params: vrtgsoort_p (85237NED, 85236NED, 85404NED) |
| `BRANDSTCODECORVRTG` | statline-calibrated | params: brandstof_p (85237NED, 85236NED, 85404NED) |
| `MASSALEEGCORVRTG` | statline-calibrated | params: gewicht_mean (85237NED, 85236NED, 85404NED) |
| `MAXLAADVERMCORVRTG` | random-uniform | uniform [0, 3000] |
| `AANTALCYLCORVRTG` | codelist-hardcoded | hardcoded probs |
| `CYLININHOUDCORVRTG` | random-normal | normal (mean=1600, sd=600) |
| `SOORTBROMFIETSCOR` | codelist-hardcoded | codelist: SOORTBROMFIETS |

### verkeersprestatie

| Column | Level | Source |
|--------|-------|--------|
| `RINKENTEKEN` | spine-derived | spine.pers.RINKENTEKEN |
| `RinpersoonsVP` | codelist-hardcoded | codelist: RINPERSOONS_RDW |
| `RinpersoonVP` | spine-derived | spine.pers.RINPERSOON |
| `VPGEWICHT` | codelist-hardcoded | hardcoded probs |
| `VPDGNWEG` | codelist-hardcoded | hardcoded probs |
| `VPJAARKM` | statline-calibrated | params: jaarkm_mean (85237NED, 85236NED, 85404NED) |

## spolis

### spolisbus

| Column | Level | Source |
|--------|-------|--------|
| `RINPERSOONS` | codelist-hardcoded | codelist: RINPERSOONS_SPOLIS |
| `RINPERSOON` | spine-derived | spine.pers.RINPERSOON |
| `IKVID` | random-id | random hex, width=32 |
| `SDATUMAANVANGIKO` | constant | template: {jan1} |
| `SDATUMEINDEIKO` | constant | template: {dec31} |
| `SAANTSV` | random-normal | normal (mean=18, sd=6) |
| `SAANTVERLU` | random-normal | normal (mean=130, sd=40) |
| `SAUTOZAAK` | statline-calibrated | params: autozaak_mean (81431NED) |
| `SBAANDAGEN` | codelist-hardcoded | hardcoded probs |
| `SBASISLOON` | statline-calibrated | params: basisloon_mean (81431NED) |
| `SBASISUREN` | statline-calibrated | params: basisuren_mean (81431NED) |
| `SBEDRALINWWB` | random-normal | normal (mean=0, sd=50) |
| `SBEDRRCHTAL` | random-normal | normal (mean=0, sd=20) |
| `SBEDRZDAFTR` | random-normal | normal (mean=0, sd=10) |
| `SBIJDRZVW` | random-normal | normal (mean=180, sd=100) |
| `SBIJZONDEREBELONING` | statline-calibrated | params: bijzbeloning_mean (81431NED) |
| `SEXTRSAL` | random-normal | normal (mean=50, sd=200) |
| `SINCIDENTSAL` | random-normal | normal (mean=20, sd=100) |
| `SINGLBPH` | random-normal | normal (mean=100, sd=200) |
| `SLNINGLD` | statline-calibrated | params: loon_mean (81431NED) |
| `SLNLBPH` | statline-calibrated | params: lnlbph_mean (81431NED) |
| `SLNOWRK` | random-normal | normal (mean=50, sd=200) |
| `SLNSV` | statline-calibrated | params: lnsv_mean (81431NED) |
| `SLNTABBB` | random-normal | normal (mean=0, sd=50) |
| `SLVLPREG` | random-normal | normal (mean=0, sd=50) |
| `SLVLPREGTOEG` | random-normal | normal (mean=0, sd=50) |
| `SOPGRCHTEXTRSAL` | random-normal | normal (mean=0, sd=100) |
| `SOPGRCHTVAKBSL` | random-normal | normal (mean=0, sd=50) |
| `SOVERWERKUREN` | random-normal | normal (mean=3, sd=8) |
| `SPENSIOENPREMIE` | random-normal | normal (mean=250, sd=200) |
| `SPRAWF` | random-normal | normal (mean=90, sd=60) |
| `SPRUFO` | random-normal | normal (mean=15, sd=30) |
| `SPRWAOAOF` | random-normal | normal (mean=20, sd=30) |
| `SPRWAOAOK` | random-normal | normal (mean=15, sd=25) |
| `SPRWGF` | random-normal | normal (mean=30, sd=40) |
| `SREGULIEREUREN` | statline-calibrated | params: reguliereuren_mean (81431NED) |
| `SREISK` | random-normal | normal (mean=50, sd=80) |
| `SVAKBSL` | random-normal | normal (mean=200, sd=150) |
| `SVERGZVW` | random-normal | normal (mean=180, sd=120) |
| `SVERRARBKRT` | random-normal | normal (mean=10, sd=30) |
| `SVERSTRAANV` | random-normal | normal (mean=5, sd=20) |
| `SVOLTIJDDAGEN` | random-normal | normal (mean=22, sd=6) |
| `SWGBIJDRKO` | random-normal | normal (mean=0, sd=30) |
| `SWRDLN` | random-normal | normal (mean=100, sd=300) |
| `SWRDPRGEBRAUT` | random-normal | normal (mean=50, sd=200) |
| `SWRKNBIJDRAUT` | random-normal | normal (mean=10, sd=50) |
| `SCAO_crypt` | random-id | random hex, width=32 |
| `SCDAARD` | codelist-hardcoded | codelist: SCDAARD |
| `SCDAGH` | codelist-hardcoded | codelist: SCDAGH |
| `SCDINCINKVERM` | codelist-hardcoded | codelist: SCDINCINKVERM |
| `SCDINVLVPL1` | codelist-hardcoded | codelist: SCDINVLVPL |
| `SCDINVLVPL2` | codelist-hardcoded | codelist: SCDINVLVPL |
| `SCDINVLVPL3` | codelist-hardcoded | codelist: SCDINVLVPL |
| `SCDRDNGNBIJT` | codelist-hardcoded | codelist: SCDRDNGNBIJT |
| `SCDZVW` | codelist-hardcoded | codelist: SCDZVW |
| `SCONTRACTSOORT` | codelist-hardcoded | codelist: SCONTRACTSOORT |
| `SDATUMAANVANGIKVORG` | constant | template: {jan1} |
| `SFSINDFZ` | codelist-hardcoded | codelist: SFSINDFZ |
| `SINDLHKORT` | codelist-hardcoded | codelist: JN_INDICATOR |
| `SINDSA03` | codelist-hardcoded | codelist: JN_INDICATOR |
| `SINDSA43` | codelist-hardcoded | codelist: JN_INDICATOR |
| `SINDSA71` | codelist-hardcoded | codelist: JN_INDICATOR |
| `SINDSA72` | codelist-hardcoded | codelist: JN_INDICATOR |
| `SINDVAKBN` | codelist-hardcoded | codelist: JN_INDICATOR |
| `SINDZW` | codelist-hardcoded | codelist: JN_INDICATOR |
| `SINLEGLEVENSLOOP` | codelist-hardcoded | codelist: JN_INDICATOR |
| `SOVERWERK` | codelist-hardcoded | codelist: INDICATOR_01 |
| `SPOLISDIENSTVERBAND` | statline-calibrated | params: dienstverband_p (81431NED) |
| `SRISGRP` | codelist-hardcoded | codelist: SRISGRP |
| `SSRTIV` | codelist-hardcoded | codelist: SSRTIV |
| `SWEKARBDUURKLASSE` | statline-calibrated | params: wekarbduur_p (81431NED) |
| `SARBEIDSRELATIE` | codelist-hardcoded | codelist: SARBEIDSRELATIE |
| `SAUTOVANDEZAAK` | codelist-hardcoded | codelist: SAUTOVANDEZAAK |
| `SBEID` | random-id | random hex, width=8 |
| `SCAOSECTOR` | codelist-hardcoded | codelist: SCAOSECTOR |
| `SDATUMAANVANGIKV` | constant | template: {jan1} |
| `SDATUMEINDEIKV` | constant | template: {dec31} |
| `SINDWAO` | codelist-hardcoded | codelist: JN_INDICATOR |
| `SINDWW` | codelist-hardcoded | codelist: JN_INDICATOR |
| `SLBTAB` | codelist-hardcoded | codelist: SLBTAB |
| `SLHNR_crypt` | random-id | random hex, width=32 |
| `SSECT` | statline-calibrated | params: ssect_p (81431NED) |
| `SSOORTBAAN` | statline-calibrated | params: soortbaan_p (81431NED) |
| `STIJDVAKTYPE` | codelist-hardcoded | codelist: STIJDVAKTYPE |
| `SPRWGAWHK` | random-normal | normal (mean=15, sd=25) |
| `SWGHZVW` | random-normal | normal (mean=180, sd=120) |
| `SPRGEDIFFWHK` | random-normal | normal (mean=10, sd=20) |
| `SINDTIJDHK` | codelist-hardcoded | codelist: INDICATOR_01 |
| `SIMPUTATIE` | codelist-hardcoded | codelist: INDICATOR_01 |
| `SINDPRKJONGRWEN` | codelist-hardcoded | codelist: INDICATOR_01 |
| `SINDPKAGH` | codelist-hardcoded | codelist: INDICATOR_01 |
| `SINDPKNWARBVOUDWN` | codelist-hardcoded | codelist: INDICATOR_01 |
| `SINDPMA` | codelist-hardcoded | codelist: INDICATOR_01 |
| `SCTRCTLN` | random-normal | normal (mean=2800, sd=1200) |
| `SAANTCTRCTURENPWK` | random-normal | normal (mean=32, sd=8) |
| `SBEDRRNTKSTVPERSL` | random-normal | normal (mean=0, sd=20) |
| `SINDWAARNEMING` | codelist-hardcoded | codelist: INDICATOR_01 |
| `SModelramingPensioenpremieWn` | random-normal | normal (mean=100, sd=80) |
| `SModelramingPensioenpremieWg` | random-normal | normal (mean=200, sd=150) |
| `SModelramingVutpremieWn` | random-normal | normal (mean=10, sd=30) |
| `SModelramingVutpremieWg` | random-normal | normal (mean=20, sd=50) |
| `SModelramingSFpremieWg` | random-normal | normal (mean=15, sd=40) |
| `SIndAvrLkvOudrWn` | codelist-hardcoded | codelist: INDICATOR_01 |
| `SIndAvrLkvAgWn` | codelist-hardcoded | codelist: INDICATOR_01 |
| `SIndAvrLkvDgBafSb` | codelist-hardcoded | codelist: INDICATOR_01 |
| `SIndAvrLkvHpAgWn` | codelist-hardcoded | codelist: INDICATOR_01 |
| `CdRdnEindArbov` | codelist-hardcoded | codelist: CDRDNEINDARB |
| `CdCaoInl_crypt` | random-id | random hex, width=32 |
| `IndArbovOnbepTd` | codelist-hardcoded | codelist: INDICATOR_01 |
| `IndSchriftArbov` | codelist-hardcoded | codelist: INDICATOR_01 |
| `IndOprov` | codelist-hardcoded | codelist: INDICATOR_01 |
| `IndJrurennrm` | codelist-hardcoded | codelist: INDICATOR_01 |
| `PRLNUFO` | random-normal | normal (mean=10, sd=25) |
| `PRLNAWFANWLg` | random-normal | normal (mean=30, sd=30) |
| `PRLNAWFANWHg` | random-normal | normal (mean=50, sd=40) |
| `PRLNAWFANWHz` | random-normal | normal (mean=0, sd=10) |
| `PrAwfLg` | random-normal | normal (mean=10, sd=15) |
| `PrAwfHg` | random-normal | normal (mean=15, sd=20) |
| `PrAwfHz` | random-normal | normal (mean=0, sd=5) |
| `INDPUBAANONBEPTD` | codelist-hardcoded | codelist: INDICATOR_01 |
| `OPBAVWB` | random-normal | normal (mean=5, sd=15) |
| `OPNAVWB` | random-normal | normal (mean=5, sd=15) |
| `PRLNAOFANWHG` | random-normal | normal (mean=10, sd=20) |
| `PRLNAOFANWLG` | random-normal | normal (mean=5, sd=10) |
| `PRLNAOFANWUIT` | random-normal | normal (mean=0, sd=5) |
| `PRAOFHG` | random-normal | normal (mean=5, sd=10) |
| `PRAOFLG` | random-normal | normal (mean=3, sd=8) |
| `PRAOFUIT` | random-normal | normal (mean=0, sd=5) |
| `OPSLWKO` | random-normal | normal (mean=5, sd=15) |
| `PRLNWHKANW` | random-normal | normal (mean=10, sd=20) |
| `PRLNAWFANWUIT` | random-normal | normal (mean=0, sd=5) |
| `PRAWFUIT` | random-normal | normal (mean=0, sd=5) |
| `INDDEELNTIJDSPF` | codelist-hardcoded | codelist: INDICATOR_01 |

## vehtab

### vehtab

| Column | Level | Source |
|--------|-------|--------|
| `RINPERSOONSHKW` | constant | value: R |
| `RINPERSOONHKW` | spine-derived | spine.hh.RINPERSOON_Ref |
| `VEHP100WELVAART` | spine-derived | spine.hh.P100WELVAART |
| `VEHP100HVERM` | spine-derived | spine.hh.P100HVERM |
| `VEHW1000VERH` | spine-derived | spine.hh.VERMHH |
| `VEHW1100BEZH` | statline-calibrated | params: bezh_mean (83834NED) |
| `VEHW1110FINH` | statline-calibrated | params: finh_mean (83834NED) |
| `VEHW1111BANH` | statline-calibrated | params: banh_mean (83834NED) |
| `VEHW1112EFFH` | statline-calibrated | params: effh_mean (83834NED) |
| `VEHW1120ONRH` | statline-calibrated | params: onrh_mean (83834NED) |
| `VEHW1121WONH` | statline-calibrated | params: wonh_mean (83834NED) |
| `VEHW1122OGOH` | statline-calibrated | params: ogoh_mean (83834NED) |
| `VEHW1130ONDH` | statline-calibrated | params: ondh_mean (83834NED) |
| `VEHW1140ABEH` | statline-calibrated | params: abeh_mean (83834NED) |
| `VEHW1150OVEH` | statline-calibrated | params: oveh_mean (83834NED) |
| `VEHW1200STOH` | statline-calibrated | params: stoh_mean (83834NED) |
| `VEHW1210SHYH` | statline-calibrated | params: shyh_mean (83834NED) |
| `VEHW1220SSTH` | statline-calibrated | params: ssth_mean (83834NED) |
| `VEHW1230SOVH` | statline-calibrated | params: sovh_mean (83834NED) |
| `VEHWVEREXEWH` | statline-calibrated | params: verexewh_mean (83834NED) |

## energieverbruik

### energieverbruik

| Column | Level | Source |
|--------|-------|--------|
| `SOORTOBJECTNUMMER` | spine-derived | spine.obj.SOORTOBJECTNUMMER |
| `RINOBJECTNUMMER` | spine-derived | spine.obj.RINOBJECTNUMMER |
| `WONINGT` | constant | value:   |
| `WOONR` | constant | value:   |
| `STADSW` | statline-calibrated | params: stadsverwarming_categorical (Kerncijfers wijken en buurten) |
| `GAS` | statline-calibrated | params: gas_mean (Kerncijfers wijken en buurten) |
| `ELEK` | statline-calibrated | params: elek_mean (Kerncijfers wijken en buurten) |
| `GASBRON` | codelist-hardcoded | codelist: GASBRON |
| `ELEKBRON` | codelist-hardcoded | codelist: ELEKBRON |
| `ELEKTERUG` | random-normal | normal (mean=500, sd=1200) |
| `ELEKNETTO` | random-normal | normal (mean=2400, sd=1200) |
| `GASSJV` | random-normal | normal (mean=1100, sd=620) |
| `WARMTESCHATTING` | random-normal | normal (mean=35, sd=20) |
| `ZONPV` | statline-calibrated | params: solar_pv_categorical (Kerncijfers wijken en buurten) |
| `ZONVERMOGEN1JAN` | random-normal | normal (mean=2.5, sd=3) |
| `ZONVERMOGEN31DEC` | random-normal | normal (mean=2.8, sd=3.2) |
| `ZONPVBRON` | codelist-hardcoded | codelist: ZONPVBRON |
| `HOOFDVERWARMING31DEC` | codelist-hardcoded | codelist: HOOFDVERWARMING31DEC |
| `WONINGBEWONING10PROFIELEN` | codelist-hardcoded | codelist: WONINGBEWONING10PROFIELEN |
| `KBHOOFDVERWARMING31DEC` | codelist-hardcoded | codelist: KBHOOFDVERWARMING31DEC |

## gba

### adresobjectbus

| Column | Level | Source |
|--------|-------|--------|
| `RINPERSOONS` | spine-derived | spine.pers.RINPERSOONS |
| `RINPERSOON` | spine-derived | spine.pers.RINPERSOON |
| `SOORTOBJECTNUMMER` | spine-derived | spine.pers.SOORTOBJECTNUMMER |
| `RINOBJECTNUMMER` | spine-derived | spine.pers.RINOBJECTNUMMER |
| `GBADATUMAANVANGADRESHOUDING` | spine-derived | spine.pers.AanvangWoonduur |
| `GBADATUMEINDEADRESHOUDING` | constant | value: 99999999 |
| `GBAGEMEENTEVANINSCHRIJVING` | computed | computed.GemeenteCodeJJJJ1Jan |
| `GBAAANTALINGESCHREVENENOPNUMMERAANDUIDING` | random-normal | normal (mean=2.2, sd=1.5) |

### huishoudensbus

| Column | Level | Source |
|--------|-------|--------|
| `RINPERSOONS` | spine-derived | spine.pers.RINPERSOONS |
| `RINPERSOON` | spine-derived | spine.pers.RINPERSOON |
| `HUESSION` | spine-derived | spine.pers.HUISHOUDNR |
| `DAESSION` | spine-derived | spine.pers.DATUMAANVANGHH |
| `TYPHH` | spine-derived | spine.pers.TYPHH |
| `PLESSION` | spine-derived | spine.pers.PLHH |
| `AANESSION` | spine-derived | spine.pers.AantalPersonenPerHuishouden |
| `REFESSION` | spine-derived | spine.pers.REFPERSOONHH |

### persoontab

| Column | Level | Source |
|--------|-------|--------|
| `RINPERSOONS` | spine-derived | spine.pers.RINPERSOONS |
| `RINPERSOON` | spine-derived | spine.pers.RINPERSOON |
| `GBAGEBOORTEJAAR` | spine-derived | spine.pers.GBAGeboorteJaar |
| `GBAGEBOORTEMAAND` | random-uniform | uniform [1, 12] |
| `GBAGEBOORTELAND` | codelist-hardcoded | codelist: geboorteland |
| `GBAGESLACHT` | spine-derived | spine.pers.GBAGeslachtsAanduiding |
| `GBAAANTALOUDERSBUITENLAND` | codelist-hardcoded | codelist: aantalouders |
| `GBAGENERATIE` | codelist-hardcoded | codelist: generatie |
| `GBAHERKOMSTGROEPERING` | codelist-hardcoded | codelist: herkomstgroepering |
| `GBAGEBOORTELANDMOEDER` | codelist-hardcoded | codelist: geboorteland |
| `GBAGEBOORTELANDVADER` | codelist-hardcoded | codelist: geboorteland |
| `GBADATUMAANVANGHUIDIGVERBLIJF` | spine-derived | spine.pers.AanvangWoonduur |
| `GBADATUMVESTIGINGINNEDERLAND` | codelist-hardcoded | hardcoded probs |
| `GBADATUMOVERLIJDEN` | constant | value: 00000000 |
| `GBADATUMEMIGRATIE` | constant | value: 00000000 |
| `GBABURGERLIJKESTAAT` | spine-derived | spine.pers.GBABurgerlijkeStaat |

