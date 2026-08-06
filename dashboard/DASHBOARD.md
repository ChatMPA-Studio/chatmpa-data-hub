# chatMPA Dashboard — Display Specification

**Audience:** Front-end engineers building the chatMPA prototype dashboard.  
**Purpose:** Defines exactly what to display in the interface, for each data source, in each panel — without requiring any marine ecology knowledge.

---

## 1. Interface architecture

```
┌─────────────────── Top nav (68px) ──────────────────────────┐
│  chatMPA  [Demo]   Mission  How it works  Innovation …       │
└─────────────────────────────────────────────────────────────┘
┌──────────────── Map (flex: 1) ──────────────────┬── Panel (380px) ──┐
│                                                  │                   │
│   [MPA polygons]   [Prosperity grid]             │  (empty state)    │
│   [Fishing office dots]                          │  ← click an MPA   │
│                                                  │                   │
│   [Layer toggles top-right]                      │  (panel content)  │
│   [Legend bottom-left]                           │  when MPA clicked │
└──────────────────────────────────────────────────┴───────────────────┘
```

Two-column layout. Left: Leaflet map (full remaining height). Right: fixed 380 px scrollable panel that populates when a user clicks an MPA polygon.

---

## 2. Map layers

| Layer | What it shows | Toggle? | Default |
|-------|--------------|---------|---------|
| **MPA polygons** | Protected area boundaries, color-coded by data availability | Yes | ON |
| **Prosperity grid** | 0.05° coastal grid cells (3,236 total); teal inside an MPA, grey outside | Yes | ON |
| **Fishing offices** | Circle markers for 72 artisanal landing offices, colored by CONAPESCA region | Yes | ON |

### MPA polygon styles

| State | Fill | Border | Weight |
|-------|------|--------|--------|
| Has LTEM data | `#1D496B` at 28% opacity | `#0E82A8` | 1.6 px |
| No LTEM data | `#6488AC` at 10% opacity | `#9DB6CE` | 0.8 px |
| Selected (clicked) | `#0B2338` at 55% opacity | `#1E9EC4` | 2.5 px |

### Fishing office colors (by CONAPESCA region)

| Region ID | Name | Color |
|-----------|------|-------|
| 1 | Golfo de California Norte | `#1E9EC4` |
| 2 | Pacífico Baja Norte | `#0B2338` |
| 3 | Golfo de California Sur y BCS | `#21925F` |
| 4 | Pacífico Nayarit-Guerrero | `#C6892A` |
| 6 | Pacífico Central | `#7C5A93` |
| 7 | Pacífico Sur (Oaxaca-Chiapas) | `#CC4C43` |

Region 5 (inland freshwater offices) is excluded from the map.

---

## 3. MPA side panel

When the user clicks an MPA polygon, the right panel fills with data. Content is organized as stacked sections from top to bottom:

```
┌─────────────────────────────────────────┐
│ [badge] Marine Protected Area           │
│ Name of the MPA                         │  ← panel header
│ Category · LTEM: <region name>          │
├────────┬────────┬────────┬──────────────┤
│BIOMASS │INVERTS │ART.    │ IND.         │  ← KPI grid (6 cards, 3×2)
│x.xx    │xx ind  │CPUE    │ CPUE         │
│T/ha    │/transect│xxx    │ xxx kg/day   │
├────────┼────────┼────────┼──────────────┤
│ SST    │ Chl-a  │        │              │
│xx.x °C │x.xxx   │        │              │
│        │mg/m³   │        │              │
├─────────────────────────────────────────┤
│ Fish Biomass — Trophic Structure (T/ha) │  ← stacked area chart
│ [6 functional groups, stacked]          │    (GAM trend fallback if
│                                         │     no functional group data)
├─────────────────────────────────────────┤
│ Fishing Pressure · [Region badge]       │  ← CPUE section
│ ARTISANAL  xxx kg/day                   │
│ INDUSTRIAL xxx kg/day                   │
│ CPUE Trend 2001–2026 [dual line chart]  │
├─────────────────────────────────────────┤
│ Marine Environment                      │  ← environment section
│ Marine Heatwaves [bar + line chart]     │
│ Chlorophyll-a [line chart]              │
└─────────────────────────────────────────┘
```

### 3.1 Panel header

