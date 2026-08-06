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
│ Name of the MPA                         │  ← panel header (sticky)
│ Category · LTEM: <region name>          │
├──────────┬──────────┬──────────┬────────┤
│ BIOMASS  │ URCHINS  │ ART.     │ GORGO- │  ← KPI grid (4 cards)
│ x.xx T/ha│ xx ind   │ CPUE xxx │ NIANS  │
│          │ /transect│ kg/day   │ xx ind │
├─────────────────────────────────────────┤
│ Fish Biomass — GAM Trend (T/ha)         │  ← biomass time series
│ [line chart]                            │
├─────────────────────────────────────────┤
│ Fishing Pressure · [Region badge]       │  ← CPUE section
│ ARTISANAL  xxx kg/day                   │
│ INDUSTRIAL xxx kg/day                   │
│ CPUE Trend 2001–2026 [dual line chart]  │
├─────────────────────────────────────────┤
│ Invertebrate Abundance                  │  ← invertebrate section
│ Echinoidea  [chart]                     │
│ Asteroidea  [chart]                     │
│ Holaxonia   [chart]                     │
│ Scleractinia [chart]                    │
└─────────────────────────────────────────┘
```

### 3.1 Panel header

| Element | Value |
|---------|-------|
| Badge label | `"Marine Protected Area"` (green, always) |
| Title | MPA name (from shapefile `nombre_amp` field) |
| Subtitle | `{categoria}  ·  LTEM: {ltem_region}` (omit LTEM part if no data) |

### 3.2 KPI grid — 4 cards in a 2×2 grid

Each card has: **label** (10px uppercase), **value** (22px bold), **unit** (11px), **sub** (11px smaller note).

#### Card 1 — Fish Biomass
| Field | Content |
|-------|---------|
| Label | `FISH BIOMASS` |
| Value | `{mean_biomass}` rounded to 2 decimals |
| Unit | `T / ha` |
| Sub | `Mean · last 5 survey years` |
| Source skill | `ltem-fish-biomass` |
| If no data | Show `—` |

> **T/ha**: tonnes per hectare. 1 T/ha = 100 g/m². Cabo Pulmo (well-recovered MPA) is ~0.09 T/ha. Unprotected reefs typically < 0.01 T/ha.

#### Card 2 — Sea Urchins
| Field | Content |
|-------|---------|
| Label | `SEA URCHINS (ECHINOIDEA)` |
| Value | `{mean_abundance}` rounded to 1 decimal |
| Unit | `ind. / transect` |
| Sub | `Mean · last 5 survey years` |
| Source skill | `ltem-invertebrate-abundance` |

> Sea urchins (Echinoidea) are key reef grazers. High abundance can indicate overgrazing of algae or, in recovering reefs, predator-controlled balance.

#### Card 3 — Artisanal CPUE
| Field | Content |
|-------|---------|
| Label | `ARTISANAL CPUE` |
| Value | `{kpi_menores_mean_cpue}` rounded to integer |
| Unit | `kg / effective day` |
| Sub | `MENORES · 5-yr mean · {region_name}` |
| Source | `conapesca-lfo-regions` aggregation |

> CPUE = Catch Per Unit Effort. This is an all-species aggregate for the artisanal (small-boat, MENORES) fleet in the CONAPESCA fishing region where this MPA sits. Higher value = more productive fishing trips.

#### Card 4 — Gorgonians
| Field | Content |
|-------|---------|
| Label | `GORGONIANS (HOLAXONIA)` |
| Value | `{mean_abundance}` rounded to 1 decimal |
| Unit | `ind. / transect` |
| Sub | `Mean · last 5 survey years` |
| Source skill | `ltem-invertebrate-abundance` |

> Gorgonian corals (Holaxonia, sea fans) are structural reef builders. Their abundance signals reef habitat quality and is sensitive to temperature stress.

---

### 3.3 Fish Biomass — GAM Trend chart

**Chart type:** Line chart with scatter overlay  
**Library:** Chart.js  
**Height:** 150–160 px

| Element | Detail |
|---------|--------|
| X axis | Year (integer) |
| Y axis | Fish biomass in **T/ha** (label: `T/ha`) |
| Scatter points | Observed annual means — color `#0B2338`, white border |
| Trend line | GAM fitted values — `#1E9EC4` (marine teal), 2 px |
| CI band | GAM 95% CI — `rgba(30,158,196,0.15)` fill between upper/lower |
| Y minimum | 0 (biomass cannot be negative) |
| Warning | If < 5 survey years: amber text `⚠ Only N survey years — trend not fitted (min 5)` |
| Info | When trend fitted: show `GAM deviance explained: XX%` in grey |

