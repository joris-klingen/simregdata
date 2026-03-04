# scripts/housing_type_timeseries.R
#
# Housing type composition of the Dutch dwelling stock, 2016-2024.
# Mimics a microdata workflow: for each year the Woonbase population
# file is loaded via read_sav() and reduced to one row per dwelling (VBO).

suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
  library(haven)
})
devtools::load_all("simcbsradata")  # must come AFTER library(haven) to avoid masking read_sav

dir.create("plots", recursive = TRUE, showWarnings = FALSE)

BLUE <- "#2166AC"
theme_set(
  theme_minimal(base_size = 11) +
    theme(plot.subtitle = element_text(colour = "grey45", size = 9),
          plot.caption  = element_text(colour = "grey60", size = 7),
          plot.title    = element_text(face = "bold"))
)


# Load Woonbase per year ----

years <- 2022:2023
message("Loading Woonbase for years ", min(years), "-", max(years), " ...")

# In real CBS microdata: col_select loads only needed columns across all 17 M
# rows; no n_max — the full population is read.  The vectorised spine generator
# makes this fast enough to repeat across all years in a loop.

# Aggregate counts directly per year (avoid large row-level rbindlist)
agg_list <- lapply(years, function(yr) {

  sim_reset()
  woonbase_init(year = yr, n = 1e6, seed = 42L)

  # Read from KenmerkenWoonruimten (object-level) — already one row per
  # dwelling, and VBOWoningType lives on the raw obj spine so no lazy
  # enrichment is triggered.
  dt_vbo <- as.data.table(read_sav(
    sprintf("WoonbaseKenmerkenWoonruimten%dV1", yr),
    col_select = c(RINOBJECTNUMMER, VBOWoningType1Jan)
  ))

  # Convert to factor with CBS labels; drop unknown categories
  dt_vbo[, woningtype := as.character(as_factor(VBOWoningType1Jan))]
  dt_vbo <- dt_vbo[!is.na(woningtype) &
                   !grepl("nbekend", woningtype, ignore.case = TRUE)]

  # Return aggregated counts — no need to carry full rows
  counts <- dt_vbo[, .N, by = woningtype]
  counts[, year := yr]
  counts
})

dt_agg <- rbindlist(agg_list)
dt_agg[, woningtype := factor(woningtype)]
message("  ", format(sum(dt_agg$N), big.mark = ","), " dwellings across ",
        length(years), " years")


# Plot ----

KLEUREN <- c("#004699", "#6cbd74", "#bed200", "#ff9100", "#009dec")

p1 <- ggplot(dt_agg, aes(x = year, y = N, fill = woningtype)) +
  geom_area(alpha = 0.85, colour = "white", linewidth = 0.2) +
  scale_x_continuous(breaks = years) +
  scale_y_continuous(labels = scales::label_comma()) +
  scale_fill_manual(values = KLEUREN,
                    guide  = guide_legend(ncol = 2, keyheight = 0.8)) +
  labs(title    = "Woningtypen in de woningvoorraad",
       subtitle = "Aantal per woningtype op 1 januari (Woonbase-simulatie)",
       x = NULL, y = "Aantal woningen", fill = NULL,
       caption  = "Bron: CBS Woonbase (gesimuleerd)") +
  theme(legend.position = "bottom",
        axis.text.x     = element_text(angle = 45, hjust = 1))

print(p1)
ggsave("plots/031_p1_woningtype_tijdreeks.png",
       p1, width = 8, height = 5, dpi = 150)
message("  p1 done")

message("Figure saved to plots/")
