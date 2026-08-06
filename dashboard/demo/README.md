# chatMPA Demo

Interactive proof-of-concept dashboard for 12 MPAs with LTEM + CONAPESCA + SST + Chl-a data.

## Quick start

```bash
# From this directory:
python3 -m http.server 8080
# Open: http://localhost:8080/demo.html
```

`demo.html` loads `demo_data.json` via `fetch()` — a local server is required (direct `file://` opens fail due to CORS).

`chatMPA-site-standalone.html` is the full chatMPA site with the demo embedded. Open it directly in a browser (no server needed for the site shell), then navigate to the Demo section.

## What it shows

Click any of the 12 teal MPA polygons on the map. The right panel shows:

1. **6-card KPI grid** (3×2): Fish Biomass · Invertebrates · Art. CPUE · Ind. CPUE · SST · Chl-a
2. **Fish Biomass — Trophic Structure**: stacked area chart with 6 functional groups (T/ha). Falls back to GAM trend + CI band if functional group data is absent.
3. **Fishing Pressure**: artisanal + industrial CPUE KPIs and dual-line trend 2001–2026 (CONAPESCA, by region)
4. **Marine Environment**: Marine Heatwave bar+line chart (1982–2025, GoC MPAs only) and Chl-a annual time series (2004–2023)

Grey/muted polygons are MPAs that exist but have no pre-computed LTEM data.

## Files

| File | Size | What it is |
|------|------|-----------|
| `demo.html` | ~110 KB | Self-contained map + panel (Leaflet + Chart.js from CDN) |
| `chatMPA-site-standalone.html` | ~1.8 MB | Full chatMPA site with demo embedded and DEMO_DATA inlined |
| `demo_data.json` | ~1.1 MB | Pre-computed results for 12 MPAs |

## Data structure

`demo_data.json` top-level keys:
- `mpas` — GeoJSON of all MPA polygons
- `grid` — GeoJSON of prosperity grid (3,236 cells)
- `offices` — CONAPESCA fishing office locations (72 offices)
- `mpa_data` — per-MPA analysis results; keys per MPA:
  - `biomass` — LTEM fish biomass KPI + annual means + GAM trend
  - `functional_groups` — trophic group breakdown (6 groups, T/ha time series)
  - `invertebrates` — 4-taxon abundance KPIs + annual means (Echinoidea, Asteroidea, Holaxonia, Scleractinia)
  - `sst` — annual heatwave days + mean SST (GoC MPAs only; `null` otherwise)
  - `chl` — annual mean Chl-a mg/m³
- `cpue_regions` — CONAPESCA CPUE aggregated by fishing region (6 regions)

See `../DASHBOARD.md` § 5 for the full JSON schema.

## Data freshness

Pre-computed from:
- LTEM surveys through 2025 (last survey season available)
- CONAPESCA landings 2001–2026 (as of 2026-07-15 snapshot)
- SST: NOAA OISST daily 1982–2025
- Chl-a: MODIS-Aqua monthly 2004–2023

## SST / MHW coverage

SST and Marine Heatwave data are available only for MPAs within the Gulf of California OISST bbox (lon −115.875 to −105.875, lat 22.125 to 31.625). Three MPAs show `null` SST:
- Islas Marietas (~20.7°N, Pacific)
- Huatulco (~15.7°N, Pacific)
- Revillagigedo (~18–19°N, Pacific)

Their SST card shows a `GoC only` tag. All 12 MPAs have Chl-a data (MODIS covers the full coastal zone).

## What is NOT in the demo

- Invertebrate time-series charts (4-taxon GAM trends) — data is in JSON but not rendered in the current panel UI
- NRSI reef health index (skill exists; not pre-computed in demo)
- Species-specific CPUE (only fleet-aggregate MENORES/MAYORES)
- Custom area of interest (user-drawn polygon)
- Loading states (blank until data loads)

## Biomass units

LTEM data is in **T/ha** (tonnes per hectare). The JSON field `mean_biomass_g_m2` stores T/ha values — the field name is a legacy artifact. Display everywhere as T/ha.

Reference: Cabo Pulmo (well-recovered MPA) ≈ 0.09 T/ha. Unprotected reefs typically < 0.01 T/ha.

## CONAPESCA region assignment

Each MPA is assigned to a CONAPESCA fishing region by nearest coastal fishing office (Haversine distance from MPA polygon centroid). All MPAs in the same region share the same CPUE time series — CONAPESCA data is not georeferenced per MPA.

See `../../skills/per-database/conapesca-lfo-regions/references/lfo_region_lookup.csv` for the office → region mapping.