**What the GAM means:** The GAM (Generalized Additive Model) fits a flexible smooth curve through the annual averages, accounting for the fact that different reefs within the same MPA have different baseline biomass levels. The trend line shows the population-level trajectory — is biomass going up, down, or stable?

---

### 3.4 Fishing Pressure — CONAPESCA section

Shows fishing effort around the MPA based on its CONAPESCA fishing region.

**KPI row (2 cards side by side):**

| Card | Label | Value | Unit | Sub |
|------|-------|-------|------|-----|
| Left | `ARTISANAL` (green tag) | `{kpi_menores_mean_cpue}` | `kg / effective day` | `MENORES · 5-yr mean` |
| Right | `INDUSTRIAL` (amber tag) | `{kpi_mayores_mean_cpue}` | `kg / effective day` | `MAYORES · 5-yr mean` |

**CPUE Trend chart (2001–2026):**

| Element | Detail |
|---------|--------|
| Height | 120 px |
| Line 1 | MENORES (artisanal) — `#21925F` solid, 1.8 px |
| Line 2 | MAYORES (industrial) — `#C6892A` dashed (4,3), 1.8 px |
| X axis | Year |
| Y axis | kg / effective day |
| Legend | Bottom, small (9px font) |

**Region badge:** Show the region name (e.g., `GoC Sur y BCS`) with a small teal dot in a pill-shaped badge above the KPI row.

**What this means for non-engineers:** MENORES = small-scale artisanal boats (the ones you see on beaches). MAYORES = industrial trawlers and vessels. A high industrial CPUE near an MPA means large-scale fishing pressure in the surrounding waters.

**Data note:** CPUE is not per-MPA but per CONAPESCA fishing region. All MPAs within the same region show the same CPUE time series. Current regions and which MPAs belong to them:

| Region | MPAs in demo |
|--------|-------------|
| GoC Norte (R1) | Alto Golfo |
| Pac. Baja Norte (R2) | El Vizcaíno |
| GoC Sur y BCS (R3) | Cabo Pulmo, Bahía de Loreto, Espíritu Santo, Balandra, Cabo San Lucas, Revillagigedo, Ventilas Hidrotermales |
| Pac. Nayarit-Guerrero (R4) | Islas Marietas, Islas Marías |
| Pac. Sur (R7) | Huatulco |

---

### 3.5 Invertebrate Abundance — 4 taxon charts

Four stacked charts, one per taxon (single-column layout). Each chart is 90–100 px tall.

**Taxa displayed (in this order):**

| Order | Taxon | What it is | Chart color |
|-------|-------|-----------|-------------|
| 1 | **Echinoidea** | Sea urchins — reef grazers, very common | `#1E9EC4` (teal) |
| 2 | **Asteroidea** | Sea stars — predators, indicator of food web health | `#21925F` (green) |
| 3 | **Holaxonia** | Gorgonian corals (sea fans) — structural habitat builders | `#7C5A93` (purple) |
| 4 | **Scleractinia** | Stony corals (hard corals) — reef builders | `#C6892A` (amber) |

**Per-taxon chart:**

| Element | Detail |
|---------|--------|
| Title | Taxon name (10px bold, above chart) |
| X axis | Year (ticks max 4) |
| Y axis | Individuals per transect (no label needed at this size) |
| Y minimum | 0 |
| Scatter points | Observed annual means — taxon color, 2.5 px radius |
| Trend line | GAM fitted — taxon color, 1.5 px |
| CI band | `{taxon_color}28` (28 = 16% opacity hex) |

**If a taxon has no data for this MPA:** skip rendering that chart entirely (do not show an empty frame).

---

## 4. Data availability

### What is pre-computed in the current demo

The demo (`dashboard/demo/demo_data.json`) contains pre-computed results for **12 MPAs** with LTEM monitoring data:

| MPA | LTEM Region | CONAPESCA Region |
|-----|------------|-----------------|
| Alto Golfo de California y Delta del Río Colorado | Alto Golfo | R1 GoC Norte |
| Islas Marietas | Bahía de Banderas | R4 Pac. Nayarit-Guerrero |
| Cabo Pulmo | Cabo Pulmo | R3 GoC Sur y BCS |
| Huatulco | Huatulco | R7 Pac. Sur |
| Islas Marías | Islas Marias | R4 Pac. Nayarit-Guerrero |
| Zona marina del Archipiélago de Espíritu Santo | La Paz | R3 GoC Sur y BCS |
| Balandra | La Ventana | R3 GoC Sur y BCS |
| Bahía de Loreto | Loreto | R3 GoC Sur y BCS |
| Cabo San Lucas | Los Cabos | R3 GoC Sur y BCS |
| Revillagigedo | Revillagigedo | R3 GoC Sur y BCS |
| Ventilas Hidrotermales (Cuenca de Guaymas) | San Basilio | R3 GoC Sur y BCS |
| El Vizcaíno | Santa Rosalía | R2 Pac. Baja Norte |

The remaining ~40 MPA polygons on the map exist but have no LTEM data — they show a muted style and a "No LTEM data" tooltip. In production, the AI orchestrator would query the MCPs on demand for any MPA.

### CONAPESCA CPUE data

- Source: CONAPESCA landings database 2001–2026 (12.7M records)
- Aggregated to: region × year × fleet (MENORES / MAYORES)
- All-species aggregate: total kg ÷ total effective fishing days
- 6 marine regions (Region 5 = inland freshwater, excluded)
- File: `skills/per-database/conapesca-lfo-regions/references/lfo_region_lookup.csv`

### Data source update frequency

| Source | Update cadence | Who triggers update | Notes |
|--------|---------------|--------------------:|-------|
| **LTEM** | Biannual (2× per year) | CBMC science team | Survey seasons are roughly May–June and Oct–Nov. New data arrives as RDS snapshots. |
| **CONAPESCA** | Annual | CBMC science team | Landings database delivered as annual snapshots (~July each year, covering the prior calendar year). |
| **SST (OISST)** | Every 15 days (or daily) | Automated ERDDAP pull | Near-real-time satellite data. Can be kept fresh with a scheduled download script. |
| **Chlorophyll-a (MODIS)** | Every 15 days (or daily) | Automated ERDDAP pull | Same pipeline as SST. 15-day composites reduce cloud gaps in tropical waters. |

The dashboard does not need a live connection to these sources. The orchestrator pre-computes and caches results; the frontend just renders what the orchestrator returns.

### Future additions (not yet available)

| Metric | Source | Status |
|--------|--------|--------|
| Sea Surface Temperature (SST) | ERDDAP / OISST | Pending local data copy |
| Chlorophyll-a | ERDDAP / MODIS | Pending local data copy |
| Net Primary Production (NPP) | ERDDAP / MODIS | Pending local data copy |
| Reef trophic health (NRSI) | LTEM | Skill exists, data not pre-computed |
| Species-specific CPUE | CONAPESCA | Requires target-species list per region |

When SST and Chl-a are available, add two more panel sections:
- **SST Anomaly** chart (°C above/below climatology) — placeholder: teal line at zero
- **Chlorophyll-a** chart (mg/m³ geometric mean) — placeholder: grey flat line

---

## 5. Data structures (for engineers)

### `demo_data.json` — top-level structure

