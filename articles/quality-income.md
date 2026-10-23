# Developing a household income analysis

> **How unequal is household disposable income in the Netherlands, and
> how does it differ between household types?**

The analysis itself will run in CBS Remote Access. This page develops
its code on simulated `INHATAB` (household income) linked to woonbase
household types, and uses StatLine 83932NED, the published aggregate of
the same register, to show which simulated results look like the real
ones. Similar pages:
[`vignette("quality-cars")`](https://joris-klingen.github.io/simregdata/articles/quality-cars.md)
and
[`vignette("quality-energy")`](https://joris-klingen.github.io/simregdata/articles/quality-energy.md).

## At a glance

| Result | Looks like reality? | In Remote Access |
|----|----|----|
| Mean and median income, overall and by household type | yes | similar; a large gap means a bug |
| Gross and standardised income | yes | similar |
| Percentile columns | yes | similar, plus special codes |
| Distribution over income classes | bulk yes, tails too thin | more households at both ends |
| Decile means (inequality) | up to decile 8 | top decile much higher |
| Primary income | too high | lower |
| Personal incomes summing to household income | no | consistent |

Household income is drawn per household type from the mean and median of
83932NED; the class distribution and decile means are not calibrated.

## Simulated data

``` r

sim_reset()
woonbase_init(year = 2023, n = 50000L, seed = 42L)
sim_init("inhatab", year = 2023, seed = 43L)
sim_init("inpatab", year = 2023, seed = 44L)

pers <- as.data.table(read_sav("WoonbasePopulatiePersonen2023V1",
                               col_select = c(RINPERSOON, HUISHOUDNR1Jan)))
hh <- as.data.table(read_sav("WoonbasePopulatieHuishoudens2023V1",
                             col_select = c(HUISHOUDNR1Jan, TYPHH1Jan)))
inpa <- as.data.table(read_sav("INPA2023TABV1",
                               col_select = c(RINPERSOON, RINPERSOONHKW, INPPERSBESTINK)))
inha <- as.data.table(read_sav("INHA2023TABV1"))

# INHATAB is keyed on RINPERSOONHKW; INPATAB links it to persons, woonbase
# links persons to households
inpa[pers, on = "RINPERSOON", HUISHOUDNR1Jan := i.HUISHOUDNR1Jan]
inha[unique(inpa, by = "RINPERSOONHKW"), on = "RINPERSOONHKW",
     HUISHOUDNR1Jan := i.HUISHOUDNR1Jan]
hh[inha, on = "HUISHOUDNR1Jan", `:=`(
  inkomen = as.numeric(i.INHBESTINKH), p100 = as.numeric(i.INHP100HBEST),
  primair = as.numeric(i.INHPRIMINKH), bruto = as.numeric(i.INHBRUTINKH),
  gestand = as.numeric(i.INHGESTINKH))]

# StatLine covers private households only
hh <- hh[!is.na(inkomen) & as_factor(TYPHH1Jan) != "Institutioneel huishouden"]
```

## Level and income concepts

``` r

sim_level <- hh[, .(gemiddeld = mean(inkomen), mediaan = median(inkomen))]
```

|                          | simulatie | StatLine |
|:-------------------------|----------:|---------:|
| Mean disposable income   |    59,900 |   57,600 |
| Median disposable income |    47,100 |   44,700 |

![](quality-income_files/figure-html/concepts.png)

Gross and standardised income follow disposable income closely. Primary
income comes out too high: it is far more skewed (pensioners have little
of it) than a single ratio per household type can capture.

## Distribution and inequality

``` r

sim_dec <- hh[order(inkomen), .(deciel = ceiling(seq_len(.N) / .N * 10), inkomen)][
  , .(gemiddeld = mean(inkomen), bron = "simulatie"), by = deciel]
```

![](quality-income_files/figure-html/classes.png)![](quality-income_files/figure-html/deciles.png)

The bulk of the distribution matches. The tails are too thin: hardly any
household falls below 10,000 euro (self-employed with losses, students),
and the top decile averages 164 thousand euro against 172 thousand in
reality, so inequality measures that weigh the very top come out too
low.

`INHP100HBEST` is the rank of the household income (rank correlation
1.000), so grouping on it gives the same deciles as computing the ranks
yourself.

## Household type

``` r

hh[, type := fcase(
  TYPHH1Jan %in% 1,   "Eenpersoonshuishouden",
  TYPHH1Jan %in% 6,   "Eenoudergezin",
  TYPHH1Jan %in% 2:3, "Paar, zonder kind",
  TYPHH1Jan %in% 4:5, "Paar, met kind(eren)",
  TYPHH1Jan %in% 7,   "Meerpersoonshuishouden, overig")]
sim_type <- hh[!is.na(type), .(gemiddeld = mean(inkomen), bron = "simulatie"), by = type]
```

![](quality-income_files/figure-html/by-type.png)

Couples with children have about three times the income of single-person
households, in the simulation as in reality.

## Persons and households

``` r

pers_sum <- inpa[, .(som_personen = sum(as.numeric(INPPERSBESTINK))), by = RINPERSOONHKW]
pers_sum[inha, on = "RINPERSOONHKW", huishouden := as.numeric(i.INHBESTINKH)]
pers_sum[, cor(som_personen, huishouden)]
#> [1] 0.1828951
```

Personal incomes in `INPATAB` are drawn independently of the household,
so they do not add up to the household income. Code that splits
household income over its members runs, but a consistency check like the
one above only passes on the real data.

## Before you move to Remote Access

- **Negative and very low incomes.** Simulated household income is at
  least a few thousand euro; in reality self-employed households can
  have negative disposable income.
  [`log()`](https://rdrr.io/r/base/Log.html), ratios to income and
  classes starting at 0 need a rule for them.
- **Special codes.** In comparable CBS files (such as VEHTAB) percentile
  columns use negative codes for unknown income and institutional
  households. Check the INHATAB documentation and exclude those codes
  before averaging or ranking; the simulated percentiles are always 1 to
  100.
- **Losses of persons.** Personal income in `INPATAB` is floored at
  exactly -50,000 euro here, with no floor in reality; don’t build
  classes around that value.
- **Private households.** StatLine covers private households only. The
  filter on `TYPHH1Jan` above does that for the woonbase link; on the
  real data also check how institutional households appear in `INHATAB`
  itself.
