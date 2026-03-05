# analysis/demo_autobelasting.R
#
# Autobelasting chart — cross-dataset policy analysis.
# Simulates car tax burden by income percentile from CBS + RDW data.
# Run: Rscript analysis/demo_autobelasting.R

suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
  library(haven)
  library(glue)
})
devtools::load_all(".")  # must come AFTER library(haven) to avoid masking read_sav

dir.create("plots", showWarnings = FALSE)
log_msg <- function(...) cat(sprintf("[%s] %s\n", format(Sys.time(), "%H:%M:%S"), paste0(...)))

YEAR   <- 2023L
N_PERS <- 20000L

# Load and join data ----

log_msg("Initialising spines...")
sim_reset()
woonbase_init(year = YEAR, n = N_PERS, seed = 42L)
sim_init("rdw", year = YEAR, seed = 43L)

# Person-level population (maps every person to their household)
dt_pers <- as.data.table(read_sav(
  glue("WoonbasePopulatiePersonen{YEAR}V1"),
  col_select = c(RINPERSOON, HUISHOUDNR1Jan)
))

# Household-level data (one row per HH — income + percentile from package)
dt_hh <- as.data.table(read_sav(
  glue("WOONBASEEKHuishoudensWV{YEAR}V1"),
  col_select = c(RINPERSOON, BESTINKH1JAN, P100HBEST1JAN)
))

# Join HUISHOUDNR onto welvaart table (both have RINPERSOON = ref person)
dt_hh_pop <- as.data.table(read_sav(
  glue("WoonbasePopulatieHuishoudens{YEAR}V1"),
  col_select = c(HUISHOUDNR1Jan, RINPERSOON,
                 AantalPersonenPerHuishouden1Jan)
))
dt_hh <- merge(dt_hh, dt_hh_pop, by = "RINPERSOON")

setnames(dt_hh, c("BESTINKH1JAN", "P100HBEST1JAN"),
                c("income",       "pct_raw"))

# Income percentile in 5-point groups (5, 10, ..., 100)
dt_hh[, pct_group := as.integer(pmin(100L, ceiling(pct_raw / 5) * 5L))]

# RDW kentekens: vehicle attributes per person
dt_kent <- as.data.table(read_sav(
  glue("RDWNPACT{YEAR}TABV1"),
  col_select = c(RINPERSOON, RINKENTEKEN, VRTGSOORT,
                 BRANDSTCODECORVRTG, MASSALEEGCORVRTG)
))

# VKT per vehicle (RINKENTEKEN is consistent across RDW files)
dt_vp <- as.data.table(read_sav(
  glue("VERKEERSPRESTATIE{YEAR}TABV1"),
  col_select = c(RINKENTEKEN, RinpersoonVP, VPJAARKM)
))

# --- Keep only personenauto (passenger cars) ---
dt_kent[, vrtg_label := as.character(as_factor(VRTGSOORT))]
dt_cars <- dt_kent[grepl("personenauto", vrtg_label, ignore.case = TRUE)]

# Add VKT
dt_cars[dt_vp, on = "RINKENTEKEN", vpjaarkm := i.VPJAARKM]
dt_cars[is.na(vpjaarkm), vpjaarkm := 0]

# Fuel labels
dt_cars[, fuel := as.character(as_factor(BRANDSTCODECORVRTG))]
dt_cars[, mass := as.numeric(MASSALEEGCORVRTG)]

# --- Map cars to households via person-level population ---
dt_cars[dt_pers, on = "RINPERSOON", HUISHOUDNR1Jan := i.HUISHOUDNR1Jan]
dt_cars <- dt_cars[!is.na(HUISHOUDNR1Jan)]


# Simulate tax components per vehicle ----

# mrb: motor vehicle tax — weight-based (roughly €4/kg for first 900kg, €6 above)
dt_cars[, tax_mrb := fifelse(mass <= 900, mass * 0.45, 900 * 0.45 + (mass - 900) * 0.65)]

# bpm afschrijving: purchase tax depreciation (~€300-600/yr depending on fuel)
dt_cars[, tax_bpm := fifelse(fuel == "Electriciteit", 50,
                    fifelse(fuel == "Diesel", 500, 350))]

# btw afschrijving: VAT on vehicle depreciation (~€200-400/yr)
dt_cars[, tax_btw_afschr := fifelse(fuel == "Electriciteit", 300,
                            fifelse(fuel == "Diesel", 250, 200))]

# accijns brandstof: fuel excise based on km driven
# ~€0.85/L petrol excise, ~10 km/L avg → €0.085/km; diesel ~€0.065/km; EV: 0
dt_cars[, tax_accijns := fifelse(fuel == "Electriciteit", 0,
                         fifelse(fuel == "Diesel", vpjaarkm * 0.065,
                         fifelse(fuel == "LPG", vpjaarkm * 0.045,
                                 vpjaarkm * 0.085)))]

