# analysis/demo_woonbase.R
#
# Woonbase visualisation: population pyramid, HH type by age, income vs WOZ.
# Run: Rscript analysis/demo_woonbase.R

suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
  library(haven)
})
devtools::load_all(".")

dir.create("plots", showWarnings = FALSE)

YEAR <- 2023L


# Load data ----

woonbase_init(year = YEAR, n = 5000L, seed = 42L)

dt <- as.data.table(read_sav(
  sprintf("WoonbasePopulatiePersonen%dV1", YEAR),
  col_select = c(RINPERSOON, GBAGeboorteJaar1Jan,
                 GBAGeslachtsAanduiding1Jan, TYPHH1Jan,
                 HUISHOUDNR1Jan)
))
dt[, leeftijd := YEAR - as.integer(GBAGeboorteJaar1Jan)]
dt[, geslacht := as.character(as_factor(GBAGeslachtsAanduiding1Jan))]
dt[, typhh    := as.character(as_factor(TYPHH1Jan))]

theme_set(theme_minimal(base_size = 11) +
  theme(plot.title = element_text(face = "bold"),
        plot.subtitle = element_text(colour = "grey45", size = 9)))


# Population pyramid ----

pyr <- dt[leeftijd >= 0 & leeftijd <= 100]
pyr[, age_group := cut(leeftijd, breaks = seq(0, 100, 5), right = FALSE,
                       labels = paste0(seq(0, 95, 5), "-", seq(4, 99, 5)))]
pyr <- pyr[, .N, by = .(age_group, geslacht)]
pyr[geslacht == "Mannen", N := -N]

p1 <- ggplot(pyr, aes(age_group, N, fill = geslacht)) +
  geom_col(width = 0.85) +
  coord_flip() +
  scale_y_continuous(
    labels = \(x) format(abs(x), big.mark = ","),
    name = "Aantal") +
  scale_fill_manual(values = c("Mannen" = "#2166AC", "Vrouwen" = "#B2182B"),
                    name = NULL) +
  labs(title = "Bevolkingspiramide",
       subtitle = sprintf("Woonbase %d (gesimuleerd, n=%s)",
                          YEAR, format(nrow(dt), big.mark = ",")),
       x = "Leeftijdsgroep") +
  theme(legend.position = "bottom",
        panel.grid.major.y = element_blank())

print(p1)
ggsave("plots/demo_woonbase_p1_piramide.png", p1, width = 7, height = 6, dpi = 150)


# Household type by age of reference person ----

ref <- dt[, .SD[1L], by = HUISHOUDNR1Jan]
ref[, age_grp := cut(leeftijd, breaks = c(0, 25, 35, 45, 55, 65, 75, 101),
                     labels = c("<25", "25-34", "35-44", "45-54",
                                "55-64", "65-74", "75+"),
                     right = FALSE)]
ref <- ref[, .N, by = .(age_grp, typhh)]
ref[, pct := N / sum(N) * 100, by = age_grp]

type_order <- ref[, .(tot = sum(N)), by = typhh][order(-tot), typhh]
ref[, typhh := factor(typhh, levels = rev(type_order))]

p2 <- ggplot(ref, aes(age_grp, pct, fill = typhh)) +
  geom_col(width = 0.8) +
  scale_fill_brewer(palette = "Set2", name = NULL,
                    guide = guide_legend(ncol = 2, reverse = TRUE)) +
  scale_y_continuous(labels = \(x) paste0(x, "%")) +
  labs(title = "Huishoudtype naar leeftijd referentiepersoon",
       subtitle = sprintf("Woonbase %d -- hoe huishoudsamenstelling verschuift met leeftijd", YEAR),
       x = "Leeftijd referentiepersoon", y = "Aandeel") +
  theme(legend.position = "bottom")

print(p2)
ggsave("plots/demo_woonbase_p2_typhh_leeftijd.png", p2, width = 9, height = 5.5, dpi = 150)


# Income vs WOZ heatmap ----

dt_hh <- as.data.table(read_sav(
  sprintf("WOONBASEEKHuishoudensWV%dV1", YEAR),
  col_select = c(RINPERSOON, BESTINKH1JAN)
))
dt_obj <- as.data.table(read_sav(
  sprintf("WoonbaseKenmerkenWoonruimten%dV1", YEAR),
  col_select = c(RINOBJECTNUMMER, WOZWaardeObjectBAG1Jan)
))
dt_sleutel <- as.data.table(read_sav(
  sprintf("WoonbaseSleutelbestand%dV1", YEAR),
  col_select = c(RINPERSOON, RINOBJECTNUMMER)
))
woz_inc <- merge(dt_hh, dt_sleutel, by = "RINPERSOON")
woz_inc <- merge(woz_inc, dt_obj, by = "RINOBJECTNUMMER")
woz_inc <- woz_inc[BESTINKH1JAN > 0 & WOZWaardeObjectBAG1Jan > 0]

p3 <- ggplot(woz_inc, aes(x = WOZWaardeObjectBAG1Jan / 1000,
                           y = BESTINKH1JAN / 1000)) +
  geom_bin2d(bins = 40) +
  scale_fill_viridis_c(option = "inferno", name = "Huishoudens") +
  scale_x_continuous(labels = \(x) paste0(x, "k"),
                     limits = c(0, quantile(woz_inc$WOZWaardeObjectBAG1Jan / 1000, 0.99))) +
  scale_y_continuous(labels = \(x) paste0(x, "k"),
                     limits = c(0, quantile(woz_inc$BESTINKH1JAN / 1000, 0.99))) +
  labs(title = "Inkomen vs. WOZ-waarde",
       subtitle = "Dichtheid -- hogere WOZ correleert met hoger inkomen",
       x = "WOZ-waarde woning (x1000 EUR)",
       y = "Besteedbaar inkomen (x1000 EUR)") +
  theme(legend.position = "right")

print(p3)
ggsave("plots/demo_woonbase_p3_inkomen_woz.png", p3, width = 7, height = 5.5, dpi = 150)

cat("Saved 3 plots to plots/\n")