| Element | Value |
|---------|-------|
| Badge label | `"Marine Protected Area"` (green, always) |
| Title | MPA name (from shapefile `nombre_amp` field) |
| Subtitle | `{categoria}  ·  LTEM: {ltem_region}` (omit LTEM part if no data) |

---

### 3.2 KPI grid — 6 cards in a 3×2 grid

Each card has: **label** (10px uppercase), **value** (18px bold), **unit** (10px), **sub** (10px smaller note).

#### Card 1 — Fish Biomass
| Field | Content |
|-------|---------|
| Label | `FISH BIOMASS` |
| Value | `{mean_biomass_g_m2}` rounded to 2 decimals |
| Unit | `T / ha` |
| Sub | `Mean · 5-yr surveys · LTEM` |
| Source | `ltem-fish-biomass` → `mpa_data[name].biomass.kpi.mean_biomass_g_m2` |
| If no data | Show `—` |

> **T/ha**: tonnes per hectare. Cabo Pulmo (well-recovered MPA) ≈ 0.09 T/ha. Unprotected reefs typically < 0.01 T/ha.

#### Card 2 — Invertebrates
| Field | Content |
|-------|---------|
| Label | `INVERTEBRATES` |
| Value | Echinoidea `mean_abundance_per_transect`, 1 decimal |
| Unit | `ind. / transect` |
| Sub | `Echinoidea · LTEM` |
| Source | `mpa_data[name].invertebrates.Echinoidea.kpi.mean_abundance_per_transect` |
| If no data | Show `—` |

> Echinoidea (sea urchins) are used as the single representative invertebrate KPI — most abundant and ecologically significant. Full 4-taxon time series appears in the CPUE section's sibling invertebrate skill output.

#### Card 3 — Art. CPUE
| Field | Content |
|-------|---------|
| Label | `ART. CPUE` |
| Value | `{kpi_menores_mean_cpue}` rounded to integer |
| Unit | `kg / eff. day` |
| Sub | `MENORES · 5-yr · {region_name}` |
| Source | `cpue_regions[conapesca_region_id].kpi_menores_mean_cpue` |
| If no data | Show `—` |

#### Card 4 — Ind. CPUE
| Field | Content |
|-------|---------|
| Label | `IND. CPUE` |
| Value | `{kpi_mayores_mean_cpue}` rounded to integer |
| Unit | `kg / eff. day` |
| Sub | `MAYORES · 5-yr · {region_name}` |
| Source | `cpue_regions[conapesca_region_id].kpi_mayores_mean_cpue` |
| If no data | Show `—` |

#### Card 5 — SST
| Field | Content |
|-------|---------|
| Label | `SST` |
| Value | `{kpi_mean_sst_c}` rounded to 1 decimal |
| Unit | `°C · OISST` |
| Sub | `{kpi_years} · {kpi_mhw_days_per_yr} MHW days/yr` |
| Source | `mpa_data[name].sst` |
| If outside GoC | Show `—` with tag `GoC only` (SST data covers Gulf of California only) |

> SST coverage: lon −115.875 to −105.875, lat 22.125 to 31.625 (OISST). MPAs outside this bbox (Islas Marietas, Huatulco, Revillagigedo) show the "GoC only" tag.

#### Card 6 — Chl-a
| Field | Content |
|-------|---------|
| Label | `CHL-A` |
| Value | `{kpi_mean_chla_mg_m3}` rounded to 3 decimals |
| Unit | `mg/m³ · MODIS` |
| Sub | `{kpi_years} · annual mean` |
| Source | `mpa_data[name].chl` |
| If no data | Show `—` with tag `no data` |

---

### 3.3 Fish Biomass — Trophic Structure chart

**Primary display (when `functional_groups` data exists):**

**Chart type:** Stacked area chart  
**Library:** Chart.js  
**Height:** 190 px

| Element | Detail |
|---------|--------|
| X axis | Year (integer) |
| Y axis | Fish biomass in **T/ha** (label: `T/ha`), stacked |
| Series | 6 trophic functional groups (see color table below) |
| Fill | Each series filled with 80% opacity of group color |
| Border | Group color, 0.8 px |
| Tension | 0.3 (slight smoothing) |
| Points | Hidden (`pointRadius: 0`) |
| Legend | Bottom, 9px font, reversed order (top group on right) |
| Stack | Chart.js `stack: 'biomass'` on both axes |

