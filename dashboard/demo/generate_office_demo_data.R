## generate_office_demo_data.R
## Extracts pre-computed demo data from CONAPESCA landings database
## for 5 focal offices → office_demo_data.json

library(data.table)
library(jsonlite)

# ── Paths ─────────────────────────────────────────────────────────────────────
DB_PATH  <- "C:/Users/carol/OneDrive/Documentos/CBMC/Projects/conapesca-database/outputs/conapesca_landings_2001_2026.rds"
OUT_PATH <- "C:/Users/carol/OneDrive/Documentos/CBMC/Projects/chatmpa-data-hub/dashboard/demo/office_demo_data.json"

# ── Load data ─────────────────────────────────────────────────────────────────
message("Loading database...")
dt <- readRDS(DB_PATH)
message("  Rows: ", nrow(dt))

# Ensure key columns are the right type
dt[, anio_corte              := as.integer(anio_corte)]
dt[, peso_desembarcado_kg    := as.numeric(peso_desembarcado_kg)]
dt[, valor_pesos_estimado    := as.numeric(valor_pesos_estimado)]
dt[, flag_fecha_generica            := as.logical(flag_fecha_generica)]
dt[, flag_dias_efectivos_sospechoso := as.logical(flag_dias_efectivos_sospechoso)]

# ── Helper: strip accents (for matching) ──────────────────────────────────────
strip_accents <- function(x) {
  x <- gsub("[áàäâ]", "a", x, ignore.case = FALSE)
  x <- gsub("[ÁÀÄÂ]", "A", x)
  x <- gsub("[éèëê]", "e", x, ignore.case = FALSE)
  x <- gsub("[ÉÈËÊ]", "E", x)
  x <- gsub("[íìïî]", "i", x, ignore.case = FALSE)
  x <- gsub("[ÍÌÏÎ]", "I", x)
  x <- gsub("[óòöô]", "o", x, ignore.case = FALSE)
  x <- gsub("[ÓÒÖÔ]", "O", x)
  x <- gsub("[úùüû]", "u", x, ignore.case = FALSE)
  x <- gsub("[ÚÙÜÛ]", "U", x)
  x <- gsub("[ñ]",    "n", x, ignore.case = FALSE)
  x <- gsub("[Ñ]",    "N", x)
  x
}

# ── Helper: resolve oficina spelling (accent-insensitive) ─────────────────────
resolve_oficina <- function(dt, oficina, estado) {
  # Try exact match first
  if (dt[nombre_estado == estado & nombre_oficina == oficina, .N] > 0) return(oficina)
  # Try accent-stripped match
  stripped_input  <- strip_accents(oficina)
  stripped_col    <- strip_accents(dt$nombre_oficina)
  estado_col      <- dt$nombre_estado
  candidates      <- unique(dt$nombre_oficina[estado_col == estado &
                             stripped_col == stripped_input])
  if (length(candidates) > 0) {
    message(sprintf("  Oficina spelling resolved: '%s' → '%s'", oficina, candidates[1]))
    return(candidates[1])
  }
  stop(sprintf("Oficina not found: %s | %s", oficina, estado))
}

# ── Helper: resolve recurso_demo (accent-insensitive) ─────────────────────────
resolve_recurso <- function(dt, oficina, estado, candidates) {
  db_recursos <- unique(dt[nombre_oficina == oficina & nombre_estado == estado,
                           nombre_principal])
  db_stripped <- strip_accents(db_recursos)

  for (r in candidates) {
    r_stripped <- strip_accents(r)
    # Exact match
    if (r %in% db_recursos) {
      message(sprintf("  recurso_demo resolved (exact): %s", r))
      return(r)
    }
    # Accent-stripped match
    idx <- which(db_stripped == r_stripped)
    if (length(idx) > 0) {
      actual <- db_recursos[idx[1]]
      message(sprintf("  recurso_demo resolved (stripped '%s' → '%s'): %s", r, actual, actual))
      return(actual)
    }
  }
  stop(sprintf("No recurso found for %s | %s among: %s", oficina, estado,
               paste(candidates, collapse = ", ")))
}

