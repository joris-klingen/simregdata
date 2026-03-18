# CBS Microdata Variable Reference

Comprehensive variable reference for CBS (Statistics Netherlands) microdata files. Extracted from official CBS PDF documentation. All descriptions are in the original Dutch unless otherwise noted. Variables with `{sfx}` (1Jan/31Dec) suffixes share the same definition for both reference dates.

---

## Woonbase

The Woonbase ("housing base") answers the question "Who lives where with whom?" It consists of key files (sleutelbestand), characteristic files (kenmerken), and population files (populatie). Available 2015--2024.

---

### WoonbaseSleutel (Sleutelbestand)

**Bus file linking persons, households, and dwellings.** Observation unit: person-household-dwelling spell. A new record is created whenever the relationship between the three entities changes.

| Variable | Type | Description | Codes/Values |
|---|---|---|---|
| RINPERSOONS | A1 | Indicator oorsprong persoon-id | `R`=In GBA |
| RINPERSOON | A9 | Persoon-id (pseudonymised) | Dimensionless 9-char ID |
| REFPERSOONHH | A1 | Is persoon referentiepersoon van huishouden? | `0`=Nee, `1`=Ja, `9`=Institutioneel huishouden |
| PLHH | A2 | Plaats persoon in huishouden | `1`=Thuiswonend kind, `2`=Alleenstaande, `3`=Partner niet-gehuwd paar z. kinderen, `4`=Partner gehuwd paar z. kinderen, `5`=Partner niet-gehuwd paar m. kinderen, `6`=Partner gehuwd paar m. kinderen, `7`=Ouder eenouderhuishouden, `8`=Ref.persoon overig HH, `9`=Overig lid, `10`=Lid institutioneel HH, `-`=Onbekend |
| HUISHOUDNR | A12 | Huishouden-id (samen met DATUMAANVANGHH) | Dimensionless 12-char ID |
| DATUMAANVANGHH | A8 | Aanvangsdatum huishouden (JJJJMMDD) | Date |
| TYPHH | A1 | Type huishouden | `-`=Onbekend, `1`=Eenpersoons, `2`=Niet-gehuwd paar z.k., `3`=Gehuwd paar z.k., `4`=Niet-gehuwd paar m.k., `5`=Gehuwd paar m.k., `6`=Eenouder, `7`=Overig, `8`=Institutioneel |
| IMPUTATIECODEHH | A1 | Huishouden geimputeerd? | `0`=Nee, `1`=Ja |
| SOORTOBJECTNUMMER | A1 | Herkomst object-id | `-`=Geen VBO, `B`=BAG, `H`=Historisch, `D`=GBA, `O`=Onbekend |
| RINOBJECTNUMMER | A32 | Object-id (pseudonymised) | Dimensionless 32-char ID |
| INVOORRAAD | A1 | VBO in voorraad woningen/niet-woningen? | `-`=Geen VBO, `0`=Niet in voorraad, `1`=In voorraad |
| VBOVOORRAADTYPE | A1 | Soort VBO in voorraad | `-`=Geen VBO, `0`=Woonfunctie, `1`=Niet-woonfunctie |
| BEGINGELDIGHEID | A8 | Ingangsdatum record (JJJJMMDD) | Date |
| EINDGELDIGHEID | A8 | Einddatum record (JJJJMMDD) | Date |
| REDENBEGINGELDIGHEID | A3 | Reden start record | `ADR`=Adreswijziging, `GEB`=Geboorte, `HH`=Huishoudenswijziging, `IMM`=Immigratie, `OBJ`=Wijziging VBO, `OPJ`=Object onbewoond toegevoegd, `OPN`=Administratief opgenomen, `V`=Verhuizing |
| REDENEINDGELDIGHEID | A3 | Reden einde record | `ADR`=Adreswijziging, `AFV`=Administratief afgevoerd, `EMI`=Emigratie, `HH`=Huishoudenswijziging, `IMM`=Immigratie, `NVT`=Niet van toepassing, `OBJ`=Wijziging VBO, `OPN`=Administratief opgenomen, `OVL`=Overlijden, `V`=Verhuizing |

---

### WoonbaseKenmerkenPersonen

**Characteristics of all persons in the Netherlands.** Observation unit: person. One record per person with attributes at both 1 Jan and 31 Dec.

| Variable | Type | Description | Codes/Values |
|---|---|---|---|
| RINPERSOON | A9 | Persoon-id | 9-char ID |
| RINPERSOONS | A1 | Indicator oorsprong persoon-id | `R`=In GBA |
| GBABurgerlijkeStaat{sfx} | A2 | Burgerlijke staat | `--`=Onbekend, `O`=Ongehuwd, `H`=Gehuwd, `P`=Partnerschap, `S`=Gescheiden na huwelijk, `SP`=Gescheiden na partnerschap, `W`=Verweduwd na huwelijk, `WP`=Verweduwd na partnerschap |
| GBAGeboorteJaar{sfx} | A4 | Geboortejaar | `----`=Onbekend, else 4-digit year |
| GBAGeslachtsAanduiding{sfx} | A1 | Geslacht | `-`=Onbekend, `1`=Man, `2`=Vrouw |
| GEMEENTECODEJJJJ{sfx} | A4 | Gemeentecode | 4-digit CBS municipality code |
| WIJKCODEJJJJ{sfx} | A6 | Wijkcode | 6-digit CBS district code |
| BUURTCODEJJJJ{sfx} | A8 | Buurtcode | 8-digit CBS neighbourhood code |
| PLHH{sfx} | A2 | Plaats persoon in huishouden | `1`--`10` (see Sleutel), `99`=Onbekend |
| RINOBJECTNUMMER{sfx} | A32 | Object-id | 32-char ID |
| SOORTOBJECTNUMMER{sfx} | A1 | Herkomst object-id | `-`=Geen VBO, `B`=BAG, `H`=Historisch, `D`=GBA, `O`=Onbekend |
| AanvangWoonduur{sfx} | A8 | Datum aanvang adresbewoning (JJJJMMDD) | Date. Note: earliest known date in 2015--2017 is 19950101 |
| OPLNIVSOI2016AGG4HBMETNIRWO{sfx} | A4 | Opleidingsniveau SOI2016 behaald (4-agg) | Education level codes (removed in later versions) |
| OPLNIVSOI2016AGG4HGMETNIRWO{sfx} | A4 | Opleidingsniveau SOI2016 gevolgd (4-agg) | Education level codes |
| OPLNIVSOI2021AGG4HBMETNIRWO{sfx} | A4 | Opleidingsniveau SOI2021 behaald (4-agg) | Education level codes |
| OPLNIVSOI2021AGG4HGMETNIRWO{sfx} | A4 | Opleidingsniveau SOI2021 gevolgd (4-agg) | Education level codes |
| GEWICHTHOOGSTEOPL{sfx} | F12.6 | Gewicht hoogste opleiding | Numeric weight |

