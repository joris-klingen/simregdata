# Vacant dwellings and unknown dwelling values ----
#
# The real woonbase holds dwellings without residents, and a few dwellings
# whose floor area or WOZ value is unknown. Both are added to the object
# spine after households, income and other attributes have been drawn, so
# they do not change any other simulated value. Shares are assumptions, not
# StatLine figures.

.VACANT_SHARE <- 0.015
.OPP_UNKNOWN_SHARE <- 0.005
.WOZ_UNKNOWN_SHARE <- 0.01
.WOZ_UNKNOWN <- 99999999999

# Copies of randomly chosen dwellings with new ids and no household. Ids and
# templates are hashed from the vacancy index, so they do not depend on the
# random stream; the template order is the keyed (sorted) object id.
.add_vacant_dwellings <- function(dt_obj, share = .VACANT_SHARE) {
  n_vac <- as.integer(round(nrow(dt_obj) * share))
  if (n_vac == 0L) return(dt_obj)
  i <- seq_len(n_vac)
  tpl <- 1L + floor(.hash_mix(i, "vacant_template") * nrow(dt_obj))
  vac <- dt_obj[tpl]
  vac[, RINOBJECTNUMMER := sprintf("%08.0f%08.0f",
    floor(.hash_mix(i, "vacant_id_a") * 1e8), floor(.hash_mix(i, "vacant_id_b") * 1e8))]
  vac <- vac[!RINOBJECTNUMMER %in% dt_obj$RINOBJECTNUMMER]
  out <- data.table::rbindlist(list(dt_obj, vac), use.names = TRUE)
  data.table::setkey(out, RINOBJECTNUMMER)
  out
}

# Unknown floor area (class 9, value empty) and WOZ value (class 9, value
# 99999999999), as coded in the woonbase files
.mask_unknown_dwelling_values <- function(dt_obj) {
  obj_id <- .hash_id_num(dt_obj$RINOBJECTNUMMER)
  unk_opp <- .hash_mix(obj_id, "obj_opp_unknown") < .OPP_UNKNOWN_SHARE
  unk_woz <- .hash_mix(obj_id, "obj_woz_unknown") < .WOZ_UNKNOWN_SHARE
  for (sfx in c("1Jan", "31Dec")) {
    data.table::set(dt_obj, which(unk_opp), paste0("VBOOppervlakte", sfx), NA_integer_)
    data.table::set(dt_obj, which(unk_opp), paste0("VBOOppervlakteKlasse", sfx), "9")
    woz_col <- paste0("WOZWaardeObjectBAG", sfx)
    if (is.integer(dt_obj[[woz_col]])) {
      data.table::set(dt_obj, j = woz_col, value = as.numeric(dt_obj[[woz_col]]))
    }
    data.table::set(dt_obj, which(unk_woz), woz_col, .WOZ_UNKNOWN)
    data.table::set(dt_obj, which(unk_woz), paste0("WOZWaardeObjectBAGKlasse", sfx), "9")
  }
  dt_obj
}