# ── Focal offices definition ───────────────────────────────────────────────────
offices_raw <- list(
  list(oficina = "CABO SAN LUCAS", estado = "BAJA CALIFORNIA SUR",
       recurso_candidates = c("DORADO", "JUREL", "PARGO"),
       region_id = 3L, region_name = "Golfo de California Sur y BCS"),
  list(oficina = "LA PAZ",         estado = "BAJA CALIFORNIA SUR",
       recurso_candidates = c("CAMARÓN", "CAMARON"),
       region_id = 3L, region_name = "Golfo de California Sur y BCS"),
  list(oficina = "MAZATLAN",       estado = "SINALOA",
       recurso_candidates = c("CAMARÓN", "CAMARON"),
       region_id = 4L, region_name = "Pacifico Nayarit-Guerrero"),
  list(oficina = "GUAYMAS",        estado = "SONORA",
       recurso_candidates = c("CAMARÓN", "CAMARON"),
       region_id = 1L, region_name = "Golfo de California Norte"),
  list(oficina = "ENSENADA",       estado = "BAJA CALIFORNIA",
       recurso_candidates = c("ABULÓN", "ABULON", "ERIZO"),
       region_id = 2L, region_name = "Pacifico Baja Norte")
)

# Resolve spellings and recursos
message("\n=== Resolving office and resource names ===")
offices <- lapply(offices_raw, function(o) {
  message(sprintf("Resolving: %s | %s", o$oficina, o$estado))
  o$oficina  <- resolve_oficina(dt, o$oficina, o$estado)
  o$recurso  <- resolve_recurso(dt, o$oficina, o$estado, o$recurso_candidates)
  o
})

# ── Computation helpers ────────────────────────────────────────────────────────

## 1. National Ranking ─────────────────────────────────────────────────────────
compute_ranking <- function(dt_input, focal_oficina, focal_estado) {
  agg <- dt_input[, .(
    total_toneladas = sum(peso_desembarcado_kg, na.rm = TRUE) / 1000,
    total_valor_mxn = sum(valor_pesos_estimado,  na.rm = TRUE)
  ), by = .(nombre_oficina, nombre_estado)]

  grand_vol   <- sum(agg$total_toneladas, na.rm = TRUE)
  grand_valor <- sum(agg$total_valor_mxn, na.rm = TRUE)

  agg[, rank_volumen := frankv(total_toneladas, order = -1L, ties.method = "min")]
  agg[, rank_valor   := frankv(total_valor_mxn,  order = -1L, ties.method = "min")]

  n_offices <- nrow(agg)
  row <- agg[nombre_oficina == focal_oficina & nombre_estado == focal_estado]

  if (nrow(row) == 0) {
    return(list(rank_volumen = NULL, rank_valor = NULL, n_offices = n_offices,
                pct_volumen = 0, pct_valor = 0,
                total_toneladas = 0, total_valor_mxn = 0))
  }
  list(
    rank_volumen    = as.integer(row$rank_volumen),
    rank_valor      = as.integer(row$rank_valor),
    n_offices       = as.integer(n_offices),
    pct_volumen     = round(row$total_toneladas / grand_vol   * 100, 2),
    pct_valor       = round(row$total_valor_mxn  / grand_valor * 100, 2),
    total_toneladas = round(row$total_toneladas, 0),
    total_valor_mxn = round(row$total_valor_mxn,  0)
  )
}

