devtools::load_all(".")
sim_reset()

cat("=== Zonnestroominstallaties tests ===\n\n")

cat("--- 1. Basic generation ---\n")
sim_init("zonnestroominstallaties", year = 2023L, n = 200L, seed = 42L)
dt <- read_sav("Zonnnestroominstallaties2023V1")
cat(sprintf("  Rows: %d, Cols: %d\n", nrow(dt), ncol(dt)))
stopifnot(ncol(dt) == 28L)
stopifnot(nrow(dt) > 0L)
cat("  PASS\n\n")

cat("--- 2. Column types ---\n")
stopifnot(is.numeric(dt[["Vermogen_panelen"]]))
stopifnot(is.numeric(dt[["Jaarproductie"]]))
stopifnot(is.numeric(dt[["PC4"]]))
stopifnot(is.character(dt[["EAN_installatie_crypt"]]))
stopifnot(is.character(dt[["RINObjectnummer"]]))
stopifnot(haven::is.labelled(dt[["Type"]]))
stopifnot(haven::is.labelled(dt[["Actief_op_31_12"]]))
cat("  PASS\n\n")

cat("--- 3. Value ranges ---\n")
stopifnot(all(dt[["Vermogen_panelen"]] >= 0.5))
stopifnot(all(dt[["Jaarproductie"]] >= 0))
stopifnot(all(dt[["PC4"]] >= 1000 & dt[["PC4"]] <= 9999))
stopifnot(all(as.integer(dt[["Type"]]) %in% 1:3))
cat(sprintf("  Panel capacity: %.1f-%.1f kWp (mean %.1f)\n",
            min(dt[["Vermogen_panelen"]]), max(dt[["Vermogen_panelen"]]),
            mean(dt[["Vermogen_panelen"]])))
cat(sprintf("  Annual production: %.6f-%.6f GWh\n",
            min(dt[["Jaarproductie"]]), max(dt[["Jaarproductie"]])))
cat("  PASS\n\n")

cat("--- 4. Seasonal pattern ---\n")
months <- c("januari", "februari", "maart", "april", "mei", "juni",
            "juli", "augustus", "september", "oktober", "november", "december")
means <- sapply(months, function(m) mean(dt[[paste0("Productie_", m)]]))
cat(sprintf("  Monthly means (GWh): %s\n",
            paste(sprintf("%.6f", means), collapse = ", ")))
# Summer months should be higher than winter
stopifnot(means["juni"] > means["januari"])
stopifnot(means["juli"] > means["december"])
cat("  PASS: summer > winter\n\n")

cat("--- 5. Cross-link with energieverbruik ---\n")
sim_init("energieverbruik", year = 2023L, seed = 42L)
dt_ev <- read_sav("ENERGIEVERBRUIK2023TABV1",
                   col_select = c(RINOBJECTNUMMER, ZONPV, GAS, ELEK))
dt_ev <- as.data.table(dt_ev)
dt_solar <- as.data.table(dt)

joined <- merge(dt_solar, dt_ev, by.x = "RINObjectnummer",
                by.y = "RINOBJECTNUMMER")
cat(sprintf("  Solar installations: %d\n", nrow(dt_solar)))
cat(sprintf("  Energy dwellings: %d\n", nrow(dt_ev)))
cat(sprintf("  Joined: %d (%.0f%% match)\n", nrow(joined),
            nrow(joined) / nrow(dt_solar) * 100))
stopifnot(nrow(joined) > 0)
cat("  PASS\n\n")

cat("--- 6. col_select ---\n")
dt_sel <- read_sav("Zonnnestroominstallaties2023V1",
                    col_select = c(RINObjectnummer, Vermogen_panelen, Jaarproductie))
stopifnot(ncol(dt_sel) == 3L)
cat("  PASS\n\n")

cat("--- 7. Reproducibility ---\n")
sim_reset()
sim_init("zonnestroominstallaties", year = 2023L, n = 200L, seed = 42L)
dt2 <- read_sav("Zonnnestroominstallaties2023V1")
stopifnot(identical(dt[["Vermogen_panelen"]], dt2[["Vermogen_panelen"]]))
cat("  PASS\n\n")

cat("=== All zonnestroominstallaties tests passed ===\n")