**Trophic functional groups (in stacking order, bottom to top):**

| Group key | Spanish label | Color |
|-----------|--------------|-------|
| `GenPred_solitary` | Depredadores solitarios | `#D73027` |
| `GenPred_schooling` | Depredadores en cardúmenes | `#FC8D59` |
| `EpiBent_schooling` | Omnívoros en cardúmen | `#FEE08B` |
| `Crip_schooling` | Herbívoros en cardúmen | `#91BFDB` |
| `Crip_solitary` | Crípticos solitarios | `#4575B4` |
| `Plank` | Planctívoros | `#313695` |

**Fallback (when `functional_groups` is absent but `biomass` exists):**

Show the GAM trend chart instead (scatter + smooth line + 95% CI band), same as the old design:

| Element | Detail |
|---------|--------|
| Height | 150 px |
| Scatter | Observed annual means — `#0B2338`, white border, 4 px |
| Trend line | GAM fit — `#1E9EC4`, 2 px |
| CI band | `rgba(30,158,196,0.15)` between `lwr` and `upr` |
| Sub-label | `GAM dev.expl.: {dev_expl_pct}%` in grey (10px) |

---

### 3.4 Fishing Pressure — CONAPESCA section

**KPI row (2 cards side by side):**

| Card | Label | Value | Unit | Sub |
|------|-------|-------|------|-----|
| Left | `ARTISANAL` (green tag) | `{kpi_menores_mean_cpue}` | `kg / effective day` | `MENORES · 5-yr mean` |
| Right | `INDUSTRIAL` (amber tag) | `{kpi_mayores_mean_cpue}` | `kg / effective day` | `MAYORES · 5-yr mean` |

**CPUE Trend chart (2001–2026):**

| Element | Detail |
|---------|--------|
| Height | 130 px |
| Line 1 | MENORES (artisanal) — `#21925F` solid, 1.8 px |
| Line 2 | MAYORES (industrial) — `#C6892A` dashed (4,3), 1.8 px |
| X axis | Year |
| Y axis | kg / effective day |
| Legend | Bottom, 9px font |

**Region badge:** Pill-shaped badge with a small teal dot and region name (e.g., `GoC Sur y BCS`) above the KPI row.

**Data note:** CPUE is regional, not per-MPA. All MPAs in the same CONAPESCA region share the same time series.

| Region | MPAs in demo |
|--------|-------------|
| GoC Norte (R1) | Alto Golfo |
| Pac. Baja Norte (R2) | El Vizcaíno |
| GoC Sur y BCS (R3) | Cabo Pulmo, Bahía de Loreto, Espíritu Santo, Balandra, Cabo San Lucas, Revillagigedo, Ventilas Hidrotermales |
| Pac. Nayarit-Guerrero (R4) | Islas Marietas, Islas Marías |
| Pac. Sur (R7) | Huatulco |

---

### 3.5 Marine Environment section

Two charts stacked vertically. Both are optional — render only when data is available.

#### 3.5.1 Marine Heatwaves (MHW) chart

**Chart type:** Combo — bars (heatwave days) + line (mean SST)  
**Height:** 130 px  
**Shown when:** `mpa_data[name].sst` exists (GoC MPAs only)

| Element | Detail |
|---------|--------|
| Bars | Annual heatwave days/yr — `rgba(204,76,67,0.65)` fill, left Y axis |
| Line | Annual mean SST °C — `#1E9EC4`, 1.5 px, right Y axis |
| X axis | Year (1982–2025) |
| Left Y label | `MHW days` |
| Right Y label | `°C` |
| Legend | Bottom, 9px |
| Note below chart | `Baseline: 1998–2011 · min 5 consecutive days (Hobday et al. 2016)` |

> MHW = Marine Heatwave. A day counts as a heatwave day when SST exceeds the local 90th percentile for ≥ 5 consecutive days. Detection uses the `heatwaveR` R package with OISST daily data.

#### 3.5.2 Chlorophyll-a time series

**Chart type:** Line chart with area fill  
**Height:** 130 px  
**Shown when:** `mpa_data[name].chl` exists

