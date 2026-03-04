# scripts/housing_type_timeseries.R
#
# Housing type composition of the Dutch dwelling stock, 2016-2024.
# Mimics a microdata workflow: for each year the Woonbase population
# file is loaded via read_sav() and reduced to one row per dwelling (VBO).

suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
  library(haven)
  library(simcbsradata)
})

dir.create("output/figures", recursive = TRUE, showWarnings = FALSE)

BLUE <- "#2166AC"
theme_set(
  theme_minimal(base_size = 11) +
    theme(plot.subtitle = element_text(colour = "grey45", size = 9),
          plot.caption  = element_text(colour = "grey60", size = 7),
          plot.title    = element_text(face = "bold"))
)


# Load Woonbase per year ----

years <- 2016:2024
message("Loading Woonbase for years ", min(years), "-", max(years), " ...")

# In real CBS microdata: col_select loads only needed columns across all 17 M
# rows; no n_max — the full population is read.  The vectorised spine generator
# makes this fast enough to repeat across all years in a loop.

dt_list <- lapply(years, function(yr) {

  woonbase_init(year = yr, n = NULL, seed = 42L)

  dt <- as.data.table(read_sav(
    sprintf("WoonbasePopulatiePersonen%dV1", yr),
    col_select = c(RINOBJECTNUMMER1Jan, VBOWoningType1Jan)
    # no n_max: full generated population
  ))

  # One row per dwelling (dedup to VBO level)
  dt_vbo <- dt[, .SD[1L], by = RINOBJECTNUMMER1Jan]

  # Convert to factor with CBS labels; drop unknown categories
  dt_vbo[, woningtype := as_factor(VBOWoningType1Jan)]
  dt_vbo <- dt_vbo[!is.na(woningtype) &
                   !grepl("nbekend", woningtype, ignore.case = TRUE)]
  dt_vbo[, woningtype := factor(as.character(woningtype))]

  dt_vbo[, .(year = yr, woningtype)]
})

dt <- rbindlist(dt_list)
message("  ", format(nrow(dt), big.mark = ","), " dwelling observations loaded")


# Aggregate to counts per year and type ----

dt_agg <- dt[, .N, by = .(year, woningtype)]


# Plot ----

KLEUREN <- c("#004699", "#6cbd74", "#bed200", "#ff9100", "#009dec")

p1 <- ggplot(dt_agg, aes(x = year, y = N, fill = woningtype)) +
  geom_area(position = "fill", alpha = 0.85, colour = "white", linewidth = 0.2) +
  scale_x_continuous(breaks = years) +
  scale_y_continuous(labels = \(x) paste0(round(x * 100), "%")) +
  scale_fill_manual(values = KLEUREN,
                    guide  = guide_legend(ncol = 2, keyheight = 0.8)) +
  labs(title    = "Verdeling woningtypen in de woningvoorraad",
       subtitle = "Aandeel per woningtype op 1 januari (Woonbase-simulatie)",
       x = NULL, y = "Aandeel (%)", fill = NULL,
       caption  = "Bron: CBS Woonbase (gesimuleerd)") +
  theme(legend.position = "bottom",
        axis.text.x     = element_text(angle = 45, hjust = 1))

print(p1)
ggsave("output/figures/031_p1_woningtype_tijdreeks.png",
       p1, width = 8, height = 5, dpi = 150)
message("  p1 done")

message("Figure saved to output/figures/")
