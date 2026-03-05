# analysis/analyse_woonbase.R
#
# Loads 4 Woonbase files, joins them by reference with data.table,
# and produces 6 descriptive plots + 2 municipality choropleths.
#
# Files used:
#   woonbasepopulatieperso  – person population (rich: HH + object attrs as klasse)
#   woonbasekenmerkenhuis   – household characteristics (one row per HH)
#   woonbasekenmerkenpers   – person characteristics (one row per person)
#   woonbasekenmerkenwoon   – dwelling characteristics (one row per VBO; exact values)

suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
  library(haven)
  library(sf)
})
devtools::load_all(".")  # must come AFTER library(haven) to avoid masking read_sav

dir.create("plots", recursive = TRUE, showWarnings = FALSE)

YEAR  <- 2023L
BLUE  <- "#2166AC"
theme_set(
  theme_minimal(base_size = 11) +
    theme(plot.subtitle = element_text(colour = "grey45", size = 9),
          plot.caption  = element_text(colour = "grey60", size = 7),
          plot.title    = element_text(face = "bold"))
)


# Initialise spine ----

woonbase_init(year = YEAR, n = 1e5, seed = 42L)


# Load files into data.table ----

message("Loading Woonbase files …")

# col_select mirrors what you'd request on real CBS microdata: only the columns
# actually needed for this analysis.  n_max takes a row sample — in a
# development/analysis setting you'd typically work on a subset of the 17 M
# (persons) or 8 M (HH / objects) rows in the full register.

dt_pp <- as.data.table(read_sav(
  sprintf("WoonbasePopulatiePersonen%dV1", YEAR),
  n_max      = 50000L,
  col_select = c(RINPERSOON, RINOBJECTNUMMER1Jan, HUISHOUDNR1Jan,
                 GBAGeboorteJaar1Jan, GBAGeslachtsAanduiding1Jan,
                 TYPHH1Jan, PLHH1Jan, TypeEigenaar1Jan, VBOWoningType1Jan,
                 GemeenteCodeJJJJ1Jan, AantalPersonenPerHuishouden1Jan)
))

dt_kh <- as.data.table(read_sav(
  sprintf("WoonbaseKenmerkenHuishoudens%dV1", YEAR),
  n_max      = 50000L,
  col_select = c(HUISHOUDNR1Jan, RINPERSOON,
                 TYPHH1Jan, AantalPersonenPerHuishouden1Jan,
                 AantalKinderenPerHuishouden1Jan)
))

dt_kp <- as.data.table(read_sav(
  sprintf("WoonbaseKenmerkenPersonen%dV1", YEAR),
  n_max      = 50000L,
  col_select = c(RINPERSOON, GBAGeboorteJaar1Jan, GBAGeslachtsAanduiding1Jan)
))

dt_ko <- as.data.table(read_sav(
  sprintf("WoonbaseKenmerkenWoonruimten%dV1", YEAR),
  n_max      = 50000L,
  col_select = c(RINOBJECTNUMMER, VBOWoningType1Jan, VBOBouwjaar1Jan,
                 VBOOppervlakte1Jan, WOZWaardeObjectBAG1Jan)
))


# Joins by reference ----

message("Joining …")

# 3a. Update join: add exact WOZ value, floor area, and build year
#     from kenmerken_woon into the person table.
#     Key: RINOBJECTNUMMER1Jan (dt_pp) → RINOBJECTNUMMER (dt_ko).
dt_pp[
  dt_ko[, .(RINOBJECTNUMMER,
            WOZ_exact = WOZWaardeObjectBAG1Jan,
            opp_m2    = VBOOppervlakte1Jan,
            bouwjaar  = VBOBouwjaar1Jan)],
  on  = c("RINOBJECTNUMMER1Jan" = "RINOBJECTNUMMER"),
  `:=`(WOZ_exact = i.WOZ_exact,
       opp_m2    = i.opp_m2,
       bouwjaar  = i.bouwjaar)
]