| Element | Detail |
|---------|--------|
| Line | Annual mean Chl-a — `#21925F`, 1.8 px |
| Fill | `rgba(33,146,95,0.12)` under the line |
| X axis | Year (2004–2023) |
| Y label | `mg/m³` |
| Tension | 0.3 |
| Points | 2.5 px radius, `#21925F` |
| Note below chart | `Monthly composites averaged annually · mg m⁻³` |

---

## 4. Data availability

### Pre-computed in the current demo

`demo_data.json` contains results for **12 MPAs** (LTEM monitoring sites). Data coverage varies by source:

| MPA | LTEM | SST | Chl-a | CONAPESCA region |
|-----|------|-----|-------|-----------------|
| Alto Golfo | ✓ | ✓ GoC | ✓ | R1 GoC Norte |
| El Vizcaíno | ✓ | ✓ GoC | ✓ | R2 Pac. Baja Norte |
| Cabo Pulmo | ✓ | ✓ GoC | ✓ | R3 GoC Sur y BCS |
| Bahía de Loreto | ✓ | ✓ GoC | ✓ | R3 GoC Sur y BCS |
| Espíritu Santo | ✓ | ✓ GoC | ✓ | R3 GoC Sur y BCS |
| Balandra | ✓ | ✓ GoC | ✓ | R3 GoC Sur y BCS |
| Cabo San Lucas | ✓ | ✓ GoC | ✓ | R3 GoC Sur y BCS |
| Islas Marías | ✓ | ✓ GoC | ✓ | R4 Pac. Nayarit-Guerrero |
| Ventilas Hidrotermales | ✓ | ✓ GoC | ✓ | R3 GoC Sur y BCS |
| Islas Marietas | ✓ | — (outside GoC bbox) | ✓ | R4 Pac. Nayarit-Guerrero |
| Huatulco | ✓ | — (outside GoC bbox) | ✓ | R7 Pac. Sur |
| Revillagigedo | ✓ | — (outside GoC bbox) | ✓ | R3 GoC Sur y BCS |

**SST spatial coverage:** OISST lon −115.875 to −105.875, lat 22.125 to 31.625 (Gulf of California). Three Pacific-facing MPAs fall outside this bbox and show no SST or MHW data.

The remaining ~40 MPA polygons on the map have no LTEM data — they show a muted style and a "No LTEM data" tooltip. In production the AI orchestrator would query the MCPs on demand.

### CONAPESCA CPUE data

- Source: CONAPESCA landings database 2001–2026 (12.7M records)
- Aggregated to: region × year × fleet (MENORES / MAYORES)
- All-species aggregate: total kg ÷ total effective fishing days
- 6 marine regions (Region 5 = inland freshwater, excluded)
- Region mapping: `skills/per-database/conapesca-lfo-regions/references/lfo_region_lookup.csv`

### SST / MHW data

- Source: NOAA OISST v2.1 daily (1982–2025)
- MHW detection: `heatwaveR::ts2clm()` + `detect_event(minDuration=5, maxGap=2)`
- Baseline period: 1998-01-01 to 2011-12-31
- Stored as annual summaries: `year`, `heatwave_days`, `mean_temp`

### Chlorophyll-a data

- Source: MODIS-Aqua (via NPP coastal zone dataset), monthly 2004–2023
- Variable: `mean_npp` (used as Chl-a proxy, mg/m³)
- Spatial coverage: lon −117.7 to −86.1, lat 14 to 33 (all coastal zone)
- Stored as annual means per MPA bounding box

### Data source update frequency

| Source | Update cadence | Who triggers | Notes |
|--------|---------------|-------------|-------|
| **LTEM** | Biannual (2× per year) | CBMC science team | Survey seasons May–June and Oct–Nov. Data arrives as RDS snapshots. |
| **CONAPESCA** | Annual | CBMC science team | Landings delivered as annual snapshots (~July, covering prior calendar year). |
| **SST (OISST)** | Every 15 days (or daily) | Automated ERDDAP pull | Near-real-time satellite data. |
| **Chlorophyll-a (MODIS)** | Every 15 days (or daily) | Automated ERDDAP pull | 15-day composites reduce cloud gaps in tropical waters. |

### Remaining future additions

