source('scripts/000_project_init.R')
source("scripts/functions/read_sav_woonbase.R")

library(profvis)
library(rlang)

N  <- 1e6L   # target rows
YR <- 2023L


# Phase timing ----
# Time each stage separately so we know where the seconds go.
# Compares assemble WITH col_q (Option A, lazy labelling) vs without.

woonbase_reset()

t_params <- system.time(
  params <- woonbase_cbs_params(YR)
)

t_spine <- system.time(
  .wb$spine <- .wb_build_spine(
    n_persons = ceiling(N * 1.05),
    params    = params,
    seed      = 42L,
    year      = YR
  )
)

# Assemble all columns — baseline, Option A has no effect here
t_assemble_full <- system.time(
  dt_full <- .wb_assemble("populatie_pers", .wb$spine)
)

# Assemble with col_q — Option A skips ~28 labelling calls
col_q <- quo(c(RINOBJECTNUMMER1Jan, VBOWoningType1Jan))
t_assemble_colq <- system.time(
  dt_colq <- .wb_assemble("populatie_pers", .wb$spine, col_q = col_q)
)

# End-to-end read_sav with col_select (includes n_max trim + as_tibble)
t_readsav <- system.time({
  dt <- read_sav(
    file       = sprintf("WoonbasePopulatiePersonen%dV1", YR),
    col_select = c(RINOBJECTNUMMER1Jan, VBOWoningType1Jan)
  )
})

cat("\n── Timing breakdown ─────────────────────────────────────────────────\n")
cat(sprintf("  CBS params (woonbase_cbs_params)          : %5.2f s\n", t_params["elapsed"]))
cat(sprintf("  Spine build (.wb_build_spine)             : %5.2f s\n", t_spine["elapsed"]))
cat(sprintf("  Assemble full  (no col_q)                 : %5.2f s\n", t_assemble_full["elapsed"]))
cat(sprintf("  Assemble 2-col (col_q, Option A)          : %5.2f s\n", t_assemble_colq["elapsed"]))
cat(sprintf("  read_sav end-to-end (col_select, cached)  : %5.2f s\n", t_readsav["elapsed"]))
cat(sprintf("  ─────────────────────────────────────────\n"))
cat(sprintf("  woonbase_init + read_sav total            : %5.2f s\n",
            sum(c(t_spine, t_assemble_colq)["elapsed"])))
cat(sprintf("  Rows returned                             : %s\n\n", format(nrow(dt), big.mark = ",")))


# Spine sub-phase timing ----
# Break down .wb_build_spine into its three internal stages.

woonbase_reset()
set.seed(42L)
N_HH <- round(ceiling(N * 1.05) / params$avg_hh_size)

t_obj <- system.time({
  dt_obj <- data.table(
    RINOBJECTNUMMER   = .rand_id(N_HH, 16L),
    SOORTOBJECTNUMMER = .rcat(N_HH, names(params$soortobj_p), params$soortobj_p)
  )
  for (sfx in c("1Jan", "31Dec")) {
    gem <- .rcat(N_HH, params$gem_codes)
    set(dt_obj, j = paste0("GemeenteCodeJJJJ",  sfx), value = gem)
    set(dt_obj, j = paste0("VBOWoningType",     sfx), value = .rcat(N_HH, names(params$woningtype_p), params$woningtype_p))
    set(dt_obj, j = paste0("WOZWaardeObjectBAG",sfx), value = round(rlnorm(N_HH, log(300000), 0.50), -3L))
    set(dt_obj, j = paste0("VBOOppervlakte",    sfx), value = as.integer(pmax(15L, round(rlnorm(N_HH, log(85), 0.45)))))
    set(dt_obj, j = paste0("VBOBouwjaar",       sfx), value = sample(1850L:YR, N_HH, replace = TRUE))
    set(dt_obj, j = paste0("TypeEigenaar",      sfx), value = .rcat(N_HH, names(params$eigenaar_p), params$eigenaar_p))
  }
})

