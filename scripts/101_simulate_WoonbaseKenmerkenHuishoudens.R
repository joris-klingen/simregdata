# =============================================================================
# simulate_woonbase_huishoudens()
# Simulates data from: Woonbase Kenmerkenbestand Huishoudens
# (WoonbaseKenmerkenHuishoudens), as documented by CBS Microdata Services.
#
# Mimics the interface of haven::read_sav(), supporting:
#   - col_select   : tidy-select column selection (names, indices, or tidyselect)
#   - n_max        : maximum number of rows to return (like read_sav's n_max)
#   - skip         : number of rows to skip before reading
#   - year         : reference year for simulated dates (default: 2023)
#   - seed         : random seed for reproducibility
#
# Variable structure follows the CBS documentation (16 variables, A1-A12 formats).
# Distributions are calibrated to realistic Dutch household compositions.
# =============================================================================

simulate_woonbase_huishoudens <- function(
    n            = 10000L,   # total rows to generate (persons in households)
    n_max        = Inf,      # max rows to *return* (like haven::read_sav)
    skip         = 0L,       # rows to skip before returning
    col_select   = NULL,     # tidy-select: NULL = all columns
    year         = 2023L,    # reference year for date generation
    seed         = NULL      # set for reproducibility
) {
  
  # ── dependencies ────────────────────────────────────────────────────────────
  need <- c("dplyr", "tibble", "tidyselect", "haven", "rlang")
  missing_pkgs <- need[!vapply(need, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing_pkgs)) {
    stop("Please install required packages: ",
         paste(missing_pkgs, collapse = ", "),
         "\n  install.packages(c(", paste0('"', missing_pkgs, '"', collapse = ", "), "))")
  }
  
  if (!is.null(seed)) set.seed(seed)
  
  n <- as.integer(n)
  
  # ── 1. Household type distribution (calibrated to NL ~2023) ─────────────────
  # Types: 1=single, 2=unwed no kids, 3=married no kids, 4=unwed+kids,
  #        5=married+kids, 6=single parent, 7=other, 8=institutional
  hh_type_probs <- c(
    "1" = 0.38,   # single-person (largest group in NL)
    "2" = 0.13,   # unwed couple, no children
    "3" = 0.12,   # married couple, no children
    "4" = 0.07,   # unwed couple, with children
    "5" = 0.17,   # married couple, with children
    "6" = 0.07,   # single-parent
    "7" = 0.03,   # other private
    "8" = 0.03    # institutional
  )
  
  # ── 2. Generate household pool ───────────────────────────────────────────────
  # Persons per household type (Jan)
  persons_per_type <- list(
    "1" = 1L,
    "2" = function() sample(2L:3L, 1, prob = c(0.85, 0.15)),
    "3" = function() sample(2L:3L, 1, prob = c(0.85, 0.15)),
    "4" = function() sample(3L:5L, 1, prob = c(0.4, 0.35, 0.25)),
    "5" = function() sample(3L:6L, 1, prob = c(0.35, 0.35, 0.20, 0.10)),
    "6" = function() sample(2L:4L, 1, prob = c(0.5, 0.35, 0.15)),
    "7" = function() sample(2L:4L, 1, prob = c(0.5, 0.35, 0.15)),
    "8" = function() sample(5L:80L, 1)
  )
  
  children_per_type <- list(
    "1" = 0L, "2" = 0L, "3" = 0L,
    "4" = function(np) sample(1L:(np - 2L), 1),
    "5" = function(np) sample(1L:(np - 2L), 1),
    "6" = function(np) sample(1L:(np - 1L), 1),
    "7" = 0L,
    "8" = 0L   # not applicable
  )
  
  # ── helper: generate one household ──────────────────────────────────────────
  make_household <- function(hh_idx) {
    hh_type_jan <- sample(names(hh_type_probs), 1, prob = hh_type_probs)
    
    # Small probability household type changes over the year
    hh_type_dec <- if (runif(1) < 0.05) {
      sample(names(hh_type_probs), 1, prob = hh_type_probs)
    } else {
      hh_type_jan
    }
    
    # Number of persons (Jan)
    n_persons_jan <- if (is.function(persons_per_type[[hh_type_jan]])) {
      persons_per_type[[hh_type_jan]]()
    } else {
      persons_per_type[[hh_type_jan]]
    }
    
    # Children (Jan)
    n_children_jan <- if (is.function(children_per_type[[hh_type_jan]])) {
      children_per_type[[hh_type_jan]](n_persons_jan)
    } else {
      children_per_type[[hh_type_jan]]
    }
    
    # Dec values (may differ slightly)
    changed <- runif(1) < 0.03
    n_persons_dec <- if (changed) max(1L, n_persons_jan + sample(c(-1L, 1L), 1)) else n_persons_jan
    n_children_dec <- if (changed && n_children_jan > 0) max(0L, n_children_jan + sample(c(-1L, 0L, 1L), 1)) else n_children_jan
    
    # Household ID and start dates
    hh_id_jan  <- sprintf("%012d", hh_idx * 10L)
    start_jan  <- as.integer(format(
      as.Date(paste0(year, "-01-01")) - sample(0L:3650L, 1),
      "%Y%m%d"
    ))
    
    # Dec household: same or new (if something changed)
    hh_changed <- runif(1) < 0.04
    hh_id_dec  <- if (hh_changed) sprintf("%012d", hh_idx * 10L + 1L) else hh_id_jan
    start_dec  <- if (hh_changed) {
      as.integer(format(
        as.Date(paste0(year, "-07-01")) - sample(0L:180L, 1),
        "%Y%m%d"
      ))
    } else {
      start_jan
    }
    
    # Imputation (~95% = 0)
    imp_jan <- sample(c(0L, 1L), 1, prob = c(0.95, 0.05))
    imp_dec <- sample(c(0L, 1L), 1, prob = c(0.95, 0.05))
    
    # Reference person logic per CBS rules
    # For institutional households → REFPERSOONHH = 9
    # For private: one person gets 1, rest get 0
    is_institutional <- hh_type_jan == "8"
    
    list(
      hh_id_jan     = hh_id_jan,
      hh_id_dec     = hh_id_dec,
      start_jan     = start_jan,
      start_dec     = start_dec,
      imp_jan       = imp_jan,
      imp_dec       = imp_dec,
      n_persons_jan = n_persons_jan,
      n_persons_dec = n_persons_dec,
      n_children_jan = n_children_jan,
      n_children_dec = n_children_dec,
      hh_type_jan   = hh_type_jan,
      hh_type_dec   = hh_type_dec,
      is_institutional = is_institutional
    )
  }
  
  # ── 3. Build person-level rows ───────────────────────────────────────────────
  rows <- vector("list", n)
  hh_idx   <- 1L
  row_idx  <- 1L
  
  while (row_idx <= n) {
    hh <- make_household(hh_idx)
    np <- hh$n_persons_jan
    
    # Don't overflow
    persons_to_add <- min(np, n - row_idx + 1L)
    
    for (p in seq_len(persons_to_add)) {
      # Reference person: first person in private HH = 1, institutional = 9
      ref_jan <- if (hh$is_institutional) "9" else if (p == 1L) "1" else "0"
      ref_dec <- if (hh$hh_type_dec == "8") "9" else if (p == 1L) "1" else "0"
      
      # RINPERSOON: 9-digit pseudonymous ID
      rin <- sprintf("%09d", row_idx * 7L + sample(1L:999L, 1))
      
      rows[[row_idx]] <- list(
        HUISHOUDNR1Jan                  = hh$hh_id_jan,
        HUISHOUDNR31Dec                 = hh$hh_id_dec,
        DatumAanvangHH1Jan              = as.character(hh$start_jan),
        DatumAanvangHH31Dec             = as.character(hh$start_dec),
        IMPUTATIECODEHH1Jan             = as.character(hh$imp_jan),
        IMPUTATIECODEHH31Dec            = as.character(hh$imp_dec),
        RefPersoonHH1Jan                = ref_jan,
        RefPersoonHH31Dec               = ref_dec,
        RINPERSOON                      = rin,
        RINPERSOONS                     = "R",
        TYPHH1Jan                       = hh$hh_type_jan,
        TYPHH31Dec                      = hh$hh_type_dec,
        AantalKinderenPerHuishouden1Jan = if (hh$n_children_jan == 0L) "--" else sprintf("%2d", hh$n_children_jan),
        AantalKinderenPerHuishouden31Dec = if (hh$n_children_dec == 0L) "--" else sprintf("%2d", hh$n_children_dec),
        AantalPersonenPerHuishouden1Jan = sprintf("%4d", hh$n_persons_jan),
        AantalPersonenPerHuishouden31Dec = sprintf("%4d", hh$n_persons_dec)
      )
      row_idx <- row_idx + 1L
    }
    
    hh_idx <- hh_idx + 1L
  }
  
  df <- tibble::as_tibble(do.call(rbind, lapply(rows, as.data.frame,
                                                stringsAsFactors = FALSE)))
  
  # ── 4. Attach haven-style labelled attributes (mimics read_sav output) ───────
  label_col <- function(df, col, label, labels = NULL) {
    attr(df[[col]], "label") <- label
    if (!is.null(labels)) {
      df[[col]] <- haven::labelled(df[[col]], labels = labels, label = label)
    }
    df
  }
  
  df <- label_col(df, "HUISHOUDNR1Jan",
                  "Uniek identificatienummer huishouden op peilmoment 1 januari")
  df <- label_col(df, "HUISHOUDNR31Dec",
                  "Uniek identificatienummer huishouden op peilmoment 31 december")
  df <- label_col(df, "DatumAanvangHH1Jan",
                  "Aanvangsdatum huishouden geldig 1 januari (JJJJMMDD)")
  df <- label_col(df, "DatumAanvangHH31Dec",
                  "Aanvangsdatum huishouden geldig 31 december (JJJJMMDD)")
  
  df <- label_col(df, "IMPUTATIECODEHH1Jan",
                  "Huishouden is wel/niet geimputeerd (1 januari)",
                  labels = c("nee" = "0", "ja" = "1"))
  df <- label_col(df, "IMPUTATIECODEHH31Dec",
                  "Huishouden is wel/niet geimputeerd (31 december)",
                  labels = c("nee" = "0", "ja" = "1"))
  
  df <- label_col(df, "RefPersoonHH1Jan",
                  "Referentiepersoon in het huishouden (1 januari)",
                  labels = c("nee" = "0", "ja" = "1",
                             "nee, persoon in institutioneel huishouden" = "9"))
  df <- label_col(df, "RefPersoonHH31Dec",
                  "Referentiepersoon in het huishouden (31 december)",
                  labels = c("nee" = "0", "ja" = "1",
                             "nee, persoon in institutioneel huishouden" = "9"))
  
  df <- label_col(df, "RINPERSOON",
                  "Pseudoniem persoonsnummer (samen met RINPERSOONS uniek)")
  df <- label_col(df, "RINPERSOONS",
                  "Bron persoonsnummer",
                  labels = c("RINPERSOON WEL IN GBA" = "R"))
  
  hh_type_labels <- c(
    "Eenpersoonshuishouden"          = "1",
    "Niet-gehuwd paar zonder kinderen" = "2",
    "Gehuwd paar zonder kinderen"    = "3",
    "Niet-gehuwd paar met kinderen"  = "4",
    "Gehuwd paar met kinderen"       = "5",
    "Eenouderhuishouden"             = "6",
    "Overig huishouden"              = "7",
    "Institutioneel huishouden"      = "8"
  )
  df <- label_col(df, "TYPHH1Jan",
                  "Type huishouden (1 januari)", labels = hh_type_labels)
  df <- label_col(df, "TYPHH31Dec",
                  "Type huishouden (31 december)", labels = hh_type_labels)
  
  df <- label_col(df, "AantalKinderenPerHuishouden1Jan",
                  "Aantal thuiswonende kinderen (1 januari); '--' = geen kinderen")
  df <- label_col(df, "AantalKinderenPerHuishouden31Dec",
                  "Aantal thuiswonende kinderen (31 december); '--' = geen kinderen")
  df <- label_col(df, "AantalPersonenPerHuishouden1Jan",
                  "Aantal personen in het huishouden (1 januari)")
  df <- label_col(df, "AantalPersonenPerHuishouden31Dec",
                  "Aantal personen in het huishouden (31 december)")
  
  # ── 5. Apply skip / n_max (mirrors read_sav behaviour) ──────────────────────
  skip  <- as.integer(skip)
  n_max <- if (is.infinite(n_max)) nrow(df) else as.integer(n_max)
  
  start_row <- skip + 1L
  end_row   <- min(skip + n_max, nrow(df))
  
  if (start_row > nrow(df)) {
    df <- df[integer(0), ]
  } else {
    df <- df[start_row:end_row, ]
  }
  
  # ── 6. Column selection (mirrors read_sav col_select) ───────────────────────
  if (!is.null(col_select)) {
    sel <- tidyselect::eval_select(rlang::enquo(col_select), df,
                                   allow_rename = FALSE)
    df <- df[, sel, drop = FALSE]
  }
  
  # ── 7. Attach file-level metadata (as haven::read_sav does) ─────────────────
  attr(df, "label")    <- "Woonbase Kenmerkenbestand Huishoudens"
  attr(df, "source")   <- "Simulated — CBS Microdata Services documentation (27 nov 2025)"
  attr(df, "encoding") <- "UTF-8"
  
  df
}


# =============================================================================
# USAGE EXAMPLES
# =============================================================================
if (FALSE) {
  
  # Basic usage — 5 000 simulated person records
  df <- simulate_woonbase_huishoudens(n = 5000, seed = 42)
  dplyr::glimpse(df)
  
  # Like read_sav(): limit rows and skip
  df_small <- simulate_woonbase_huishoudens(n = 10000, n_max = 500, skip = 100, seed = 1)
  
  # Column selection (tidyselect, just like read_sav col_select)
  df_cols <- simulate_woonbase_huishoudens(
    n          = 2000,
    col_select = c(RINPERSOON, TYPHH1Jan, TYPHH31Dec,
                   AantalPersonenPerHuishouden1Jan),
    seed       = 7
  )
  
  # Count private households on Jan 1 (reference person trick from CBS docs)
  library(dplyr)
  df %>%
    filter(RefPersoonHH1Jan == "1") %>%
    count(TYPHH1Jan)
  
  # Proportion imputed
  df %>%
    count(IMPUTATIECODEHH1Jan) %>%
    mutate(pct = n / sum(n))
  
  # Inspect haven labels
  haven::print_labels(df$TYPHH1Jan)
}
