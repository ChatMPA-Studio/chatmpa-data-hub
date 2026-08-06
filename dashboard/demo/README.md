# chatMPA Demo

Interactive proof-of-concept dashboard for 12 MPAs with LTEM + CONAPESCA data.

## Quick start

```bash
# From this directory:
python3 -m http.server 8080
# Open: http://localhost:8080/demo.html
```

`demo.html` loads `demo_data.json` via `fetch()` — a local server is required (direct `file://` opens fail due to CORS).

## What it shows

Click any of the 12 teal MPA polygons on the map. The right panel shows:

1. **Fish biomass** (T/ha) — mean + GAM trend (LTEM data)
2. **Invertebrate abundance** — 4 taxa stacked (Echinoidea, Asteroidea, Holaxonia, Scleractinia)
3. **Fishing pressure** — artisanal + industrial CPUE trend 2001–2026 (CONAPESCA, by region)
4. **KPI cards** — biomass, sea urchins, artisanal CPUE, gorgonians

Grey/muted polygons are MPAs that exist but have no pre-computed LTEM data.

## Files

| File | Size | What it is |
|------|------|-----------|
| `demo.html` | ~110 KB | Self-contained UI (Leaflet + Chart.js from CDN) |
| `demo_data.json` | ~1.1 MB | Pre-computed results for 12 MPAs |

## Data structure

`demo_data.json` top-level keys:
- `mpas` — GeoJSON of all MPA polygons
- `grid` — GeoJSON of prosperity grid (3,236 cells)
- `offices` — CONAPESCA fishing office locations (72 offices)
- `mpa_data` — per-MPA analysis results (LTEM biomass, invertebrates)
- `cpue_regions` — CONAPESCA CPUE aggregated by fishing region (6 regions)

See `../DASHBOARD.md` § 5 for the full JSON schema.

## Data freshness

Pre-computed from:
- LTEM surveys through 2025 (last survey season available)
- CONAPESCA landings 2001–2026 (as of 2026-07-15 snapshot)

## What is NOT in the demo

- SST anomaly and Chlorophyll-a (data not yet available locally)
- NRSI reef health index (skill exists; not pre-computed in demo)
- Species-specific CPUE (only fleet-aggregate is shown)
- Custom area of interest (user-drawn polygon)

## Biomass units

LTEM data is in **T/ha** (tonnes per hectare). The JSON field `mean_biomass_g_m2`
stores T/ha values — the field name is a legacy artifact. Display everywhere as T/ha.

Reference: Cabo Pulmo (well-recovered MPA) ≈ 0.09 T/ha. Unprotected reefs typically < 0.01 T/ha.

## CONAPESCA region assignment

Each MPA is assigned to a CONAPESCA fishing region by nearest coastal fishing office
(Haversine distance from MPA polygon centroid). This means all MPAs within the same
region share the same CPUE time series — CONAPESCA data is not georeferenced per MPA.

See `../../skills/per-database/conapesca-lfo-regions/references/lfo_region_lookup.csv` for the office → region mapping.