---

### WoonbaseKenmerkenHuishoudens

**Characteristics of all households in the Netherlands.** Observation unit: household. One record per household with attributes at 1 Jan and 31 Dec.

| Variable | Type | Description | Codes/Values |
|---|---|---|---|
| HUISHOUDNR{sfx} | A12 | Huishouden-id | 12-char ID |
| DatumAanvangHH{sfx} | A8 | Aanvangsdatum huishouden (JJJJMMDD) | Date |
| IMPUTATIECODEHH{sfx} | A1 | Huishouden geimputeerd? | `0`=Nee, `1`=Ja |
| RefPersoonHH{sfx} | A1 | Persoon is referentiepersoon? | `0`=Nee, `1`=Ja, `9`=Institutioneel |
| RINPERSOON | A9 | Persoon-id referentiepersoon | 9-char ID |
| RINPERSOONS | A1 | Indicator oorsprong persoon-id | `R`=In GBA |
| TYPHH{sfx} | A1 | Type huishouden | See Sleutel TYPHH |
| AantalKinderenPerHuishouden{sfx} | A2 | Aantal thuiswonende kinderen | `--`=Geen kinderen, else count |
| AantalPersonenPerHuishouden{sfx} | A4 | Aantal personen in huishouden | Count |

---

### WoonbaseKenmerkenWoonruimten

**Characteristics of all dwellings (VBOs) and occupied stand/berth places in the Netherlands.** Observation unit: dwelling (verblijfsobject/stand-ligplaats). One record per VBO/SL.

| Variable | Type | Description | Codes/Values |
|---|---|---|---|
| RINOBJECTNUMMER | A32 | Object-id | 32-char ID |
| SOORTOBJECTNUMMER | A1 | Herkomst object-id | `-`=Geen VBO, `B`=BAG, `H`=Historisch, `D`=GBA, `O`=Onbekend |
| GEMEENTECODEJJJJ{sfx} | A4 | Gemeentecode | 4-digit CBS code |
| WIJKCODEJJJJ{sfx} | A6 | Wijkcode | 6-digit CBS code |
| BUURTCODEJJJJ{sfx} | A8 | Buurtcode | 8-digit CBS code |
| Indicator_VBOIsNieuwbouw | A1 | VBO is nieuwbouw in huidig jaar | `-`=Geen VBO, `0`=Nee, `1`=Ja |
| Indicator_VBOIsNieuwbouwJJJJ-1 | A1 | VBO is nieuwbouw in vorig jaar | `-`=Geen VBO, `0`=Nee, `1`=Ja |
| VSLSoort{sfx} | A1 | Soort verblijfplaats | `-`=Geen VSL, `1`=VBO in voorraad met woonfunctie, `2`=VBO in voorraad zonder woonfunctie, `3`=VBO niet in voorraad met woonfunctie, `4`=VBO niet in voorraad zonder woonfunctie, `5`=Bewoonde standplaats, `6`=Bewoonde ligplaats |
| VBOWoningType{sfx} | A2 | Woningtype | `00`=Eengezins onbekend, `01`=Vrijstaand, `02`=Twee-onder-een-kap, `03`=Hoekwoning, `04`=Tussenwoning, `05`=Meergezins (appartement), `99`=Onbekend |
| VBOBouwjaar{sfx} | A4 | Bouwjaar pand | 4-digit year, `----`=Onbekend |
| VBOOppervlakte{sfx} | A8 | Gebruiksoppervlakte (m2) | Integer m2, `--------`=Onbekend. Plausible range: 14--2700 m2 |
| VBOStatus{sfx} | A1 | Status VBO | `-`=Geen VBO, `1`=Gevormd, `2`=Niet gerealiseerd, `3`=In gebruik (niet ingemeten), `4`=In gebruik, `5`=Ingetrokken, `6`=Buiten gebruik |
| WOZWaardeObjectBAG{sfx} | F11 | WOZ-waarde in euro | Euros. `99999999999`=Onbekend. Taxatiepeildatum is t-1 |

---

### WoonbasePopulatiePersonen

**All persons with combined person, household, and dwelling characteristics.** Observation unit: person. One record per person at 1 Jan and 31 Dec.

| Variable | Type | Description | Codes/Values |
|---|---|---|---|
| RINPERSOON | A9 | Persoon-id | 9-char ID |
| RINPERSOONS | A1 | Indicator oorsprong | `R`=In GBA |
| RefPersoonHH{sfx} | A1 | Referentiepersoon? | `0`/`1`/`9` |
| HUISHOUDNR{sfx} | A12 | Huishouden-id | 12-char ID |
| DATUMAANVANGHH{sfx} | A8 | Aanvangsdatum HH | JJJJMMDD |
| IMPUTATIECODEHH{sfx} | A1 | Geimputeerd? | `0`/`1` |
| RINOBJECTNUMMER{sfx} | A32 | Object-id | 32-char ID |
| SOORTOBJECTNUMMER{sfx} | A1 | Herkomst object-id | See above |
| Indicator_PersoonIsGeboren | A1 | Geboren gedurende jaar | `0`/`1` |
| Indicator_PersoonIsOverleden | A1 | Overleden gedurende jaar | `0`/`1` |
| Indicator_PersoonIsGeemigreerd | A1 | Geemigreerd gedurende jaar | `0`/`1` |
| Indicator_PersoonIsAdministratiefAfgevoerd | A1 | Administratief afgevoerd | `0`/`1` |
| Indicator_PersoonIsGeimmigreerd | A1 | Geimmigreerd gedurende jaar | `0`/`1` |
| Indicator_PersoonIsAdministratiefOpgenomen | A1 | Administratief opgenomen | `0`/`1` |
| Indicator_PersoonIsVerhuisd | A1 | Verhuisd gedurende jaar | `0`/`1` |
| Indicator_PersoonIsAanwezig{sfx} | A1 | Aanwezig op peildatum | `0`/`1` |
| AantalKeerVerhuisd | A2 | Aantal keer verhuisd in jaar | Count |
| PLHH{sfx} | A2 | Plaats in huishouden | See Sleutel PLHH |
| TYPHH{sfx} | A1 | Type huishouden | See Sleutel TYPHH |
| GBAGeslachtsAanduiding{sfx} | A1 | Geslacht | `1`=Man, `2`=Vrouw |
| GBAGeboorteJaar{sfx} | A4 | Geboortejaar | 4-digit year |
| GBABurgerlijkeStaat{sfx} | A2 | Burgerlijke staat | See KenmerkenPersonen |
| AantalPersonenPerHuishouden{sfx} | A4 | Huishoudensgrootte | Count |
| GemeenteCodeJJJJ{sfx} | A4 | Gemeentecode | 4-digit CBS code |
| VSLSoort{sfx} | A1 | Soort verblijfplaats | See KenmerkenWoonruimten |
| TypeEigenaar{sfx} | A1 | Type eigenaar woning | `C`=Corporatie, `V`=Overige verhuurder, `E`=Eigenaar-bewoner, `O`=Onbekend, `9`=Niet van toepassing |
| VBOWoningType{sfx} | A2 | Woningtype | See KenmerkenWoonruimten |
| VBOBouwJaarKlasse{sfx} | A4 | Bouwjaarklasse | Class codes (e.g. period ranges) |
| VBOOppervlakteKlasse{sfx} | A1 | Oppervlakteklasse | Size class code |
| WOZWaardeObjectBAGKlasse{sfx} | A1 | WOZ-waardeklasse | Value class code |