## 2. CPUE time series ──────────────────────────────────────────────────────────
compute_cpue <- function(dt_office) {
  dc <- dt_office[
    tipo_aviso %in% c("MAYORES", "MENORES") &
    (is.na(flag_fecha_generica)            | flag_fecha_generica == FALSE) &
    (is.na(flag_dias_efectivos_sospechoso) | flag_dias_efectivos_sospechoso == FALSE) &
    !is.na(dias_efectivos) &
    peso_desembarcado_kg > 0
  ]

  empty <- list(kpi_menores = NULL, kpi_mayores = NULL,
                years = list(), cpue_menores = list(), cpue_mayores = list(),
                n_menores = list(), n_mayores = list())

  if (nrow(dc) == 0) return(empty)

  # CPUE per folio (aggregate kg per folio first, then divide by dias_efectivos)
  by_folio <- dc[, .(
    total_kg      = sum(peso_desembarcado_kg, na.rm = TRUE),
    dias          = first(dias_efectivos),
    tipo_aviso    = first(tipo_aviso),
    anio_corte    = first(anio_corte)
  ), by = folio_aviso]
  by_folio[, cpue_folio := total_kg / dias]
  by_folio <- by_folio[is.finite(cpue_folio)]

  if (nrow(by_folio) == 0) return(empty)

  # Aggregate by year + fleet
  by_yr_fleet <- by_folio[, .(
    cpue_media = mean(cpue_folio, na.rm = TRUE),
    n_viajes   = .N
  ), by = .(anio_corte, tipo_aviso)]

  all_years <- sort(unique(by_yr_fleet$anio_corte))

  make_vec <- function(fleet) {
    sub <- by_yr_fleet[tipo_aviso == fleet]
    cpue_v <- sapply(all_years, function(y) {
      v <- sub[anio_corte == y, cpue_media]
      if (length(v) == 0 || is.na(v)) NA_real_ else round(v, 1)
    })
    n_v <- sapply(all_years, function(y) {
      v <- sub[anio_corte == y, n_viajes]
      if (length(v) == 0 || is.na(v)) NA_integer_ else as.integer(v)
    })
    list(cpue = as.list(cpue_v), n = as.list(n_v))
  }

  kpi_fleet <- function(fleet) {
    sub <- by_yr_fleet[tipo_aviso == fleet]
    if (nrow(sub) == 0) return(NULL)
    last5_yrs <- tail(sort(unique(sub$anio_corte)), 5)
    vals <- sub[anio_corte %in% last5_yrs, cpue_media]
    if (length(vals) == 0) return(NULL)
    round(mean(vals, na.rm = TRUE), 1)
  }

  may <- make_vec("MAYORES")
  men <- make_vec("MENORES")

  list(
    kpi_menores  = kpi_fleet("MENORES"),
    kpi_mayores  = kpi_fleet("MAYORES"),
    years        = as.list(all_years),
    cpue_menores = men$cpue,
    cpue_mayores = may$cpue,
    n_menores    = men$n,
    n_mayores    = may$n
  )
}

## 3. Landings time series ─────────────────────────────────────────────────────
compute_landings <- function(dt_office) {
  all_years <- sort(unique(dt_office$anio_corte))
  fleets    <- c("TOTAL", "MAYORES", "MENORES", "COSECHA")

  agg <- dt_office[, .(
    total_kg        = sum(peso_desembarcado_kg, na.rm = TRUE),
    total_valor_mxn = sum(valor_pesos_estimado,  na.rm = TRUE)
  ), by = .(anio_corte, tipo_aviso)]

  total_yr <- dt_office[, .(
    total_kg        = sum(peso_desembarcado_kg, na.rm = TRUE),
    total_valor_mxn = sum(valor_pesos_estimado,  na.rm = TRUE)
  ), by = anio_corte]

  get_series <- function(fleet) {
    if (fleet == "TOTAL") {
      src <- total_yr
    } else {
      src <- agg[tipo_aviso == fleet]
    }
    kg_v <- sapply(all_years, function(y) {
      v <- src[anio_corte == y, total_kg]
      if (length(v) == 0 || is.na(v)) NA_real_ else round(v, 0)
    })
    val_v <- sapply(all_years, function(y) {
      v <- src[anio_corte == y, total_valor_mxn]
      if (length(v) == 0 || is.na(v)) NA_real_ else round(v, 0)
    })
    list(total_kg = as.list(kg_v), total_valor_mxn = as.list(val_v))
  }

  result <- list(years = as.list(all_years))
  for (f in fleets) result[[f]] <- get_series(f)
  result
}

## 4. Catch composition ────────────────────────────────────────────────────────
compute_composition <- function(dt_office) {
  captura_kg  <- dt_office[tipo_aviso %in% c("MAYORES", "MENORES"),
                            sum(peso_desembarcado_kg, na.rm = TRUE)]
  cosecha_kg  <- dt_office[tipo_aviso == "COSECHA",
                            sum(peso_desembarcado_kg, na.rm = TRUE)]
  total_kg    <- captura_kg + cosecha_kg

  captura_val <- dt_office[tipo_aviso %in% c("MAYORES", "MENORES"),
                            sum(valor_pesos_estimado, na.rm = TRUE)]
  cosecha_val <- dt_office[tipo_aviso == "COSECHA",
                            sum(valor_pesos_estimado, na.rm = TRUE)]
  total_val   <- captura_val + cosecha_val

  safe_pct <- function(num, den) {
    if (is.na(den) || den == 0) return(NULL)
    round(num / den * 100, 2)
  }

  list(
    captura_pct_vol = safe_pct(captura_kg,  total_kg),
    cosecha_pct_vol = safe_pct(cosecha_kg,  total_kg),
    captura_pct_val = safe_pct(captura_val, total_val),
    cosecha_pct_val = safe_pct(cosecha_val, total_val)
  )
}

