# temporal_align.R — shared temporal-alignment helper
#
# Exposes temporal_align() for use by skills that join multiple annual
# data sources on a common year axis.
#
# Two call forms:
#
#   1. Named list → inner-join intersection:
#      temporal_align(list(biomass = df1, nrsi = df2, chla = df3))
#      Returns: wide data.frame joined on `time` (year).
#      Attaches attribute `excluded_years` (list per source).
#
#   2. Single data.frame + unit → regularise a single series:
#      temporal_align(df, unit = "year")
#      Fills any missing integer years between min(time) and max(time)
#      with NA rows. Returns the completed series + attribute `filled_years`.

library(dplyr)
library(tidyr)

temporal_align <- function(data, unit = c("year", "month"), ...) {
  unit <- match.arg(unit)

  # ── Form 1: named list of data.frames ────────────────────────────────────
  if (is.list(data) && !is.data.frame(data)) {
    if (length(data) == 0) stop("temporal_align: data list is empty")
    if (is.null(names(data)) || any(names(data) == "")) {
      stop("temporal_align: all elements of data list must be named")
    }

    for (nm in names(data)) {
      if (!"time" %in% colnames(data[[nm]])) {
        stop("temporal_align: element '", nm, "' has no 'time' column")
      }
    }

    # Find year intersection across all sources
    year_sets <- lapply(data, function(df) sort(unique(df$time)))
    common    <- Reduce(intersect, year_sets)

    if (length(common) == 0) {
      stop("temporal_align: no overlapping years across input series. ",
           "Years per source: ",
           paste(names(year_sets), sapply(year_sets, function(y) paste(range(y), collapse="–")),
                 sep = "=", collapse = "; "))
    }

    # Report excluded years per source (for disclosure in skill output)
    excluded <- lapply(names(data), function(nm) {
      setdiff(year_sets[[nm]], common)
    })
    names(excluded) <- names(data)

    # Filter each source to common years, deduplicate on time if needed
    aligned <- lapply(names(data), function(nm) {
      df <- data[[nm]] |>
        filter(time %in% common) |>
        group_by(time) |>
        summarise(across(everything(), mean, na.rm = TRUE), .groups = "drop")
      colnames(df)[colnames(df) != "time"] <-
        paste0(nm, "_", colnames(df)[colnames(df) != "time"])
      df
    })

    result <- Reduce(function(a, b) full_join(a, b, by = "time"), aligned) |>
      arrange(time)

    attr(result, "common_years")   <- common
    attr(result, "excluded_years") <- excluded
    attr(result, "n_sources")      <- length(data)

    n_excl <- sum(sapply(excluded, length))
    if (n_excl > 0) {
      message("temporal_align: ", n_excl, " source-year combinations excluded ",
              "to reach ", length(common), "-year intersection. ",
              "See attr(result, 'excluded_years') for details.")
    }

    return(result)
  }

  # ── Form 2: single data.frame — regularise to complete time grid ──────────
  if (!is.data.frame(data)) stop("temporal_align: data must be a data.frame or named list of data.frames")
  if (!"time" %in% colnames(data)) stop("temporal_align: data must have a 'time' column")

  if (unit == "year") {
    full_grid <- data.frame(time = seq(min(data$time, na.rm = TRUE),
                                       max(data$time, na.rm = TRUE)))
    result <- full_join(full_grid, data, by = "time") |> arrange(time)
    filled <- setdiff(full_grid$time, data$time)
    attr(result, "filled_years") <- filled
    if (length(filled) > 0) {
      message("temporal_align: ", length(filled), " years filled with NA: ",
              paste(filled, collapse = ", "))
    }
  } else if (unit == "month") {
    all_months <- expand.grid(
      time  = seq(min(data$time, na.rm = TRUE), max(data$time, na.rm = TRUE)),
      month = 1:12
    )
    if (!"month" %in% colnames(data)) {
      stop("temporal_align: unit='month' requires a 'month' column in data")
    }
    result <- full_join(all_months, data, by = c("time", "month")) |>
      arrange(time, month)
    filled <- anti_join(all_months, data, by = c("time", "month"))
    attr(result, "filled_months") <- filled
  }

  result
}