# 3b. Update join: add reference-person age and gender into kenmerken_hh.
#     RINPERSOON in kenmerken_hh identifies the household reference person.
dt_kh[
  dt_kp[, .(RINPERSOON,
            leeftijd_ref = YEAR - as.integer(GBAGeboorteJaar1Jan),
            geslacht_ref = as_factor(GBAGeslachtsAanduiding1Jan))],
  on  = "RINPERSOON",
  `:=`(leeftijd_ref = i.leeftijd_ref,
       geslacht_ref = i.geslacht_ref)
]

# 3c. Derive analysis columns (factor labels + age in years).
dt_pp[, leeftijd     := YEAR - as.integer(GBAGeboorteJaar1Jan)]
dt_pp[, typhh_f      := as_factor(TYPHH1Jan)]
dt_pp[, eigenaar_f   := as_factor(TypeEigenaar1Jan)]
dt_pp[, woningtype_f := as_factor(VBOWoningType1Jan)]
dt_pp[, geslacht_f   := as_factor(GBAGeslachtsAanduiding1Jan)]
dt_pp[, plhh_f       := as_factor(PLHH1Jan)]

dt_kh[, typhh_f  := as_factor(TYPHH1Jan)]
dt_kh[, hh_size  := as.integer(AantalPersonenPerHuishouden1Jan)]
dt_kh[, n_kids   := as.integer(AantalKinderenPerHuishouden1Jan)]

dt_ko[, woningtype_f := as_factor(VBOWoningType1Jan)]

# 3d. Object-level sub-table: one row per dwelling (dedup dt_pp).
#     Gives access to exact WOZ + eigenaar at object level without
#     inflating counts by the number of occupants.
setkey(dt_pp, RINOBJECTNUMMER1Jan)
dt_obj <- dt_pp[, .SD[1L], by = RINOBJECTNUMMER1Jan]


# Plots ----

message("Plotting …")

# -- Plot 1: Age distribution --------------------------------------------------
p1 <- ggplot(dt_pp[leeftijd >= 0 & leeftijd <= 100],
             aes(leeftijd)) +
  geom_histogram(binwidth = 5, fill = BLUE, colour = "white", linewidth = 0.25) +
  scale_x_continuous(breaks = seq(0, 100, 10)) +
  labs(title    = "Leeftijdsverdeling bevolking",
       subtitle = paste0("Personen in Woonbase, 1 januari ", YEAR),
       x = "Leeftijd (jaren)", y = "Aantal personen")

print(p1)
ggsave("plots/p1_leeftijd.png", p1, width = 7, height = 4, dpi = 150)
message("  p1 done")

# -- Plot 2: Household type composition ----------------------------------------
hh_type_cnt <- dt_kh[!is.na(typhh_f), .N, by = typhh_f]
hh_type_cnt[, pct := N / sum(N) * 100]

p2 <- ggplot(hh_type_cnt,
             aes(x = reorder(typhh_f, pct), y = pct, fill = typhh_f)) +
  geom_col(show.legend = FALSE) +
  geom_text(aes(label = sprintf("%.1f%%", pct)), hjust = -0.1, size = 3.2) +
  coord_flip() +
  scale_y_continuous(limits = c(0, max(hh_type_cnt$pct) * 1.18),
                     labels = \(x) paste0(x, "%")) +
  scale_fill_brewer(palette = "Set2") +
  labs(title    = "Samenstelling huishoudens",
       subtitle = paste0("Aandeel per type, 1 januari ", YEAR),
       x = NULL, y = "Aandeel (%)")

print(p2)
ggsave("plots/p2_typhh.png", p2, width = 9, height = 5, dpi = 150)
message("  p2 done")

# -- Plot 3: WOZ value by owner type (object level) ----------------------------
p3_data <- dt_obj[
  !is.na(WOZ_exact) & WOZ_exact < 2e6 &
  !is.na(eigenaar_f) & !grepl("nbekend", eigenaar_f, ignore.case = TRUE)
]