---

### WoonbasePopulatieHuishoudens

**All households with combined household, person (ref.person), and dwelling characteristics.** Observation unit: household. One record per household.

| Variable | Type | Description | Codes/Values |
|---|---|---|---|
| HUISHOUDNR{sfx} | A12 | Huishouden-id | 12-char ID |
| DATUMAANVANGHH{sfx} | A8 | Aanvangsdatum HH | JJJJMMDD |
| IMPUTATIECODEHH{sfx} | A1 | Geimputeerd? | `0`/`1` |
| RINPERSOONS | A1 | Indicator oorsprong ref.persoon | `R` |
| RINPERSOON | A9 | Persoon-id ref.persoon | 9-char ID |
| RINOBJECTNUMMER{sfx} | A32 | Object-id | 32-char ID |
| SOORTOBJECTNUMMER{sfx} | A1 | Herkomst object-id | See above |
| TYPHH{sfx} | A1 | Type huishouden | See Sleutel |
| AantalPersonenPerHuishouden{sfx} | A4 | Huishoudensgrootte | Count |
| AantalKinderenPerHuishouden{sfx} | A2 | Aantal kinderen | `--`=Geen |
| LeeftijdRefPersoon{sfx} | A3 | Leeftijd referentiepersoon | Age in years |
| PLHHRefPersoon{sfx} | A2 | PLHH referentiepersoon | See PLHH codes |
| GBAGeslachtsaanduidingRefPersoon{sfx} | A1 | Geslacht referentiepersoon | `1`=Man, `2`=Vrouw |
| GemeenteCodeJJJJ{sfx} | A4 | Gemeentecode | 4-digit CBS code |
| VSLSoort{sfx} | A1 | Soort verblijfplaats | See KenmerkenWoonruimten |
| WOZWaardeObjectBAGKlasse{sfx} | A1 | WOZ-waardeklasse | Value class code |
| VBOBouwJaarKlasse{sfx} | A4 | Bouwjaarklasse | Period class |
| VBOOppervlakteKlasse{sfx} | A1 | Oppervlakteklasse | Size class |
| VBOWoningType{sfx} | A2 | Woningtype | See KenmerkenWoonruimten |
| TypeEigenaar{sfx} | A1 | Type eigenaar | See PopulatiePersonen |
| Indicator_HHIsAanwezig{sfx} | A1 | Huishouden aanwezig op peildatum | `0`/`1` |

---

### WoonbasePopulatieWoonruimten

**All dwellings with combined dwelling, household, and person (ref.person) characteristics.** Observation unit: dwelling (VBO/SL). One record per VBO/SL.

| Variable | Type | Description | Codes/Values |
|---|---|---|---|
| SOORTOBJECTNUMMER | A1 | Herkomst object-id | See above |
| RINOBJECTNUMMER | A32 | Object-id | 32-char ID |
| PandID{sfx} | A32 | Pand-id (encrypted) | 32-char ID |
| VSLSoort{sfx} | A1 | Soort verblijfplaats | See KenmerkenWoonruimten |
| HUISHOUDNR{sfx} | A12 | Huishouden-id | 12-char ID |
| DATUMAANVANGHH{sfx} | A8 | Aanvangsdatum HH | JJJJMMDD |
| RINPERSOONS_Ref{sfx} | A1 | Indicator ref.persoon | `R` |
| RINPERSOON_Ref{sfx} | A9 | Persoon-id ref.persoon | 9-char ID |
| VBOWoningType{sfx} | A2 | Woningtype | See KenmerkenWoonruimten |
| VBOBouwJaarKlasse{sfx} | A4 | Bouwjaarklasse | Period class |
| VBOOppervlakteKlasse{sfx} | A1 | Oppervlakteklasse | Size class |
| WOZWaardeObjectBAGKlasse{sfx} | A1 | WOZ-waardeklasse | Value class |
| TypeEigenaar{sfx} | A1 | Type eigenaar | See PopulatiePersonen |
| AantalPersonenPerVSLKlasse{sfx} | A4 | Aantal personen per VSL (klasse) | Count class |
| AantalHuishoudensPerVSLKlasse{sfx} | A1 | Aantal huishoudens per VSL (klasse) | Count class |
| AantalKinderenPerVSL{sfx} | A2 | Aantal kinderen per VSL | Count |
| LeeftijdJongsteKindPerVSL{sfx} | A2 | Leeftijd jongste kind per VSL | Age |
| TYPHH{sfx} | A1 | Type huishouden | See Sleutel |
| GemeenteCodeJJJJ{sfx} | A4 | Gemeentecode | 4-digit CBS code |
| Indicator_VBOIsAanwezig{sfx} | A1 | VBO aanwezig op peildatum | `0`/`1` |
| Indicator_VSLIsAanwezig{sfx} | A1 | VSL aanwezig op peildatum | `0`/`1` |
| Indicator_VBOIsGesloopt | A1 | VBO gesloopt gedurende jaar | `0`/`1` |
| Indicator_VSLIsOntrokken | A1 | VSL onttrokken gedurende jaar | `0`/`1` |
| Indicator_VBOIsTransformatie | A1 | VBO is transformatie | `0`/`1` |
| Indicator_VBOIsNieuwbouw | A1 | VBO is nieuwbouw | `0`/`1` |
| Indicator_VSLIsNieuw | A1 | VSL is nieuw | `0`/`1` |

---

### WOONBASEEKHuishoudensWv (Extra Kenmerken Huishoudens Welvaart)

**Income and wealth characteristics of private households.** Observation unit: private household (identified by RINPERSOONS + RINPERSOON of reference person). Available 2018--2024. Income data refer to year T (for 1Jan) or T+1 (for 31Dec); wealth data refer to the reference date itself.