## 5. TMCA ─────────────────────────────────────────────────────────────────────
tmca_category <- function(x) {
  if (is.null(x) || is.na(x)) return("unknown")
  if (x >  3)  return("growing")
  if (x >  1)  return("growing moderately")
  if (x >= -1) return("stable")
  if (x >= -3) return("declining moderately")
  return("declining")
}

compute_tmca <- function(dt_office) {
  yr_total <- dt_office[, .(vol = sum(peso_desembarcado_kg, na.rm = TRUE) / 1000),
                         by = anio_corte]
  setkey(yr_total, anio_corte)

  yr_end   <- max(yr_total$anio_corte)
  yr_start <- yr_end - 10

  vol_end   <- yr_total[anio_corte == yr_end,   vol]
  vol_start <- yr_total[anio_corte == yr_start, vol]

  if (length(vol_end) == 0 || length(vol_start) == 0 ||
      is.na(vol_start) || is.na(vol_end) || vol_start == 0) {
    return(list(tmca = NULL, category = "unknown",
                yr_start = as.integer(yr_start), yr_end = as.integer(yr_end)))
  }

  tmca_val <- ((vol_end / vol_start)^(1/10) - 1) * 100
  list(
    tmca     = round(tmca_val, 2),
    category = tmca_category(tmca_val),
    yr_start = as.integer(yr_start),
    yr_end   = as.integer(yr_end)
  )
}

## Bundle all computations for one subset ─────────────────────────────────────
compute_block <- function(dt, focal_oficina, focal_estado, recurso = NULL) {
  if (is.null(recurso)) {
    dt_sub        <- dt[nombre_oficina == focal_oficina & nombre_estado == focal_estado]
    dt_rank_input <- dt
  } else {
    dt_sub        <- dt[nombre_oficina == focal_oficina &
                        nombre_estado  == focal_estado  &
                        nombre_principal == recurso]
    dt_rank_input <- dt[nombre_principal == recurso]
  }
  message(sprintf("    subset rows: %d", nrow(dt_sub)))

  ranking     <- compute_ranking(dt_rank_input, focal_oficina, focal_estado)
  cpue        <- compute_cpue(dt_sub)
  landings    <- compute_landings(dt_sub)
  composition <- compute_composition(dt_sub)
  tmca        <- compute_tmca(dt_sub)

  out <- list(
    ranking     = ranking,
    tmca        = tmca,
    cpue        = cpue,
    landings    = landings,
    composition = composition
  )
  if (!is.null(recurso)) out$nombre_principal <- recurso
  out
}

# ── Main loop ─────────────────────────────────────────────────────────────────
result <- list()

for (o in offices) {
  key <- paste0(o$oficina, "|", o$estado)
  message(sprintf("\n=== Processing: %s ===", key))

  message("  Computing ALL block...")
  all_block <- compute_block(dt, o$oficina, o$estado, recurso = NULL)

  message("  Computing RECURSO block (", o$recurso, ")...")
  rec_block <- compute_block(dt, o$oficina, o$estado, recurso = o$recurso)

  result[[key]] <- list(
    nombre_oficina = o$oficina,
    nombre_estado  = o$estado,
    region_id      = o$region_id,
    region_name    = o$region_name,
    recurso_demo   = o$recurso,
    all            = all_block,
    recurso        = rec_block
  )
}

# ── Serialise NaN → NA (jsonlite converts NA → null) ─────────────────────────
nan_to_na <- function(x) {
  if (is.list(x))    return(lapply(x, nan_to_na))
  if (is.numeric(x)) { x[is.nan(x)] <- NA_real_; return(x) }
  x
}
result <- nan_to_na(result)

# ── Write JSON ────────────────────────────────────────────────────────────────
message("\nWriting JSON to: ", OUT_PATH)
json_out <- toJSON(result, auto_unbox = TRUE, na = "null", pretty = TRUE, digits = NA)
writeLines(json_out, OUT_PATH)
message("Done. File size: ", file.info(OUT_PATH)$size, " bytes")

# ── Validation summary ────────────────────────────────────────────────────────
message("\n--- Validation summary ---")
for (key in names(result)) {
  o <- result[[key]]
  tmca_v <- o$all$tmca$tmca
  message(sprintf("  %s | recurso=%s | rank_vol=%s/%s | tmca=%s (%s)",
    key,
    o$recurso_demo,
    o$all$ranking$rank_volumen,
    o$all$ranking$n_offices,
    if (is.null(tmca_v)) "NA" else sprintf("%.2f", tmca_v),
    o$all$tmca$category))
}
message("\nAll done!")