p3 <- ggplot(p3_data, aes(x = eigenaar_f, y = WOZ_exact / 1e3, fill = eigenaar_f)) +
  geom_violin(alpha = 0.65, colour = NA, trim = TRUE) +
  geom_boxplot(width = 0.14, outlier.shape = NA, fill = "white",
               colour = "grey35", linewidth = 0.5) +
  scale_y_continuous(labels = \(x) paste0("\u20ac", x, "k")) +
  scale_fill_brewer(palette = "Set2") +
  labs(title    = "WOZ-waarde naar type eigenaar",
       subtitle = paste0("Woonruimten (één rij per VBO), 1 januari ", YEAR),
       x = NULL, y = "WOZ-waarde") +
  theme(legend.position   = "none",
        axis.text.x       = element_text(angle = 15, hjust = 1))

print(p3)
ggsave("plots/p3_woz_eigenaar.png", p3, width = 7, height = 5, dpi = 150)
message("  p3 done")

# -- Plot 4: Floor area by dwelling type (object level) ------------------------
p4_data <- dt_ko[
  !is.na(VBOOppervlakte1Jan) & VBOOppervlakte1Jan < 400 &
  !is.na(woningtype_f) & !grepl("nbekend", woningtype_f, ignore.case = TRUE)
]

p4 <- ggplot(p4_data,
             aes(x = reorder(woningtype_f, VBOOppervlakte1Jan, FUN = median),
                 y = VBOOppervlakte1Jan, fill = woningtype_f)) +
  geom_boxplot(outlier.alpha = 0.15, colour = "grey35", linewidth = 0.5) +
  scale_fill_brewer(palette = "Set1") +
  labs(title    = "Woonoppervlak naar woningtype",
       subtitle = paste0("Verblijfsobjecten, 1 januari ", YEAR),
       x = NULL, y = "Woonoppervlak (m\u00b2)") +
  theme(legend.position = "none",
        axis.text.x     = element_text(angle = 20, hjust = 1))

print(p4)
ggsave("plots/p4_opp_woningtype.png", p4, width = 7, height = 5, dpi = 150)
message("  p4 done")

# -- Plot 5: Build-year distribution (object level) ----------------------------
p5 <- ggplot(dt_ko[VBOBouwjaar1Jan >= 1850 & VBOBouwjaar1Jan <= YEAR],
             aes(VBOBouwjaar1Jan)) +
  geom_histogram(binwidth = 5, fill = BLUE, colour = "white", linewidth = 0.25) +
  geom_vline(xintercept = c(1945, 1975, 2000), linetype = "dashed",
             colour = "grey50", linewidth = 0.4) +
  annotate("text", x = c(1946, 1976, 2001), y = Inf,
           label = c("'45", "'75", "'00"),
           hjust = 0, vjust = 1.4, size = 2.8, colour = "grey45") +
  scale_x_continuous(breaks = seq(1850, 2025, 25)) +
  labs(title    = "Bouwjaar verblijfsobjecten",
       subtitle = paste0("Woonruimten in Woonbase, 1 januari ", YEAR),
       x = "Bouwjaar", y = "Aantal VBO's") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

print(p5)
ggsave("plots/p5_bouwjaar.png", p5, width = 7, height = 4, dpi = 150)
message("  p5 done")

# -- Plot 6: Household size by type (stacked bar) ------------------------------
p6_data <- dt_kh[!is.na(hh_size) & !is.na(typhh_f),
                 .(hh_size_cap = factor(pmin(hh_size, 8L),
                                        levels = 1:8,
                                        labels = c(1:7, "8+")),
                   typhh_f)]
p6_grp <- p6_data[, .N, by = .(hh_size_cap, typhh_f)]

p6 <- ggplot(p6_grp, aes(x = hh_size_cap, y = N, fill = typhh_f)) +
  geom_col() +
  scale_fill_brewer(palette = "Set2", name = NULL,
                    guide   = guide_legend(ncol = 2, keyheight = 0.8)) +
  labs(title    = "Huishoudensgrootte naar type",
       subtitle = paste0("Huishoudens in Woonbase, 1 januari ", YEAR),
       x = "Aantal personen per huishouden", y = "Aantal huishoudens") +
  theme(legend.position = "bottom",
        legend.text     = element_text(size = 7.5))