# btw brandstof: VAT on fuel (~21% of fuel cost excl excise)
# Fuel cost ~€0.10/km (petrol), €0.08/km (diesel) before VAT
dt_cars[, tax_btw_brandstof := fifelse(fuel == "Electriciteit", vpjaarkm * 0.01,
                               fifelse(fuel == "Diesel", vpjaarkm * 0.08 * 0.21,
                                       vpjaarkm * 0.10 * 0.21))]

# bijtelling: company car surcharge (applies to ~15% of cars, ~€1500/yr avg)
set.seed(123)
dt_cars[, tax_bijtelling := fifelse(runif(.N) < 0.15, 1500, 0)]


# Aggregate to household level ----

hh_tax <- dt_cars[, .(
  mrb            = sum(tax_mrb),
  bijtelling     = sum(tax_bijtelling),
  bpm            = sum(tax_bpm),
  btw_afschr     = sum(tax_btw_afschr),
  accijns        = sum(tax_accijns),
  btw_brandstof  = sum(tax_btw_brandstof),
  n_cars         = .N
), by = HUISHOUDNR1Jan]

# Join tax totals onto all households via HUISHOUDNR
dt_hh[hh_tax, on = "HUISHOUDNR1Jan",
      `:=`(mrb = i.mrb, bijtelling = i.bijtelling, bpm = i.bpm,
           btw_afschr = i.btw_afschr, accijns = i.accijns,
           btw_brandstof = i.btw_brandstof, n_cars = i.n_cars)]

# Fill NA (no car) with 0
tax_cols <- c("mrb", "bijtelling", "bpm", "btw_afschr", "accijns", "btw_brandstof", "n_cars")
for (col in tax_cols) dt_hh[is.na(get(col)), (col) := 0]

# Convert to % of income
pct_cols <- paste0(tax_cols[1:6], "_pct")
for (i in seq_along(pct_cols)) {
  dt_hh[, (pct_cols[i]) := get(tax_cols[i]) / income * 100]
}


# Aggregate by percentile group ----

build_pct_table <- function(dt) {
  dt[, .(
    mrb              = mean(mrb_pct),
    bijtelling       = mean(bijtelling_pct),
    `bpm afschrijving`  = mean(bpm_pct),
    `btw afschrijving`  = mean(btw_afschr_pct),
    `accijns brandstof` = mean(accijns_pct),
    `btw brandstof`     = mean(btw_brandstof_pct)
  ), by = .(percentiel = pct_group)]
}

agg_all  <- build_pct_table(dt_hh)
agg_auto <- build_pct_table(dt_hh[n_cars > 0])

# Ensure all percentile groups present, fill NAs with 0
all_pcts <- data.table(percentiel = seq(5, 100, by = 5))
agg_all  <- merge(all_pcts, agg_all,  by = "percentiel", all.x = TRUE)
agg_auto <- merge(all_pcts, agg_auto, by = "percentiel", all.x = TRUE)
for (col in names(agg_all)[-1]) {
  agg_all[is.na(get(col)), (col) := 0]
  agg_auto[is.na(get(col)), (col) := 0]
}

setorder(agg_all, percentiel)
setorder(agg_auto, percentiel)

tax_names <- c("mrb", "bijtelling", "bpm afschrijving",
               "btw afschrijving", "accijns brandstof", "btw brandstof")


# Plot ----

log_msg("Creating ggplot version...")

# CPB-style colors (matching original figure)
cpb_cols <- c(
  "mrb"              = "#005faf",
  "bijtelling"       = "#e6006e",
  "bpm afschrijving" = "#87d2ff",
  "btw afschrijving" = "#96827d",
  "accijns brandstof"= "#d7c8c8",
  "btw brandstof"    = "#F596AF"
)

make_long <- function(dt, panel_label) {
  melt(dt, id.vars = "percentiel", variable.name = "belasting", value.name = "pct")[
    , panel := panel_label]
}

long_all  <- make_long(agg_all,  "Alle huishoudens")
long_auto <- make_long(agg_auto, "Huishoudens met auto")
long <- rbindlist(list(long_all, long_auto))

long[, belasting := factor(belasting, levels = rev(tax_names))]
long[, panel := factor(panel, levels = c("Alle huishoudens", "Huishoudens met auto"))]

p <- ggplot(long, aes(x = percentiel, y = pct, fill = belasting)) +
  geom_area(alpha = 0.9) +
  facet_wrap(~ panel, ncol = 2) +
  scale_fill_manual(values = cpb_cols, name = NULL,
                    guide = guide_legend(nrow = 2)) +
  scale_x_continuous(breaks = seq(0, 100, 20)) +
  labs(
    title = "Verdeling uitgaven autobelastingen",
    subtitle = "relatief t.o.v. het besteedbare inkomen (in %)",
    x = "percentielgroepen besteedbare inkomens huishoudens",
    y = "%"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    legend.position = "bottom",
    plot.title    = element_text(face = "bold", size = 12),
    plot.subtitle = element_text(colour = "grey45", size = 9),
    strip.text    = element_text(face = "bold", size = 10),
    panel.grid.minor = element_blank()
  )

print(p)
ggsave("plots/test_autobelasting.png", p,
       width = 12, height = 5.5, dpi = 150)
log_msg("Done — saved to plots/test_autobelasting.png")