```json
{
  "generated": "ISO datetime string",
  "mpas": { /* GeoJSON FeatureCollection of all MPA polygons */ },
  "grid": { /* GeoJSON FeatureCollection of prosperity grid cells */ },
  "offices": {
    "nombre_oficina_canonico": ["OFFICE A", "OFFICE B", ...],
    "lat": [28.4, 27.1, ...],
    "lon": [-113.5, -110.2, ...],
    "region_id": [3, 3, ...],
    "region_name": ["Golfo de California Sur y BCS", ...]
  },
  "mpa_data": {
    "Cabo Pulmo": {
      "ltem_region": "Cabo Pulmo",
      "conapesca_region_id": 3,
      "biomass": {
        "kpi": {
          "mean_biomass_g_m2": 0.09,       /* value in T/ha — field name legacy */
          "sd_g_m2": 0.03,
          "years_included": [2020, 2021, 2022, 2023, 2025],
          "n_years_in_kpi": 5
        },
        "annual_means": {
          "year": [1999, 2000, ...],
          "mean_biomass_g_m2": [0.032, 0.061, ...]  /* T/ha values */
        },
        "trend": {
          "year": [1999.0, 1999.5, ...],
          "fit": [0.028, ...],
          "lwr": [0.011, ...],
          "upr": [0.045, ...]
        },
        "dev_expl_pct": 74.2
      },
      "invertebrates": {
        "Echinoidea": {
          "kpi": { "mean_abundance_per_transect": 12.4, ... },
          "annual_means": { "year": [...], "mean_abundance_per_transect": [...] },
          "trend": { "year": [...], "fit": [...], "lwr": [...], "upr": [...] }
        },
        "Asteroidea": { ... },
        "Holaxonia": { ... },
        "Scleractinia": { ... }
      }
    }
  },
  "cpue_regions": {
    "1": {
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
    },
    "2": { ... },
    "3": { ... },
    "4": { ... },
    "6": { ... },
    "7": { ... }
  }
}
```

> **Note on biomass units:** The field is named `mean_biomass_g_m2` for historical reasons but the actual values are in **T/ha** (the LTEM database stores biomass in T/ha). Display as T/ha everywhere. 1 T/ha = 100 g/m².

### MPA panel — no-data state

If `demo_data.mpa_data[mpa_name]` is undefined:
- Show panel header (name + category)
- Show grey text: `"No precomputed data for this MPA. In production, the AI orchestrator runs the skills on demand."`
- Do not show any KPI cards or charts

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

- **`demo.html`** — Self-contained interactive map + panel. Loads `demo_data.json` via `fetch()`. Requires a local server (CORS): `python3 -m http.server 8080` from the `demo/` folder, then open `http://localhost:8080/demo.html`.
- **`demo_data.json`** — Pre-computed data for 12 MPAs (LTEM + CONAPESCA CPUE). 1.1 MB.

The demo uses Leaflet.js for the map and Chart.js for all charts. It is NOT production code — it is a display reference to show engineers the intended layout, chart types, and interaction model.

### What the demo does NOT have yet (future additions):
- SST and Chl-a panels (data not available locally yet)
- NRSI (reef health index) panel
- Species-specific CPUE
- User-drawn polygon (custom area of interest)
- Loading states (currently shows blank until data loads)

---

## 8. How the data flows in production

In the production system, data is not pre-computed. The flow is:

1. User clicks an MPA polygon in the dashboard
2. Dashboard calls the AI orchestrator with `{mpa_name, conapesca_region_id}`
3. Orchestrator queries the **LTEM MCP** for biomass and invertebrate data
4. Orchestrator runs **`ltem-fish-biomass`** skill → biomass KPI + trend
5. Orchestrator runs **`ltem-invertebrate-abundance`** skill → 4-taxon KPIs + trends
6. Orchestrator queries **CONAPESCA RDS** for regional CPUE (pre-aggregated by region)
7. Orchestrator returns JSON matching the structure in §5 above
8. Dashboard renders the panel

The demo short-circuits steps 2–7 by pre-computing everything and embedding it in `demo_data.json`.

---

## 9. Skills reference

Skills are the fixed analysis contracts that produce all KPI and chart values. Full specs are in `skills/per-database/`:

| Skill folder | What it computes | Panel section |
|-------------|-----------------|---------------|
| `ltem-fish-biomass` | Fish biomass T/ha: annual observed means + GAM trend ± CI | §3.2 Card 1, §3.3 |
| `ltem-invertebrate-abundance` | Abundance per transect for Echinoidea/Asteroidea/Holaxonia/Scleractinia | §3.2 Cards 2+4, §3.5 |
| `conapesca-cpue` | CPUE kg/day per species per fleet (species-level, for advanced queries) | §3.4 (currently regional aggregate) |
| `ltem-nrsi-index` | Reef trophic health index (−1 to +1) | Future: §3.x |
| `erddap-sst-anomaly` | Sea surface temperature anomaly °C | Future: §3.x |
| `erddap-chlorophyll` | Chlorophyll-a mg/m³ | Future: §3.x |

Each `SKILL.md` file contains: what question the skill answers, the data it consumes (minimal contract), the fixed method, and example output structure.