print(p6)
ggsave("plots/p6_hh_grootte_type.png", p6, width = 9, height = 6, dpi = 150)
message("  p6 done")


# Maps ----

message("Loading gemeente boundaries …")

gem_sf <- tryCatch(
  sf::st_read(sprintf("https://cartomap.github.io/nl/wgs84/gemeente_%d.geojson", YEAR),
              quiet = TRUE),
  error = function(e) {
    message("  Could not load shapefile: ", conditionMessage(e))
    NULL
  }
)

if (!is.null(gem_sf)) {

  # statcode in cartomap is "GM0363"; strip prefix → "0363" to match our codes
  gem_sf <- setDT(gem_sf)[, GemCode4 := sub("^GM", "", statcode)]
  gem_sf <- st_as_sf(gem_sf)

  # Aggregate from person table: persons per gemeente
  gem_pers <- dt_pp[, .(n_personen = .N),
                    by = .(GemCode4 = GemeenteCodeJJJJ1Jan)]

  # Aggregate from object table: mean WOZ per gemeente (one value per dwelling)
  gem_woz  <- dt_obj[!is.na(WOZ_exact),
                     .(WOZ_gem_k = mean(WOZ_exact) / 1e3),
                     by = .(GemCode4 = GemeenteCodeJJJJ1Jan)]

  map1_sf <- merge(gem_sf, gem_pers, by = "GemCode4", all.x = TRUE)
  map2_sf <- merge(gem_sf, gem_woz,  by = "GemCode4", all.x = TRUE)

  map_theme <- theme_void(base_size = 11) +
    theme(plot.title    = element_text(face = "bold", size = 13,
                                       margin = margin(b = 4)),
          plot.subtitle = element_text(colour = "grey45", size = 9,
                                       margin = margin(b = 8)),
          plot.caption  = element_text(colour = "grey60", size = 7),
          legend.position = "right")

  # -- Map 1: Person count per gemeente ----------------------------------------
  map1 <- ggplot(map1_sf) +
    geom_sf(aes(fill = n_personen), colour = "white", linewidth = 0.1) +
    scale_fill_distiller(palette  = "Blues", direction = 1,
                         na.value = "grey88", name = "Personen",
                         labels   = \(x) format(round(x), big.mark = ".")) +
    labs(title    = "Bevolking per gemeente",
         subtitle = paste0("Personen in Woonbase, 1 januari ", YEAR),
         caption  = paste0("Gemeentegrenzen: CBS ", YEAR, " via cartomap.github.io\nData: CBS Woonbase (gesimuleerd)")) +
    map_theme

  print(map1)
  ggsave("plots/map1_bevolking_gemeente.png",
         map1, width = 6.5, height = 9, dpi = 150)
  message("  map1 done")

  # -- Map 2: Mean WOZ value per gemeente ---------------------------------------
  map2 <- ggplot(map2_sf) +
    geom_sf(aes(fill = WOZ_gem_k), colour = "white", linewidth = 0.1) +
    scale_fill_distiller(palette  = "YlOrRd", direction = 1,
                         na.value = "grey88",
                         name     = "WOZ\n(\u00d7\u20ac1k)",
                         labels   = \(x) paste0("\u20ac", round(x))) +
    labs(title    = "Gemiddelde WOZ-waarde per gemeente",
         subtitle = paste0("Woonruimten in Woonbase, 1 januari ", YEAR),
         caption  = paste0("Gemeentegrenzen: CBS ", YEAR, " via cartomap.github.io\nData: CBS Woonbase (gesimuleerd)")) +
    map_theme

  print(map2)
  ggsave("plots/map2_woz_gemeente.png",
         map2, width = 6.5, height = 9, dpi = 150)
  message("  map2 done")

} else {
  message("Maps skipped (gemeente shapefile unavailable).")
}

message("All figures saved to plots/")