All variables below exist with both `1JAN` and `31DEC` suffixes. Only the `1JAN` variant is listed.

| Variable | Type | Description | Codes/Values |
|---|---|---|---|
| RINPERSOONS | A1 | Indicator oorsprong persoon-id | `R`=In GBA |
| RINPERSOON | A9 | Persoon-id referentiepersoon | 9-char ID |
| AGHT | F1 | Aandachtsgroep huurtoeslag | `1`=Inkomen t/m norminkomen, `2`=Inkomen tussen norm en max. subsidiabele huur, `3`=Niet aandachtsgroep |
| AGIAH | F1 | Aandachtsgroep inkomensafhankelijk huurbeleid | `1`=Geen extra huurverhoging, `2`=Beperkte extra huurverhoging, `3`=Maximale extra huurverhoging |
| AGTSH | F1 | Aandachtsgroep toewijzing sociale huurwoning | `1`=Laagste inkomens, `2`=Middeninkomens, `3`=Niet aandachtsgroep |
| AOWHT | F1 | Oudste lid heeft AOW-leeftijd bereikt | `0`=Nee, `1`=Ja |
| ARMOEDE | F3 | Inkomen t.o.v. armoedegrens (%) | `1`--`500`=percentage (afgekapt), `991`=Vermogen boven grens + inkomen onder grens, `992`=Vermogen en inkomen boven grens, `998`=Studentenhuishouden, `999`=Institutioneel/zonder waarneming |
| ARMSOC | F3 | Inkomen t.o.v. beleidsmatig minimum (%) | `-3`=Studentenhuishouden, `-2`=Institutioneel, `-1`=Onbekend inkomen, `1`--`999`=percentage (afgekapt) |
| BBIHJ | F2 | Belangrijkste inkomensbron huishouden | `11`=Loon, `12`=Loon DGA, `13`=Winst zelfstandig ondernemer, `14`=Inkomen overige zelfstandige, `21`=WW, `22`=Bijstand, `23`=Sociale voorziening overig, `24`=Ziekte/AO, `25`=Pensioen, `26`=Studiefinanciering, `30`=Inkomen uit vermogen |
| BELIAGHT | F11 | Toetsingsinkomen huurtoeslag (euro) | Euro amount |
| BELIAGIAH | F11 | Toetsingsinkomen inkomensafh. huurbeleid (euro, woningniveau) | Euro amount |
| BELIAGTSH | F11 | Toetsingsinkomen toewijzing sociale huurwoning (euro) | Euro amount |
| BELIH | F11 | Belastbaar inkomen huishouden (euro, box 1+2+3) | Euro amount |
| BESTINKH | F11 | Besteedbaar inkomen huishouden (euro) | Euro amount |
| BETAALBUDGET | F11 | Betaalbudget (besteedbaar inkomen excl. lasten-gerelateerde componenten) | Euro amount |
| BETAALRESERVE | F11 | Betaalreserve (bezittingen excl. eigen woning, excl. negatief) | Euro amount |
| CORBETAALBUDGET | F1 | Correctie betaalbudget lage inkomens | `0`=Niet gecorrigeerd, `1`=Gecorrigeerd tot minimum |
| EHALGR | F2 | Woningbezit (eigen woning / huurwoning) | `10`=Eigen woning, `21`=Huurwoning zonder huurtoeslag, `22`=Huurwoning met huurtoeslag |
| GESTINKH | F11 | Gestandaardiseerd besteedbaar inkomen huishouden (euro) | Euro amount |
| LEERGROND | F11 | Toetsingsinkomen voor hypothecair krediet (euro) | Euro amount |
| P100HBEST | F3 | Percentielgroep besteedbaar inkomen | `1`=Laagste, `100`=Hoogste |
| P100HGEST | F3 | Percentielgroep gestandaardiseerd inkomen | `1`=Laagste, `100`=Hoogste |
| P100HVERM | F3 | Percentielgroep vermogen | `1`=Laagste, `100`=Hoogste |
| P100WELVAART | F3 | Percentielgroep welvaart (inkomen + vermogen) | `1`=Laagste, `100`=Hoogste |
| POPFEC | F1 | Populatie financieel-economische component | `1`=Particulier HH met inkomen begin jaar, `2`=Particulier HH met inkomen eind jaar, `3`=Institutioneel HH |
| POPIIV | F1 | Populatie inkomen/vermogen | Population indicator |
| POPIIVWONING | F2 | Populatie inkomen/vermogen + woning | Population indicator |
| VERMHH | F11 | Vermogen huishouden (euro) | Euro amount |
| VROMHH | F11 | Vermogen onroerend goed huishouden (euro) | Euro amount |
| W1000VERH | F11 | Vermogen huishouden (1000-tallen) | Euro amount / 1000 |
| VERSCHILIIV | F1 | Verschil huishoudenssamenstelling IIV | `0`/`1` |

---

### WoonbaseEKWoonruimtenPand (Extra Kenmerken Woonruimten Panden)

**Building (pand) characteristics for buildings with at least one VBO in stock.** Observation unit: pand. Available 2015--2024. Links to VBOs via PandID in PopulatieWoonruimten.

All variables with {sfx} exist at both 1Jan and 31Dec.

| Variable | Type | Description | Codes/Values |
|---|---|---|---|
| PandID | A32 | Encrypted pand-id | 32-char ID |
| PandAantalVbos{sfx} | F4 | Aantal VBOs in voorraad in pand | Count |
| PandAantalWoning{sfx} | F4 | Aantal woningen (VBOs met woonfunctie) in pand | Count |
| PandAantalNietWoning{sfx} | F4 | Aantal niet-woningen in pand | Count |
| PandOppTotWoning{sfx} | F6 | Totale oppervlakte woningen in pand (m2) | m2 (plausibel: 14--2700 per VBO) |
| PandOppTotNietWoning{sfx} | F6 | Totale oppervlakte niet-woningen in pand (m2) | m2 |
| PandOppGemWoning{sfx} | F4 | Gemiddelde oppervlakte woningen in pand (m2) | m2 |
| PandOppGemNietWoning{sfx} | F4 | Gemiddelde oppervlakte niet-woningen in pand (m2) | m2 |
| PandWinkelfunctie{sfx} | A1 | Pand bevat VBO met winkelfunctie (excl. woonfunctie)? | `-`=Geen VBOs, `0`=Nee, `1`=Ja |
| PandKantoorfunctie{sfx} | A1 | Pand bevat VBO met kantoorfunctie? | `-`/`0`/`1` |
| PandIndustriefunctie{sfx} | A1 | Pand bevat VBO met industriefunctie? | `-`/`0`/`1` |
| PandBijeenkomstfunctie{sfx} | A1 | Pand bevat VBO met bijeenkomstfunctie? | `-`/`0`/`1` |
| PandGezondheidszorgfunctie{sfx} | A1 | Pand bevat VBO met gezondheidszorgfunctie? | `-`/`0`/`1` |
| PandAnderefunctie{sfx} | A1 | Pand bevat VBO met andere functie (cel/logies/onderwijs/sport/overig)? | `-`/`0`/`1` |
| PandTransformatie{sfx} | A1 | Pand bevat woningen ontstaan uit pandtransformatie vorig jaar? | `-`/`0`/`1` |
| PandHoogte | F3 | 70e percentielhoogte pand (meters boven maaiveld) | Meters (2--300). From 3D-BAG/AHN |
| PandAantalVerdiepingen | F2 | Aantal verdiepingen pand | Count. From 3D-BAG |
| PandDaktype | A1 | Daktype pand | Categorical. From 3D-BAG |