| Metric | Source | Status |
|--------|--------|--------|
| Reef trophic health (NRSI) | LTEM | Skill exists (`ltem-nrsi-index`); not yet pre-computed in demo |
| Net Primary Production (NPP) | ERDDAP / MODIS | Data available; skill pending |
| Species-specific CPUE | CONAPESCA | Requires target-species list per region |
| Custom user polygon (AOI) | Any | UI feature; not yet implemented |

---

## 5. Data structures (for engineers)

### `demo_data.json` — top-level structure

```json
{
  "generated": "ISO datetime string",
  "mpas": { /* GeoJSON FeatureCollection of all MPA polygons */ },
  "grid": { /* GeoJSON FeatureCollection of prosperity grid cells */ },
  "offices": {
    "nombre_oficina_canonico": ["OFFICE A", ...],
    "lat": [28.4, ...],
    "lon": [-113.5, ...],
    "region_id": [3, ...],
    "region_name": ["Golfo de California Sur y BCS", ...]
  },
  "mpa_data": { /* see below */ },
  "cpue_regions": { /* see below */ }
}
```

### `mpa_data[name]` — per-MPA block

```json
{
  "ltem_region": "Cabo Pulmo",
  "conapesca_region_id": 3,

  "biomass": {
    "kpi": {
      "mean_biomass_g_m2": 0.09,        /* T/ha — field name is a legacy artifact */
      "sd_g_m2": 0.03,
      "years_included": [2020, 2021, 2022, 2023, 2025],
      "n_years_in_kpi": 5
    },
    "annual_means": {
      "year": [1999, 2000, ...],
      "mean_biomass_g_m2": [0.032, 0.061, ...]   /* T/ha */
    },
    "trend": {
      "year": [1999.0, 1999.5, ...],
      "fit": [0.028, ...],
      "lwr": [0.011, ...],
      "upr": [0.045, ...]
    },
    "dev_expl_pct": 74.2
  },

  "functional_groups": {
    "group_order": ["Depredadores solitarios", "Depredadores en cardúmenes",
                    "Omnívoros en cardúmen", "Herbívoros en cardúmen",
                    "Crípticos solitarios", "Planctívoros"],
    "group_colors": ["#D73027", "#FC8D59", "#FEE08B", "#91BFDB", "#4575B4", "#313695"],
    "series": {
      "Depredadores solitarios": {
        "year": [1999, 2000, ...],
        "biomass": [0.012, 0.018, ...]   /* T/ha */
      },
      /* ... one entry per group ... */
    }
  },

  "invertebrates": {
    "Echinoidea": {
      "kpi": { "mean_abundance_per_transect": 12.4, "n_years_in_kpi": 5 },
      "annual_means": { "year": [...], "mean_abundance_per_transect": [...] },
      "trend": { "year": [...], "fit": [...], "lwr": [...], "upr": [...] }
    },
    "Asteroidea": { /* same structure */ },
    "Holaxonia":  { /* same structure */ },
    "Scleractinia": { /* same structure */ }
  },

  "sst": {
    "kpi_mean_sst_c": 24.3,
    "kpi_mhw_days_per_yr": 12.4,
    "kpi_n_events_recent": 3,
    "kpi_years": "1982–2025",
    "annual": {
      "year": [1982, 1983, ...],
      "heatwave_days": [8, 5, ...],
      "mean_temp": [23.1, 23.4, ...]
    }
  },
  /* sst is null for MPAs outside GoC bbox */

  "chl": {
    "kpi_mean_chla_mg_m3": 0.412,
    "kpi_years": "2004–2023",
    "annual": {
      "year": [2004, 2005, ...],
      "mean_chla": [0.38, 0.44, ...]
    }
  }
  /* chl is null if no MODIS coverage */
}
```

### `cpue_regions[region_id]` — CONAPESCA CPUE by region

```json
{
  "region_name": "Golfo de California Norte",
  "menores": {
    "year": [2001, 2002, ...],
    "cpue": [1150.3, 1210.8, ...],
    "total_kg": [...],
    "total_dias": [...]
  },
  "mayores": { /* same structure */ },
  "kpi_menores_mean_cpue": 1284.32,
  "kpi_mayores_mean_cpue": 8713.04
}
```

### MPA panel — no-data state

