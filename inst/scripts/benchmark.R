library(simcbsradata)
library(data.table)
library(profvis)
library(rlang)

N  <- 1e6L   # target rows
YR <- 2023L


# Phase timing ----

woonbase_reset()

t_params <- system.time(
  params <- woonbase_cbs_params(YR)
)

t_spine <- system.time(
  woonbase_init(year = YR, n = ceiling(N * 1.05), seed = 42L)
)

# End-to-end read_sav with col_select (includes n_max trim + as_tibble)
t_readsav <- system.time({
  dt <- read_sav(
    file       = sprintf("WoonbasePopulatiePersonen%dV1", YR),
    col_select = c(RINOBJECTNUMMER1Jan, VBOWoningType1Jan)
  )
})

cat("\n-- Timing breakdown ---------------------------------------------------\n")
cat(sprintf("  CBS params (woonbase_cbs_params)          : %5.2f s\n", t_params["elapsed"]))
cat(sprintf("  Spine build (woonbase_init)               : %5.2f s\n", t_spine["elapsed"]))
cat(sprintf("  read_sav end-to-end (col_select, cached)  : %5.2f s\n", t_readsav["elapsed"]))
cat(sprintf("  Rows returned                             : %s\n\n", format(nrow(dt), big.mark = ",")))


# profvis flame graph ----

woonbase_reset()

p <- profvis({
  woonbase_init(year = YR, n = ceiling(N * 1.05), seed = 42L)
  dt <- read_sav(
    file       = sprintf("WoonbasePopulatiePersonen%dV1", YR),
    col_select = c(RINOBJECTNUMMER1Jan, VBOWoningType1Jan)
  )
}, interval = 0.02)

print(p)