---

## RDW (Dienst Wegverkeer)

Vehicle registration data from the Dutch Road Transport Authority.

---

### RDWNPACTTAB

**Motor vehicle fleet with vehicle characteristics at licence plate level.** Observation unit: vehicle (kenteken). Peildatum: 1 January. Available 2010--2025. Contains active fleet, business stock, and dropped vehicles (personenauto's only for the latter two).

| Variable | Type | Description | Codes/Values |
|---|---|---|---|
| RINPERSOONS | A1 | Indicator oorsprong persoon-id | `K`=Niet in GBA (kentekens), `R`=Wel in GBA, `S`=Niet in GBA wel Sofinr |
| RINPERSOON | A9 | Persoon-id eigenaar | 9-char ID |
| RINKENTEKEN | A32 | Versleuteld kenteken | 32-char encrypted licence plate |
| KLEURCODEVRTG | A2 | Kleur voertuig | `00`=Oranje, `01`=Rose, `02`=Rood, `03`=Wit, `04`=Blauw, `05`=Groen, `06`=Geel, `07`=Grijs, `08`=Bruin, `09`=Beige, `10`=Creme, `11`=Paars, `12`=Zwart, `13`=Diversen, `99`=NVT, `--`=Onbekend. Only for personenauto's |
| EERSTETOELDAT1VRTG | A4 | Jaar eerste toelating voertuig | 4-digit year (JJJJ) |
| SRTREFVRTG | A1 | Soort referentie (eigenaar) | `B`=Erkend bedrijf, `I`=Importeur, `N`=Natuurlijk persoon, `R`=Rechtspersoon, `H`=Handelaar |
| VRTGSOORT | A1 | Soort voertuig | `-`=Onbekend, `0`=Bromfiets actief, `1`=Bestelauto actief, `2`=Vrachtwagen actief, `3`=Trekker actief, `4`=Speciaal voertuig actief, `5`=Autobus actief, `6`=Personenauto actief, `7`=Motorfiets actief, `8`=Aanhanger actief, `9`=Oplegger actief, `A`=Bestelauto uitval, `B`=Vrachtwagen uitval, `C`=Trekker uitval, `D`=Speciaal voertuig uitval, `E`=Autobus uitval, `F`=Personenauto uitval, `K`--`T`=Bedrijfsvoorraad (diverse) , `P`=Personenauto bedrijfsvoorraad, `Q`=Motorfiets bedrijfsvoorraad |
| BRANDSTCODECORVRTG | A1 | Brandstoftype voertuig | `1`=Benzine, `2`=Diesel, `3`=LPG, `4`=Elektriciteit, `5`=CNG (aardgas), `6`=Waterstof, `7`=Alcohol, `8`=Cryogeen, `9`=Hybride (pre-2016), `A`=Plug-in hybride (PHEV), `B`=Hybride (HEV) |
| MASSALEEGCORVRTG | F5 | Ledige massa voertuig (kg) | Kg. Not filled for motorfiets |
| MAXLAADVERMCORVRTG | F5 | Maximaal laadvermogen (kg) | Kg. Not filled for personenauto, trekker, autobus, motor, bromfiets |
| AANTALCYLCORVRTG | F2 | Aantal cilinders | Count. `0` for wankel/electric. Not filled for bromfiets/aanhanger/oplegger |
| CYLININHOUDCORVRTG | F4 | Cilinderinhoud (cc) | Cubic cm. `0` for electric. Only filled for motorfiets |
| SOORTBROMFIETSCOR | A2 | Soort bromfiets | `01`=Snorfiets, `02`=Bromfiets, `03`=Brommobiel, `04`=Overig. Only for voertuigsoort bromfiets |

---

### VERKEERSPRESTATIETAB

**Traffic performance of passenger cars with vehicle kilometres travelled (VKT).** Observation unit: vehicle (kenteken). Annual data. Available 2010--2024. Only natural persons' cars; company/lease cars excluded.

| Variable | Type | Description | Codes/Values |
|---|---|---|---|
| RINKENTEKEN | A32 | Versleuteld kenteken | 32-char encrypted licence plate |
| RinpersoonsVP | A1 | Indicator oorsprong persoon-id | `K`=Niet in GBA (RDW), `R`=Wel in GBA, `S`=Niet in GBA wel Sofinr |
| RinpersoonVP | A9 | Persoon-id eigenaar | 9-char ID. May be empty if no owner found |
| VPGEWICHT | F16.5 | Ophooggewicht verkeersprestaties | Weight factor. Must always be applied. Higher in 2010--2011 (sample-based) |
| VPDGNWEG | F3 | Aantal dagen voertuig op de weg | Days (0--366). 365/366 for full-year vehicles |
| VPJAARKM | F10.2 | Jaarkilometrage voertuig (km) | Km per year. Always weight with VPGEWICHT |

---

## SPOLIS (Polisadministratie)

Employment records from the insurance administration.

---

### SPOLISBUS

**Employment spells (jobs) at month level.** Observation unit: person-job-month. Contains wages, hours, days, and job characteristics. Available 2010--present. One of the largest CBS microdata files (~133 variables).

Note: The SPOLIS PDF documentation is very extensive (133 variables). Below is the complete variable list.

**Numeric wage/hours variables (F-type):**

| Variable | Type | Description | Codes/Values |
|---|---|---|---|
| RINPERSOONS | A1 | Indicator oorsprong persoon-id | `R`=In GBA |
| RINPERSOON | A9 | Persoon-id | 9-char ID |
| IKVID | A32 | Inkomensverhouding-id (job ID) | 32-char encrypted ID |
| SDATUMAANVANGIKO | A8 | Startdatum inkomensverhouding oorspronkelijk (JJJJMMDD) | Date |
| SDATUMEINDEIKO | A8 | Einddatum inkomensverhouding oorspronkelijk (JJJJMMDD) | Date |
| SAANTSV | F10.2 | Aantal SV-dagen | Count |
| SAANTVERLU | F10.2 | Aantal verlofuren | Hours |
| SAUTOZAAK | F10 | Bijtelling prive-gebruik auto | Euro |
| SBAANDAGEN | F2 | Aantal baandagen in tijdvak | Days (1--31) |
| SBASISLOON | F10 | Basisloon (SV-loon) | Euro |
| SBASISUREN | F8.2 | Basisuren (betaalde uren) | Hours |
| SBEDRALINWWB | F10.2 | Bedrag alimentatie/WWB | Euro |
| SBEDRRCHTAL | F10.2 | Bedrag rechten alimentatie | Euro |
| SBEDRZDAFTR | F10.2 | Bedrag ziektedagen aftrek | Euro |
| SBIJDRZVW | F10.2 | Bijdrage Zvw | Euro |
| SBIJZONDEREBELONING | F10 | Bijzondere beloning | Euro |
| SEXTRSAL | F10 | Extra salaris | Euro |
| SINCIDENTSAL | F10 | Incidenteel salaris | Euro |
| SINGLBPH | F10 | Ingehouden loonbelasting/premie volksverzekeringen | Euro |
| SLNINGLD | F10 | Loon in geld | Euro |
| SLNLBPH | F10 | Loon voor loonbelasting/premie volksverzekeringen | Euro |
| SLNOWRK | F10 | Loon overwerk | Euro |
| SLNSV | F10 | Loon SV | Euro |
| SLNTABBB | F10 | Loon tabel bijzondere beloningen | Euro |
| SLVLPREG | F10 | Loonvoordeel premieregeling | Euro |
| SLVLPREGTOEG | F10 | Loonvoordeel premieregeling toegekend | Euro |
| SOPGRCHTEXTRSAL | F10 | Opgebouwd recht extra salaris | Euro |
| SOPGRCHTVAKBSL | F10 | Opgebouwd recht vakantie-bijslag | Euro |
| SOVERWERKUREN | F8.2 | Overwerkuren | Hours |
| SPENSIOENPREMIE | F10 | Pensioenpremie werknemer | Euro |
| SPRAWF | F10.2 | Premie AWf (werkloosheidsfonds) | Euro |
| SPRUFO | F10.2 | Premie Ufo | Euro |
| SPRWAOAOF | F10.2 | Premie WAO/AOF | Euro |
| SPRWAOAOK | F10.2 | Premie WAO/AOK | Euro |
| SPRWGF | F10.2 | Premie WGA-flex | Euro |
| SREGULIEREUREN | F8.2 | Reguliere uren | Hours |
| SREISK | F10.2 | Reiskostenvergoeding | Euro |
| SVAKBSL | F10 | Vakantie-bijslag | Euro |
| SVERGZVW | F10 | Vergoeding Zvw | Euro |
| SVERRARBKRT | F10.2 | Verrekende arbeidskorting | Euro |
| SVERSTRAANV | F10.2 | Verstrekking/aanvulling | Euro |
| SVOLTIJDDAGEN | F6.2 | Voltijddagen | Days |
| SWGBIJDRKO | F10 | Werkgeversbijdrage kinderopvang | Euro |
| SWRDLN | F10 | Waardeoverdracht loon | Euro |
| SWRDPRGEBRAUT | F10 | Waarde privgebruik auto | Euro |
| SWRKNBIJDRAUT | F10 | Werknemersbijdrage auto | Euro |
| SPRWGAWHK | F10.2 | Premie WGA WHK | Euro |
| SWGHZVW | F10.2 | Werkgeversbijdrage Zvw | Euro |
| SPRGEDIFFWHK | F10.2 | Premie gedifferentieerd WHK | Euro |
| SCTRCTLN | F12.2 | Contractloon | Euro |
| SAANTCTRCTURENPWK | F6.2 | Aantal contracturen per week | Hours |
| SBEDRRNTKSTVPERSL | F10.2 | Bedrag rente kosten versleuteld | Euro |
| SModelramingPensioenpremieWn | F10.2 | Modelraming pensioenpremie werknemer | Euro |
| SModelramingPensioenpremieWg | F10.2 | Modelraming pensioenpremie werkgever | Euro |
| SModelramingVutpremieWn | F10.2 | Modelraming VUT-premie werknemer | Euro |
| SModelramingVutpremieWg | F10.2 | Modelraming VUT-premie werkgever | Euro |
| SModelramingSFpremieWg | F10.2 | Modelraming SF-premie werkgever | Euro |
| PRLNUFO | F10.2 | Premieloon Ufo | Euro |
| PRLNAWFANWLg | F10.2 | Premieloon AWf ANW laag | Euro |
| PRLNAWFANWHg | F10.2 | Premieloon AWf ANW hoog | Euro |
| PRLNAWFANWHz | F10.2 | Premieloon AWf ANW hoog zelfstandig | Euro |
| PrAwfLg | F10.2 | Premie AWf laag | Euro |
| PrAwfHg | F10.2 | Premie AWf hoog | Euro |
| PrAwfHz | F10.2 | Premie AWf hoog zelfstandig | Euro |
| OPBAVWB | F10.2 | Opbouw AVW bedrag | Euro |
| OPNAVWB | F10.2 | Opname AVW bedrag | Euro |
| PRLNAOFANWHG | F10.2 | Premieloon AOF ANW hoog | Euro |
| PRLNAOFANWLG | F10.2 | Premieloon AOF ANW laag | Euro |
| PRLNAOFANWUIT | F10.2 | Premieloon AOF ANW uitkering | Euro |
| PRAOFHG | F10.2 | Premie AOF hoog | Euro |
| PRAOFLG | F10.2 | Premie AOF laag | Euro |
| PRAOFUIT | F10.2 | Premie AOF uitkering | Euro |
| OPSLWKO | F10.2 | Opslag WKO | Euro |
| PRLNWHKANW | F10.2 | Premieloon WHK ANW | Euro |
| PRLNAWFANWUIT | F10.2 | Premieloon AWf ANW uitkering | Euro |
| PRAWFUIT | F10.2 | Premie AWf uitkering | Euro |

**Categorical variables (A-type):**

| Variable | Type | Description | Codes/Values |
|---|---|---|---|
| SCAO_crypt | A32 | CAO-code (versleuteld) | Encrypted CAO identifier |
| SCDAARD | A2 | Code aard arbeidsverhouding | 2-digit code |
| SCDAGH | A1 | Code aard gegevens herleiding | Single char |
| SCDINCINKVERM | A1 | Code incidenteel inkomen/vermogen | Single char |
| SCDINVLVPL1 | A1 | Code invloed verzekeringsplicht 1 | Single char |
| SCDINVLVPL2 | A1 | Code invloed verzekeringsplicht 2 | Single char |
| SCDINVLVPL3 | A1 | Code invloed verzekeringsplicht 3 | Single char |
| SCDRDNGNBIJT | A1 | Code reden geen bijtelling | Single char |
| SCDZVW | A1 | Code ZVW | Single char |
| SCONTRACTSOORT | A1 | Contractsoort | Single char |
| SDATUMAANVANGIKVORG | A8 | Datum aanvang IKV oorspronkelijk | JJJJMMDD |
| SFSINDFZ | A2 | FS-indicatie flexibele zaak | 2-char code |
| SINDLHKORT | A1 | Indicatie loonheffingskorting | Single char |
| SINDSA03 | A1 | Indicatie SA03 | Single char |
| SINDSA43 | A1 | Indicatie SA43 | Single char |
| SINDSA71 | A1 | Indicatie SA71 | Single char |
| SINDSA72 | A1 | Indicatie SA72 | Single char |
| SINDVAKBN | A1 | Indicatie vakantie-bon | Single char |
| SINDZW | A1 | Indicatie Ziektewet | Single char |
| SINLEGLEVENSLOOP | A1 | Inleg levensloop | Single char |
| SOVERWERK | A1 | Indicatie overwerk | Single char |
| SPOLISDIENSTVERBAND | A1 | Polisdienstverband | Single char |
| SRISGRP | A2 | Risicogroep | 2-char code |
| SSRTIV | A2 | Soort inkomensverhouding | 2-char code |
| SWEKARBDUURKLASSE | A1 | Wekelijkse arbeidsduur klasse | Single char |
| SARBEIDSRELATIE | A1 | Arbeidsrelatie | Single char |
| SAUTOVANDEZAAK | A1 | Auto van de zaak | Single char |
| SBEID | A8 | Bedrijfs-id (encrypted) | 8-char ID |
| SCAOSECTOR | A4 | CAO-sector | 4-char code |
| SDATUMAANVANGIKV | A8 | Datum aanvang IKV (JJJJMMDD) | Date |
| SDATUMEINDEIKV | A8 | Datum einde IKV (JJJJMMDD) | Date |
| SINDWAO | A1 | Indicatie WAO | Single char |
| SINDWW | A1 | Indicatie WW | Single char |
| SLBTAB | A3 | Loonbelastingtabel | 3-char code |
| SLHNR_crypt | A32 | Loonheffingsnummer (versleuteld) | 32-char encrypted |
| SSECT | A2 | Sector | 2-char code |
| SSOORTBAAN | A1 | Soort baan | Single char |
| STIJDVAKTYPE | A1 | Tijdvaktype | Single char |
| SINDTIJDHK | A1 | Indicatie tijdelijke heffingskorting | Single char |
| SIMPUTATIE | A1 | Indicatie imputatie | Single char |
| SINDPRKJONGRWEN | A1 | Indicatie premiekorting jongere werknemers | Single char |
| SINDPKAGH | A1 | Indicatie premiekorting AGH | Single char |
| SINDPKNWARBVOUDWN | A1 | Indicatie premiekorting nieuwe arbeidsverhouding werknemer | Single char |
| SINDPMA | A1 | Indicatie premie mobiliteitsbonus arbeidsgeh. | Single char |
| SINDWAARNEMING | A1 | Indicatie waarneming | Single char |
| SIndAvrLkvOudrWn | A1 | Indicatie AVR LKV oudere werknemer | Single char |
| SIndAvrLkvAgWn | A1 | Indicatie AVR LKV AG werknemer | Single char |
| SIndAvrLkvDgBafSb | A1 | Indicatie AVR LKV doelgroep banenafspraak | Single char |
| SIndAvrLkvHpAgWn | A1 | Indicatie AVR LKV herplaatsing AG werknemer | Single char |
| CdRdnEindArbov | A2 | Code reden einde arbeidsverhouding | 2-char code |
| CdCaoInl_crypt | A32 | CAO-code inleen (versleuteld) | 32-char encrypted |
| IndArbovOnbepTd | A1 | Indicatie arbeidsovereenkomst onbepaalde tijd | Single char |
| IndSchriftArbov | A1 | Indicatie schriftelijke arbeidsovereenkomst | Single char |
| IndOprov | A1 | Indicatie oproepovereenkomst | Single char |
| IndJrurennrm | A1 | Indicatie jaarurennorm | Single char |
| INDPUBAANONBEPTD | A1 | Indicatie publiekrechtelijke aanstelling onbepaalde tijd | Single char |
| INDDEELNTIJDSPF | A1 | Indicatie deelname tijdspaarfonds | Single char |

---

## VEHTAB (Vermogens van huishoudens)

Household wealth data from tax and financial institution records.

---

### VEHTAB

**Household wealth (assets and liabilities).** Observation unit: household (identified by RINPERSOONSHKW + RINPERSOONHKW = primary earner). Data at 1 January of reporting year. Available 2006--2024. `99999999999` means income/wealth unknown.

| Variable | Type | Description | Codes/Values |
|---|---|---|---|
| RINPERSOONSHKW | A1 | Indicator oorsprong HKW persoon-id | `F`=Niet in GBA niet Sofinr, `R`=Wel in GBA, `S`=Niet in GBA wel Sofinr |
| RINPERSOONHKW | A9 | Persoon-id hoofdkostwinner (= huishouden-id) | 9-char ID |
| VEHP100WELVAART | F3 | Percentielgroep welvaart | `-1`=Onbekend inkomen, `-2`=Institutioneel, `1`--`100`=percentiel |
| VEHP100HVERM | F3 | Percentielgroep vermogen | `-1`=Onbekend inkomen, `-2`=Institutioneel, `1`--`100`=percentiel |
| VEHW1000VERH | F11 | Totaal vermogen huishouden | Euro. Bezittingen minus schulden |
| VEHW1100BEZH | F11 | Totaal bezittingen | Euro. Kan negatief zijn (door ondernemingsvermogen) |
| VEHW1110FINH | F11 | Financiele bezittingen | Euro. Bank/spaar + effecten |
| VEHW1111BANH | F11 | Bank- en spaartegoeden | Euro. Incl. buitenlandse tegoeden. Completere waarneming vanaf 2011 |
| VEHW1112EFFH | F11 | Effecten (obligaties + aandelen excl. aanm. belang) | Euro |
| VEHW1120ONRH | F11 | Onroerend goed totaal | Euro. Eigen woning + overig |
| VEHW1121WONH | F11 | Eigen woning | Euro. Op basis van WOZ-waarde |
| VEHW1122OGOH | F11 | Overig onroerend goed (2e woning, beleggingspanden) | Euro |
| VEHW1130ONDH | F11 | Ondernemingsvermogen | Euro. Saldo bezittingen/schulden bedrijf |
| VEHW1140ABEH | F11 | Aanmerkelijk belang | Euro. Aandeel >= 5% in vennootschap |
| VEHW1150OVEH | F11 | Overige bezittingen (contant geld, roerende zaken als belegging) | Euro |
| VEHW1200STOH | F11 | Totaal schulden | Euro. Hypotheek + studie + overig |
| VEHW1210SHYH | F11 | Hypotheekschuld eigen woning (netto, incl. opgebouwd tegoed) | Euro |
| VEHW1220SSTH | F11 | Studieschuld (WSF/DUO) | Euro. Apart waargenomen vanaf 2011 |
| VEHW1230SOVH | F11 | Overige schulden (consumptief, 2e woning, belasting, zorg) | Euro. Completere waarneming vanaf 2011 |
| VEHWVEREXEWH | F11 | Vermogen excl. eigen woning en hypotheekschuld | Euro |

---

## Energieverbruik

Energy consumption data for private dwellings.

---

### ENERGIEVERBRUIKTAB

**Gas and electricity consumption of private dwellings, including solar PV and heating systems.** Observation unit: dwelling (SOORTOBJECTNUMMER + RINOBJECTNUMMER). Available 2004--2024. Additional variables (solar, heating) available from 2019 onwards.

| Variable | Type | Description | Codes/Values |
|---|---|---|---|
| SOORTOBJECTNUMMER | A1 | Herkomst object-id | `B`=BAG |
| RINOBJECTNUMMER | A32 | Object-id | 32-char ID |
| WONINGT | A1 | Woningtype Kadaster (leeg vanaf 2019) | `A`=Appartement, `T`=Tussen/geschakeld, `H`=Hoekwoning, `K`=Twee-onder-een-kap, `V`=Vrijstaand, `O`=Onbekend |
| WOONR | A1 | Woonruimtecode woningregister (leeg vanaf 2019) | `1`=Woning, `4`=Recreatiewoning, `5`=Wooneenheid, `6`=Bijzonder woongebouw |
| STADSW | A1 | Stadsverwarming aanwezig (methode klantenbestanden) | `0`=Nee, `1`=Ja |
| GAS | F8 | Gaslevering daadwerkelijk (m3) | m3. `0`=geen gas/geen aansluiting. Leeg=onvoldoende info |
| ELEK | F8 | Elektriciteitslevering bruto (kWh) | kWh. Excl. terugleveringen. Leeg=onvoldoende info |
| GASBRON | A2 | Bepalingsmethode gaslevering | `BW`=Bedrijfswoning geimputeerd, `IM`=Imputatie, `KO`=Kookgas, `LG`=Leegstand, `NT`=Niet toegekend, `SW`=Stadsverwarmingswoning, `TP`=Tapwatergas, `WG`=Gevalideerd woningverbruik, `WP`=Warmtepomp geen gas, `ZW`=Zorgwoning geimputeerd |
| ELEKBRON | A2 | Bepalingsmethode elektriciteitslevering | `BW`=Bedrijfswoning, `IM`=Imputatie, `LG`=Leegstand, `WG`=Gevalideerd, `ZW`=Zorgwoning |
| ELEKTERUG | F8 | Teruglevering elektriciteit (kWh) | kWh. Afgekapt op max 2x ELEK |
| ELEKNETTO | F8 | Netto elektriciteitslevering (kWh) | kWh. ELEK - ELEKTERUG, afgekapt op 0 |
| GASSJV | F8 | Standaard jaarverbruik gas (m3, temperatuurgecorrigeerd) | m3. Profielmethodiek |
| WARMTESCHATTING | F8 | Geschatte warmtelevering (GJ) | GJ. Modelmatig op basis van vergelijkbare woningen. 31.65 m3 gas = 1 GJ |
| ZONPV | A1 | Zonnestroominstallatie aanwezig | `0`=Nee, `1`=Ja (op basis van registraties of terugleveringen) |
| ZONVERMOGEN1JAN | F10.3 | Geschat vermogen zonnepanelen op 31 dec t-1 (kWp) | kWp. Leeg als teruglevering afgekapt |
| ZONVERMOGEN31DEC | F10.3 | Geschat vermogen zonnepanelen op 31 dec t (kWp) | kWp |
| ZONPVBRON | A1 | Bron ZONPV-bepaling | `1`=Zonvermogen, `2`=Terugleveringen, `3`=Beiden, `4`=Geen indicatie. Vanaf 2022 |
| HOOFDVERWARMING31DEC | A1 | Hoofdverwarmingstype (oude methode) | `1`=Individuele CV, `2`=Blokverwarming, `3`=Stadsverwarming + gas RV+WW+koken, `4`=Stadsverwarming + gas WW/koken, `5`=Stadsverwarming zonder gas, `6`=Elektrisch + gas RV+WW+koken, `7`=Elektrisch + gas WW/koken, `8`=Elektrisch zonder gas, `9`=Onbekend |
| WONINGBEWONING10PROFIELEN | A2 | Woningprofiel aardgaswoningen | `-1`=Geen aardgaswoning, `00`=Niet in profiel, `01`--`10`=Profielen (combinatie woningtype/grootte/bouwjaar/bewoners), `19`=Afgekeurd |
| KBHOOFDVERWARMING31DEC | A2 | Hoofdverwarmingstype (nieuwe methode, afgestemd op KB) | `01`=Individuele CV, `02`=Blokverwarming, `03`=Stadsverwarming hoog gasverbruik, `04`=Stadsverwarming laag gasverbruik, `05`=Stadsverwarming zonder gas, `06`=Elektrisch hoog gasverbruik, `07`=Elektrisch laag gasverbruik, `08`=Elektrisch zonder gas, `09`=Onbekend. Vanaf 2022 |

---

## Key linking variables across datasets

| Variable | Links | Notes |
|---|---|---|
| RINPERSOON + RINPERSOONS | Person across all datasets | Universal person key |
| RINOBJECTNUMMER + SOORTOBJECTNUMMER | Dwelling across Woonbase + Energieverbruik | Universal dwelling key |
| RINKENTEKEN | Vehicle across RDW + Verkeersprestatie | Encrypted licence plate |
| HUISHOUDNR + DATUMAANVANGHH | Household within Woonbase | Composite household key |
| RINPERSOONHKW + RINPERSOONSHKW | Household in VEHTAB | Primary earner = household ID |
| SBEID | Employer in SPOLIS | Links to BETAB |
| IKVID | Job in SPOLIS | Unique per person-job |
| PandID | Building in EKWoonruimtenPand | Links VBOs to their building |