If `demo_data.mpa_data[mpa_name]` is undefined:
- Show panel header (name + category)
- Show grey text: `"No precomputed data for this MPA. In production, the AI orchestrator runs the skills on demand."`
- Do not render any KPI cards or charts.

> **Note on biomass units:** `mean_biomass_g_m2` is a legacy field name. All values are in **T/ha**. Display as T/ha everywhere.

---

## 6. Design tokens

Use the chatMPA Design System tokens for colors and typography. Key values:

```css
--ocean-800: #0B2338   /* headings, deep navy */
--ocean-600: #143A5C   /* secondary text */
--marine-400: #1E9EC4  /* primary accent, teal */
--marine-500: #0E82A8  /* borders, active */
--ink-400:    #808E97  /* muted labels */
--ink-100:    #E4E9EC  /* dividers */
--sand-50:    #FDFAF4  /* panel background */
--green-500:  #21925F  /* positive / artisanal */
--green-100:  #DBEFE5  /* green tag background */
--amber-500:  #C6892A  /* industrial / warning */
--amber-100:  #F6E9CF  /* amber tag background */
```

Font: Inter (system fallback: `system-ui, -apple-system, sans-serif`).

---

## 7. Reference implementation

A working proof-of-concept is in `dashboard/demo/`:

- **`demo.html`** — Self-contained map + panel. Loads `demo_data.json` via `fetch()`. Requires a local server (CORS): `python3 -m http.server 8080` from the `demo/` folder, then open `http://localhost:8080/demo.html`.
- **`chatMPA-site-standalone.html`** — Full chatMPA site with the demo embedded. Same data and panel logic, same `DEMO_DATA` variable inlined (no server required for the site itself, but the demo section still uses `fetch()` internally).
- **`demo_data.json`** — Pre-computed data for 12 MPAs (LTEM + CONAPESCA + SST + Chl-a). ~1.1 MB.

The demo uses Leaflet.js for the map and Chart.js 4.x for all charts. It is NOT production code — it is a display reference for engineers.

### What the demo does NOT have yet

- Invertebrate time-series charts (4-taxon panels) — data in JSON, UI not rendered in current version
- NRSI (reef health index) panel
- Species-specific CPUE (only fleet aggregate shown)
- User-drawn polygon (custom AOI)
- Loading states (blank until data loads)

---

## 8. How the data flows in production

In production, data is not pre-computed. The flow is:

1. User clicks an MPA polygon
2. Dashboard calls the AI orchestrator with `{mpa_name, conapesca_region_id}`
3. Orchestrator runs **`ltem-fish-biomass`** skill → biomass KPI + trophic breakdown
4. Orchestrator runs **`ltem-invertebrate-abundance`** skill → 4-taxon KPIs + trends
5. Orchestrator queries CONAPESCA RDS for regional CPUE
6. Orchestrator runs **`erddap-sst-anomaly`** skill → SST + MHW annual series
7. Orchestrator runs **`erddap-chlorophyll`** skill → Chl-a annual series
8. Orchestrator returns JSON matching the structure in §5
9. Dashboard renders the panel

The demo short-circuits steps 2–8 by pre-computing everything in `demo_data.json`.

---

## 9. Skills reference

| Skill folder | What it computes | Panel section |
|-------------|-----------------|---------------|
| `ltem-fish-biomass` | Biomass T/ha: annual means + GAM trend + trophic group breakdown | §3.2 Card 1, §3.3 |
| `ltem-invertebrate-abundance` | Abundance per transect for 4 taxa | §3.2 Card 2 (Echinoidea KPI) |
| `conapesca-cpue` | CPUE kg/day per species per fleet | §3.4 (currently regional aggregate) |
| `conapesca-lfo-regions` | Assigns each MPA to a CONAPESCA region | Pipeline (feeds §3.4) |
| `erddap-sst-anomaly` | SST °C + MHW annual days (OISST, GoC) | §3.2 Card 5, §3.5.1 |
| `erddap-chlorophyll` | Chl-a mg/m³ annual mean (MODIS) | §3.2 Card 6, §3.5.2 |
| `ltem-nrsi-index` | Reef trophic health index (−1 to +1) | Future panel |

Each `SKILL.md` file contains: what question the skill answers, the data it consumes, the fixed method, and example output structure.