t_hh <- system.time({
  dt_hh <- data.table(
    HUISHOUDNR      = .seq_id(N_HH, 12L),
    TYPHH           = .rcat(N_HH, names(params$typhh_p), params$typhh_p),
    RINOBJECTNUMMER = dt_obj$RINOBJECTNUMMER
  )
  dt_hh[TYPHH == "1",           HHSize := 1L]
  dt_hh[TYPHH %in% c("2","3"),  HHSize := 2L]
  dt_hh[TYPHH %in% c("4","5"),  HHSize := 2L + sample(1:3, .N, replace = TRUE, prob = c(0.50,0.35,0.15))]
  dt_hh[TYPHH == "6",           HHSize := 1L + sample(1:3, .N, replace = TRUE, prob = c(0.55,0.30,0.15))]
  dt_hh[TYPHH == "7",           HHSize := sample(2:5,  .N, replace = TRUE)]
  dt_hh[TYPHH == "8",           HHSize := sample(5:25, .N, replace = TRUE)]
})

t_pers <- system.time({
  dt_pers <- dt_hh[rep(seq_len(N_HH), times = dt_hh$HHSize)]
  dt_pers[, rank := rowid(HUISHOUDNR)]
  N_P <- nrow(dt_pers)
  dt_pers[, PLHH := fcase(
    TYPHH == "1",                       "2",
    TYPHH == "2",                       "3",
    TYPHH == "3",                       "4",
    TYPHH == "4" & rank <= 2L,          "5",
    TYPHH == "5" & rank <= 2L,          "6",
    TYPHH %in% c("4","5") & rank > 2L,  "1",
    TYPHH == "6" & rank == 1L,          "7",
    TYPHH == "6" & rank > 1L,           "1",
    TYPHH == "7" & rank == 1L,          "8",
    TYPHH == "7" & rank > 1L,           "9",
    TYPHH == "8",                       "10"
  )]
  dt_pers[, GBAGeboorteJaar := fcase(
    PLHH == "1",  YR - sample(0L:17L,  N_P, replace = TRUE),
    TYPHH == "8", YR - sample(20L:85L, N_P, replace = TRUE),
    default =     YR - sample(20L:75L, N_P, replace = TRUE)
  )]
  dt_pers[, RINPERSOON := .rand_id(N_P, 9L)]
})

# Pin down the two main suspected bottlenecks inside the person phase
t_rand_id <- system.time(x <- .rand_id(N_P, 9L))
t_seq_id  <- system.time(x <- .seq_id(N_HH, 12L))
t_yyyymmdd <- system.time(
  x <- .yyyymmdd(sample(seq(as.Date("2010-01-01"), as.Date("2023-01-01"), by="day"),
                        N_P, replace=TRUE))
)

cat("── Spine sub-phase timing ────────────────────────────────────────────\n")
cat(sprintf("  Objects   : %5.2f s  (%s objects)\n",  t_obj["elapsed"],  format(N_HH,  big.mark = ",")))
cat(sprintf("  Households: %5.2f s  (%s HH)\n",       t_hh["elapsed"],   format(N_HH,  big.mark = ",")))
cat(sprintf("  Persons   : %5.2f s  (%s persons)\n",  t_pers["elapsed"], format(N_P,   big.mark = ",")))
cat(sprintf("\n  Within persons:\n"))
cat(sprintf("    .rand_id(%s, 9)     : %5.2f s\n", format(N_P,   big.mark=","), t_rand_id["elapsed"]))
cat(sprintf("    .seq_id(%s, 12)    : %5.2f s\n",  format(N_HH,  big.mark=","), t_seq_id["elapsed"]))
cat(sprintf("    .yyyymmdd(%s dates): %5.2f s\n\n", format(N_P,  big.mark=","), t_yyyymmdd["elapsed"]))


# profvis flame graph ----
# Run in RStudio — opens an interactive flame graph in the Viewer pane.

woonbase_reset()

p <- profvis({
  woonbase_init(year = YR, n = ceiling(N * 1.05), seed = 42L)
  dt <- read_sav(
    file       = sprintf("WoonbasePopulatiePersonen%dV1", YR),
    col_select = c(RINOBJECTNUMMER1Jan, VBOWoningType1Jan)
  )
}, interval = 0.02)   # 20 ms sampling interval for finer resolution

print(p)
