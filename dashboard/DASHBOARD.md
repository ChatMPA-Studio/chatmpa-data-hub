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
│   [Fishing office dots]                          │  ← click anything │
│                                                  │                   │
│   [Layer toggles top-right]                      │  Panel A — MPA    │
│   [Legend bottom-left]                           │  Panel B — Office │
└──────────────────────────────────────────────────┴───────────────────┘
```

Two-column layout. Left: Leaflet map (full remaining height). Right: fixed 380 px scrollable panel.

**Two distinct panel types — triggered by what the user clicks:**

| Click target | Panel shown | Data sources |
|---|---|---|
| MPA polygon | **Panel A — Marine Protected Area** | LTEM + SST + Chl-a |
| Fishing office dot | **Panel B — Fisheries Office** | CONAPESCA + Economic KPIs |

Clicking the map background (no target) resets to the empty state.

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

### Fishing office styles (by CONAPESCA region)

| Region ID | Name | Color |
|-----------|------|-------|
| 1 | Golfo de California Norte | `#1E9EC4` |
| 2 | Pacífico Baja Norte | `#0B2338` |
| 3 | Golfo de California Sur y BCS | `#21925F` |
| 4 | Pacífico Nayarit-Guerrero | `#C6892A` |
| 6 | Pacífico Central | `#7C5A93` |
| 7 | Pacífico Sur (Oaxaca-Chiapas) | `#CC4C43` |

Circle markers: 6 px radius, color fill at 80% opacity, white border 1 px. Selected: 9 px radius, 100% opacity, white border 2 px.

Region 5 (inland freshwater offices) is excluded from the map.

---

## 3. Panel A — Marine Protected Area

Triggered when the user clicks an **MPA polygon**. Content is stacked top to bottom.

```
┌─────────────────────────────────────────┐
│ [badge] Marine Protected Area           │
│ Name of the MPA                         │  ← panel header
│ Category · LTEM: <region name>          │
├──────────┬──────────┬────────────────────┤
│ BIOMASS  │ INVERTS  │  REEF HEALTH       │  ← KPI row 1 (3 cards)
│ x.xx     │ xx.x     │  x.xx              │
│ T/ha     │ ind./tr. │  NRSI index        │
├──────────┬──────────┴────────────────────┤
│ SST      │ CHL-A                         │  ← KPI row 2 (2 cards)
│ xx.x °C  │ x.xxx mg/m³                  │
├─────────────────────────────────────────┤
│ Fish Biomass — Trophic Structure (T/ha) │  ← stacked area chart
│ [6 functional groups, stacked]          │
├─────────────────────────────────────────┤
│ Marine Environment                      │  ← environment section
│ Marine Heatwaves [bar + line combo]     │
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

### 3.2 KPI grid — 5 cards in a 3+2 layout

Each card has: **label** (10px uppercase), **value** (18px bold), **unit** (10px), **sub** (10px smaller note).

#### Card 1 — Fish Biomass
| Field | Content |
|-------|---------|
| Label | `FISH BIOMASS` |
| Value | `{mean_biomass_g_m2}` rounded to 2 decimals |
| Unit | `T / ha` |
| Sub | `Mean · 5-yr surveys · LTEM` |
| Source | `mpa_data[name].biomass.kpi.mean_biomass_g_m2` |
| If no data | Show `—` |

> **T/ha**: tonnes per hectare. Field `mean_biomass_g_m2` is a legacy name — all values are in T/ha. Cabo Pulmo (well-recovered MPA) ≈ 0.09 T/ha. Unprotected reefs typically < 0.01 T/ha.

#### Card 2 — Invertebrates
| Field | Content |
|-------|---------|
| Label | `INVERTEBRATES` |
| Value | Echinoidea `mean_abundance_per_transect`, 1 decimal |
| Unit | `ind. / transect` |
| Sub | `Echinoidea · LTEM` |
| Source | `mpa_data[name].invertebrates.Echinoidea.kpi.mean_abundance_per_transect` |
| If no data | Show `—` |

#### Card 3 — Reef Health (NRSI)
| Field | Content |
|-------|---------|
| Label | `REEF HEALTH` |
| Value | `{nrsi_mean}` rounded to 2 decimals |
| Unit | `NRSI · index` |
| Sub | `−1 (depleted) to +1 (pristine) · LTEM` |
| Color | Green if value > 0, red if < −0.15, grey otherwise |
| Source | `mpa_data[name].nrsi.kpi.nrsi_mean` |
| If no data | Show `—` with tag `coming soon` |

#### Card 4 — SST
| Field | Content |
|-------|---------|
| Label | `SST` |
| Value | `{kpi_mean_sst_c}` rounded to 1 decimal |
| Unit | `°C · OISST` |
| Sub | `{kpi_years} · {kpi_mhw_days_per_yr} MHW days/yr` |
| Source | `mpa_data[name].sst` |
| If outside GoC | Show `—` with tag `GoC only` |

> SST coverage: lon −115.875 to −105.875, lat 22.125 to 31.625 (OISST). Islas Marietas, Huatulco, Revillagigedo fall outside this bbox.

#### Card 5 — Chl-a
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
**Height:** 190 px

| Element | Detail |
|---------|--------|
| X axis | Year (integer) |
| Y axis | Fish biomass in **T/ha** (label: `T/ha`), stacked |
| Series | 6 trophic functional groups (see table below) |
| Fill | Each series filled with 80% opacity of group color |
| Border | Group color, 0.8 px |
| Tension | 0.3 (slight smoothing) |
| Points | Hidden (`pointRadius: 0`) |
| Legend | Bottom, 9px font, reversed order |
| Stack | `stack: 'biomass'` on both axes |

**Trophic functional groups (stacking order, bottom to top):**

| Group key | Spanish label | Color |
|-----------|--------------|-------|
| `GenPred_solitary` | Depredadores solitarios | `#D73027` |
| `GenPred_schooling` | Depredadores en cardúmenes | `#FC8D59` |
| `EpiBent_schooling` | Omnívoros en cardúmen | `#FEE08B` |
| `Crip_schooling` | Herbívoros en cardúmen | `#91BFDB` |
| `Crip_solitary` | Crípticos solitarios | `#4575B4` |
| `Plank` | Planctívoros | `#313695` |

**Fallback (when `functional_groups` is absent but `biomass` exists):**

Show the GAM trend chart (scatter + smooth line + 95% CI band):

| Element | Detail |
|---------|--------|
| Height | 150 px |
| Scatter | Observed annual means — `#0B2338`, white border, 4 px |
| Trend line | GAM fit — `#1E9EC4`, 2 px |
| CI band | `rgba(30,158,196,0.15)` between `lwr` and `upr` |
| Sub-label | `GAM dev.expl.: {dev_expl_pct}%` in grey (10px) |

---

### 3.4 Marine Environment section

Two charts stacked vertically. Render only when data is available.

#### 3.4.1 Marine Heatwaves (MHW) chart

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
| Note below | `Baseline: 1998–2011 · min 5 consecutive days (Hobday et al. 2016)` |

#### 3.4.2 Chlorophyll-a time series

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
| Note below | `Monthly composites averaged annually · mg m⁻³` |

### 3.5 MPA panel — no-data state

If `demo_data.mpa_data[mpa_name]` is undefined:
- Show panel header (name + category)
- Show grey text: `"No precomputed data for this MPA. In production, the AI orchestrator runs the skills on demand."`
- Do not render any KPI cards or charts.

---

## 4. Panel B — Fisheries Office

Triggered when the user clicks a **fishing office dot**. Content is stacked top to bottom.

```
┌─────────────────────────────────────────────┐
│ [badge] Fisheries Office                    │
│ LA PAZ                                      │  ← panel header
│ ● Golfo de California Sur y BCS             │
├────────────┬────────────┬────────────────────┤
│ RANK VOL.  │ RANK VALOR │ TMCA · DESEMB.    │  ← KPI row (3 cards, static)
│ #26        │ #28        │ −5.5%             │
│ de 165     │ de 165     │ declining         │
├─────────────────────────────────────────────┤
│ Recurso    [ Todas ▾ ]  ←─ mutuamente       │
│ Especie    [ Todas ▾ ]  ←─ excluyentes      │  ← filter bar
│ Flota      [Mayores] [Menores] [Cosecha]    │
│ Año        [ 2001 ▾ ] – [ 2026 ▾ ]  libre  │
│ Grupo comercial [ coming soon ]             │
├─────────────────────────────────────────────┤
│ ── ACTIVIDAD PESQUERA ──                    │
│                                             │
│ ┌──────────────────┐ ┌──────────────────┐  │
│ │ CPUE             │ │ CPUE             │  │  ← CPUE KPI cards
│ │ [Artisanal]      │ │ [Industrial]     │  │    label = "CPUE", fleet badge
│ │ 245              │ │ 1,832            │  │
│ │ kg / día efectivo│ │ kg / día efectivo│  │
│ │ MENORES · 01–26  │ │ MAYORES · 01–26  │  │    sub = rango real seleccionado
│ └──────────────────┘ └──────────────────┘  │
│ CPUE · kg / día efectivo                   │
│ [dual line — MENORES / MAYORES]             │  ← CPUE timeseries
│                                             │
│ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐       │
│ │Volumen│ │Volumen│ │Volumen│ │Volumen│    │  ← Volumen KPI cards (4)
│ │[Total]│ │[Ind.] │ │[Art.] │ │[Acua.]│   │    1 por flota, antes del chart
│ │12,345 │ │ 8,210 │ │ 3,891 │ │   244 │   │
│ │ton/año│ │ton/año│ │ton/año│ │ton/año│   │
│ └──────┘ └──────┘ └──────┘ └──────┘       │
│ Volumen Desembarcado · toneladas            │
│ [multi-line — TOTAL / MAYORES / MENORES /  │  ← landings volume timeseries
│  COSECHA]                                   │
│                                             │
│ Composición · Captura vs Acuacultura        │
│ Captura     ████████████████  98.3%        │  ← catch composition
│ Acuacultura ██  1.7%                        │
├─────────────────────────────────────────────┤
│ ── INDICADORES ECONÓMICOS ──                │
│                                             │
│ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐       │
│ │Valor  │ │Valor  │ │Valor  │ │Valor  │    │  ← Valor KPI cards (4)
│ │[Total]│ │[Ind.] │ │[Art.] │ │[Acua.]│   │    1 por flota, antes del chart
│ │ 487.3 │ │ 312.1 │ │ 158.4 │ │  16.8 │   │
│ │MXN M  │ │MXN M  │ │MXN M  │ │MXN M  │   │
│ └──────┘ └──────┘ └──────┘ └──────┘       │
│ Valor de la Producción · MXN                │
│ [multi-line — TOTAL / MAYORES / MENORES /  │  ← value timeseries
│  COSECHA]                                   │
│                                             │
│ Ingreso por pescador       [coming soon]   │
│ Empleo artesanal           [coming soon]   │
│ Índice de depend. mun.     [coming soon]   │
├─────────────────────────────────────────────┤
│ ── ESTATUS DE ESPECIE ──                    │
│ (solo visible cuando filtro Especie activo) │
│ NOM-059 · IUCN · FishBase · vedas          │
│ [coming soon]                               │
└─────────────────────────────────────────────┘
```

### 4.1 Panel header

| Element | Value |
|---------|-------|
| Badge label | `"Fisheries Office"` (amber, always) |
| Title | Office name (`nombre_oficina_canonico`) |
| Region badge | Pill with colored dot + region name (colors from §2 table) |

---

### 4.2 KPI row — 3 cards (static)

The three top cards **do not react to filters**. They always show the all-species, full-series figures for the office and serve as context before any filtering.

| Card | Label | Value | Sub | Skill |
|------|-------|-------|-----|-------|
| Left | `RANK VOLUMEN` | `#{rank_volumen}` | `de {n_offices} · {pct_volumen}% nación` | `conapesca-national-ranking` |
| Center | `RANK VALOR` | `#{rank_valor}` | `de {n_offices} · {pct_valor}% nación` | `conapesca-national-ranking` |
| Right | `TMCA · DESEMBARQUES` | `{tmca}%` (sign-prefixed) | category badge | `conapesca-tmca` |

**TMCA category colors:**

| Category | Color |
|----------|-------|
| `growing` | `#21925F` |
| `growing moderately` | `#4FBBD8` |
| `stable` | `#808E97` |
| `declining moderately` | `#C6892A` |
| `declining` | `#CC4C43` |

> **Semantic note:** TMCA measures the trend of **landed volume** (fishing activity), NOT stock abundance. A "declining" TMCA may reflect closures, fleet relocation, or resource decline — the chatbot should always clarify this.

Source: `office_data["{OFFICE}|{STATE}"].all.ranking` and `.all.tmca`.

---

### 4.3 Filter bar

Filters are input parameters passed to all skills simultaneously. Changing any filter re-runs the affected skills and updates all charts below the KPI row.

| Filter | Field in skill | Options | Notes |
|--------|---------------|---------|-------|
| **Recurso** | `nombre_principal` | Todas · resource group name (e.g. JUREL) | Mutually exclusive with Especie |
| **Especie** | `nombre_cientifico_canonico` | Todas · canonical species name (e.g. *Lutjanus peru*) | Mutually exclusive with Recurso. Activates Estatus de Especie section |
| **Flota** | `tipo_aviso` (display only) | Pills: Mayores / Menores / Cosecha | Skills always return all three series; frontend shows/hides lines |
| **Año** | `year_range` | Two free `<select>` elements: from 2001 to 2026 (any interval). Cross-validated: from ≤ to always. | Applied to all charts and KPI cards |
| **Grupo comercial** | — | *coming soon* | Requires `nombre_principal → grupo_comercial` mapping table in the DB |

**Mutual exclusion rule:** Selecting Recurso resets Especie to "Todas" and vice versa. This matches the skill contract — `nombre_principal` and `nombre_cientifico_canonico` cannot both be non-NULL in the same call.

---

### 4.4 Actividad Pesquera section

#### 4.4.1 CPUE KPI cards — 2 cards side by side

Card structure follows the same pattern as Panel A KPI cards: **label** (metric name, 10px uppercase) at top, then a colored **fleet badge**, then the value.

| Card | Label | Fleet badge | Value | Unit | Sub | Badge color |
|------|-------|-------------|-------|------|-----|-------------|
| Left | `CPUE` | `Artisanal` | mean `cpue_menores` over selected year range | `kg / día efectivo · prom` | `MENORES · {yearStart}–{yearEnd}` | `#21925F` |
| Right | `CPUE` | `Industrial` | mean `cpue_mayores` over selected year range | `kg / día efectivo · prom` | `MAYORES · {yearStart}–{yearEnd}` | `#C6892A` |

The mean is computed dynamically from the filtered year range (not a pre-computed 5-yr scalar). Sub-line always reflects the user's current Año selection.

In demo: values computed client-side from `office_data[key].{mode}.cpue.cpue_menores[]` / `.cpue_mayores[]` filtered by `yearStart`–`yearEnd`.  
In production: `conapesca-cpue` returns the full `cpue_series`; frontend computes the mean for the selected range.  
**Skill:** `conapesca-cpue`

#### 4.4.2 CPUE timeseries chart

**Chart type:** Dual line · **Height:** 130 px

| Element | Detail |
|---------|--------|
| Line 1 | MENORES — `#21925F` solid, 2 px, circle points |
| Line 2 | MAYORES — `#C6892A` dashed (4,3), 2 px, triangle points |
| Hollow points | When `n_viajes < 5` (low reliability) |
| X axis | Year (integer, filtered by Año selection) |
| Y axis | `kg/día` |
| Y min | 0 |
| Legend | Bottom, 9px |
| Note below | `Oficina {name} · CONAPESCA · {yearStart}–{yearEnd}` |

COSECHA always excluded (no effort concept in aquaculture).  
**Skill:** `conapesca-cpue` → `cpue_series`: `anio_corte, tipo_aviso, cpue_media, cpue_sd, n_viajes, n_viajes_excluidos`

#### 4.4.3 Volumen KPI cards — 4 cards (one per fleet)

Placed immediately **before** the Volumen Desembarcado timeseries. Shows mean annual landed volume over the selected year range, broken down by fleet. Displayed in a 2×2 grid using the same `demo-cpue-kpi-2` container (wraps to 2 rows).

| Card | Label | Fleet badge | Value | Unit | Sub | Badge color |
|------|-------|-------------|-------|------|-----|-------------|
| 1 | `Volumen` | `Total` | mean total annual tonnes | `ton / año · prom` | `{yearStart}–{yearEnd}` | `#0B2338` (navy) |
| 2 | `Volumen` | `Industrial` | mean MAYORES annual tonnes | `ton / año · prom` | `{yearStart}–{yearEnd}` | `#C6892A` (amber) |
| 3 | `Volumen` | `Artisanal` | mean MENORES annual tonnes | `ton / año · prom` | `{yearStart}–{yearEnd}` | `#21925F` (teal) |
| 4 | `Volumen` | `Acuacultura` | mean COSECHA annual tonnes | `ton / año · prom` | `{yearStart}–{yearEnd}` | `#1E9EC4` (blue) |

Each card has a top border in the fleet color. Fleet badge is an inline pill (white text on fleet color). Values computed dynamically from selected year range. Cards react to Año filter but are not affected by Flota pills (always show all 4).

In demo: computed client-side from `office_data[key].{mode}.landings.{FLEET}.total_kg[]`.  
**Skill:** `conapesca-landings-timeseries`

#### 4.4.4 Volumen Desembarcado chart

**Chart type:** Multi-line · **Height:** 130 px · **Y unit:** toneladas (divide `total_kg` by 1,000)

| Line | Color | Dash |
|------|-------|------|
| TOTAL | `#0B2338` | solid, 2 px |
| MAYORES | `#C6892A` | dashed (4,3) |
| MENORES | `#21925F` | solid |
| COSECHA | `#1E9EC4` | dotted (2,2) |

Fleet pills control which lines are visible. TOTAL always shown.  
**Skill:** `conapesca-landings-timeseries` → `anio_corte, tipo_aviso, total_kg`

#### 4.4.5 Composición — Captura vs Acuacultura

Horizontal proportion bars (CSS or SVG). Accumulated over the selected year range.

| Bar | Color | Value |
|-----|-------|-------|
| Captura (MAYORES + MENORES) | `#1E9EC4` | `{captura_pct_vol}%` |
| Acuacultura (COSECHA) | `#C6892A` | `{cosecha_pct_vol}%` |

Do not repeat total volume or value here — those are already in the timeseries charts.  
**Skill:** `conapesca-catch-composition` → `captura_pct_vol, cosecha_pct_vol, captura_pct_val, cosecha_pct_val`

---

### 4.5 Indicadores Económicos section

#### 4.5.1 Valor KPI cards — 4 cards (one per fleet)

Placed immediately **before** the Valor de la Producción timeseries. Same structure as the Volumen KPI cards (§4.4.3) but for economic value.

| Card | Label | Fleet badge | Value | Unit | Sub | Badge color |
|------|-------|-------------|-------|------|-----|-------------|
| 1 | `Valor` | `Total` | mean total annual MXN M | `MXN M / año · prom` | `{yearStart}–{yearEnd}` | `#0B2338` (navy) |
| 2 | `Valor` | `Industrial` | mean MAYORES annual MXN M | `MXN M / año · prom` | `{yearStart}–{yearEnd}` | `#C6892A` (amber) |
| 3 | `Valor` | `Artisanal` | mean MENORES annual MXN M | `MXN M / año · prom` | `{yearStart}–{yearEnd}` | `#21925F` (teal) |
| 4 | `Valor` | `Acuacultura` | mean COSECHA annual MXN M | `MXN M / año · prom` | `{yearStart}–{yearEnd}` | `#1E9EC4` (blue) |

In demo: computed client-side from `office_data[key].{mode}.landings.{FLEET}.total_valor_mxn[]`.  
**Skill:** `conapesca-landings-timeseries`

#### 4.5.2 Valor de la Producción chart

**Same skill call as Volumen Desembarcado** (`conapesca-landings-timeseries`) — the skill returns both `total_kg` and `total_valor_mxn` in one response. The frontend renders `total_kg` in Actividad Pesquera and `total_valor_mxn` here.

**Chart type:** Multi-line · **Height:** 130 px · **Y unit:** MXN  
Same line colors and fleet structure as §4.4.4.  
**Skill:** `conapesca-landings-timeseries` → `anio_corte, tipo_aviso, total_valor_mxn`

#### 4.5.3 Coming soon indicators

| KPI | Future data source |
|-----|--------------------|
| Ingreso por pescador | Padrón de permisos CONAPESCA + `total_valor_mxn / n_pescadores` |
| Empleo artesanal | Anuario Estadístico de Pesca (SAGARPA/SADER) — available at state level only |
| Índice de dependencia municipal | Municipal GDP/PEA from INEGI crossed with local production |

Show placeholder text: `coming soon` for each item.

---

### 4.6 Estatus de Especie section

**Visible only when** the Especie filter is active (`nombre_cientifico_canonico` non-NULL). Hidden when Recurso or "Todas" is selected.

**Skill:** `conapesca-species-status` *(pending implementation)*

| Data | Source | Strategy |
|------|--------|----------|
| NOM-059 status | Pre-computed reference table | Manual update (changes rarely) |
| IUCN category | Pre-computed, periodic refresh | Annual re-evaluation |
| FishBase traits (TL, Lmax, habitat) | `get_taxonomy()` via conapesca MCP | Already indexed |
| Vedas y temporadas | Pre-computed reference table | Manual update |
| Planes de manejo vigentes | `amp-planes-manejo-mcp` (real time) | Fast, updates with revisions |

Show placeholder: `coming soon · solo con filtro especie` until skill is implemented.

---

### 4.7 Panel B — no-data state

If `demo_data.office_data["{OFFICE}|{STATE}"]` is undefined:
- Show panel header (office name + region badge)
- Show grey text: `"No precomputed data for this office. In production, the AI orchestrator computes on demand."`
- Do not render KPI cards, filter bar, or charts.

---

## 5. Data availability

### Pre-computed in `demo_data.json` (12 MPAs)

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
| Islas Marietas | ✓ | — (outside GoC) | ✓ | R4 Pac. Nayarit-Guerrero |
| Huatulco | ✓ | — (outside GoC) | ✓ | R7 Pac. Sur |
| Revillagigedo | ✓ | — (outside GoC) | ✓ | R3 GoC Sur y BCS |

### CONAPESCA fishing offices (72 offices)

All 72 offices have: name, coordinates, region_id, region_name. Available in `demo_data.json → offices`.  
Regional CPUE time series (2001–2026) available in `demo_data.json → cpue_regions` (6 marine regions).  
Species/group-level CPUE: coming once Carolina's skills are complete.

### SST / MHW data

- Source: NOAA OISST v2.1 daily (1982–2025)
- MHW detection: `heatwaveR::ts2clm()` + `detect_event(minDuration=5, maxGap=2)`
- Baseline period: 1998-01-01 to 2011-12-31
- Coverage: GoC only (lon −115.875 to −105.875, lat 22.125 to 31.625)

### Chlorophyll-a data

- Source: MODIS-Aqua monthly (2004–2023)
- Variable: `mean_npp` (used as Chl-a proxy, mg/m³)
- Coverage: all coastal zone (lon −117.7 to −86.1, lat 14–33)

### Data update cadence

| Source | Cadence | Who triggers |
|--------|---------|-------------|
| LTEM | Biannual (May–Jun, Oct–Nov) | CBMC science team |
| CONAPESCA | Annual (~July) | CBMC science team |
| SST (OISST) | Every 15 days or daily | Automated ERDDAP pull |
| Chl-a (MODIS) | Every 15 days | Automated ERDDAP pull |

---

## 6. Data structures (for engineers)

### `demo_data.json` — top-level

```json
{
  "generated": "ISO datetime string",
  "mpas":        { /* GeoJSON FeatureCollection of all MPA polygons */ },
  "grid":        { /* GeoJSON FeatureCollection of prosperity grid cells */ },
  "offices": {
    "nombre_oficina_canonico": ["OFFICE A", ...],
    "lat": [28.4, ...],
    "lon": [-113.5, ...],
    "region_id": [3, ...],
    "region_name": ["Golfo de California Sur y BCS", ...]
  },
  "mpa_data":    { /* keyed by MPA name — Panel A source */ },
  "cpue_regions":{ /* keyed by region_id — Panel B source */ }
}
```

### `mpa_data[name]` — Panel A source

```json
{
  "ltem_region": "Cabo Pulmo",
  "conapesca_region_id": 3,
  "biomass": {
    "kpi": { "mean_biomass_g_m2": 0.09, "sd_g_m2": 0.03, "years_included": [...], "n_years_in_kpi": 5 },
    "annual_means": { "year": [...], "mean_biomass_g_m2": [...] },
    "trend": { "year": [...], "fit": [...], "lwr": [...], "upr": [...] },
    "dev_expl_pct": 74.2
  },
  "functional_groups": {
    "group_order": ["Depredadores solitarios", ...],
    "group_colors": ["#D73027", ...],
    "series": {
      "Depredadores solitarios": { "year": [...], "biomass": [...] },
      /* one entry per group */
    }
  },
  "invertebrates": {
    "Echinoidea":   { "kpi": {...}, "annual_means": {...}, "trend": {...} },
    "Asteroidea":   { /* same */ },
    "Holaxonia":    { /* same */ },
    "Scleractinia": { /* same */ }
  },
  "sst": {
    "kpi_mean_sst_c": 24.3,
    "kpi_mhw_days_per_yr": 12.4,
    "kpi_years": "1982–2025",
    "annual": { "year": [...], "heatwave_days": [...], "mean_temp": [...] }
  },
  "chl": {
    "kpi_mean_chla_mg_m3": 0.412,
    "kpi_years": "2004–2023",
    "annual": { "year": [...], "mean_chla": [...] }
  }
  /* nrsi: coming soon — not yet in demo_data.json */
}
```

### `cpue_regions[region_id]` — Panel B (legacy regional aggregate)

```json
{
  "region_name": "Golfo de California Norte",
  "menores": {
    "year": [2001, 2002, ...],
    "cpue": [1150.3, 1210.8, ...]
  },
  "mayores": { /* same structure */ },
  "kpi_menores_mean_cpue": 1284.32,
  "kpi_mayores_mean_cpue": 8713.04
}
```

### `office_data["{OFFICE}|{STATE}"]` — Panel B (per-office, skill-computed)

Key format: `"{nombre_oficina_canonico}|{nombre_estado}"`, e.g. `"CABO SAN LUCAS|BAJA CALIFORNIA SUR"`.  
Each office has two sub-objects: `all` (no species/resource filter) and `recurso` (filtered to `nombre_principal`).

```json
{
  "nombre_oficina": "CABO SAN LUCAS",
  "nombre_estado":  "BAJA CALIFORNIA SUR",
  "region_id":      3,
  "region_name":    "Golfo de California Sur y BCS",
  "recurso_demo":   "JUREL",
  "especie_demo":   "Lutjanus peru",
  "all": {
    "ranking": {
      "rank_volumen": 131, "rank_valor": 125, "n_offices": 165,
      "pct_volumen": 0.02, "pct_valor": 0.05,
      "total_toneladas": 7476, "total_valor_mxn": 368950664
    },
    "tmca": {
      "tmca": -24.59, "category": "declining",
      "yr_start": 2016, "yr_end": 2026
    },
    "cpue": {
      "kpi_menores": 245.3, "kpi_mayores": 1832.1,
      "years":        [2001, 2002, ...],
      "cpue_menores": [210.4, 198.7, ...],
      "cpue_mayores": [1540.2, 1620.8, ...],
      "n_menores":    [12, 15, ...],
      "n_mayores":    [8, 11, ...]
    },
    "landings": {
      "years": [2000, 2001, ...],
      "TOTAL":   { "total_kg": [76371, ...], "total_valor_mxn": [7045991, ...] },
      "MAYORES": { "total_kg": [...], "total_valor_mxn": [...] },
      "MENORES": { "total_kg": [...], "total_valor_mxn": [...] },
      "COSECHA": { "total_kg": [...], "total_valor_mxn": [...] }
    },
    "composition": {
      "captura_pct_vol": 100, "cosecha_pct_vol": 0,
      "captura_pct_val": 100, "cosecha_pct_val": 0
    }
  },
  "recurso": { /* same structure, filtered to nombre_principal */ }
}
```

**Demo offices with precomputed data:**

| Key | Recurso demo | Especie demo |
|-----|-------------|-------------|
| `CABO SAN LUCAS\|BAJA CALIFORNIA SUR` | JUREL | *Lutjanus peru* |
| `LA PAZ\|BAJA CALIFORNIA SUR` | CAMARON | *Litopenaeus vannamei* |
| `MAZATLAN\|SINALOA` | CAMARON | *Litopenaeus vannamei* |
| `GUAYMAS\|SONORA` | CAMARON | *Penaeus stylirostris* |
| `ENSENADA\|BAJA CALIFORNIA` | ABULON | *Haliotis fulgens* |

All other offices show the no-data state (§4.7). In production the orchestrator computes on demand for any office.

---

## 7. Design tokens

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

## 8. Reference implementation

A working proof-of-concept is in `dashboard/demo/`:

- **`demo.html`** — Self-contained map + panel. Loads `demo_data.json` via `fetch()`. Run with `python3 -m http.server 8080` from the `demo/` folder.
- **`chatMPA-site-standalone.html`** — Full site with demo embedded.
- **`demo_data.json`** — Pre-computed data for 12 MPAs (~1.1 MB).

The demo uses Leaflet.js + Chart.js 4.x. It is a display reference only — not production code.

**What the demo has:**
- Panel A fully implemented (biomass, MHW, Chl-a)
- Panel B implemented for 5 demo offices (CABO SAN LUCAS, LA PAZ, MAZATLAN, GUAYMAS, ENSENADA) with real CONAPESCA data

**What the demo does not yet have:**
- Species-level data for Panel B (demo shows resource-group level only; especie filter label is shown but uses recurso data)
- Economic KPIs (Carolina's skills pending)
- NRSI panel (Panel A)
- Invertebrate time-series charts, 4-taxon (Panel A)
- Estatus de Especie section (Panel B)

---

## 9. How data flows in production

**Flow A — User clicks an MPA:**
1. Dashboard calls orchestrator with `{mpa_name, ltem_region}`
2. Orchestrator runs `ltem-fish-biomass` → biomass + trophic groups
3. Orchestrator runs `ltem-invertebrate-abundance` → 4-taxon KPIs + trends
4. Orchestrator runs `ltem-nrsi-index` → reef health index
5. Orchestrator runs `erddap-sst-anomaly` → SST + MHW series
6. Orchestrator runs `erddap-chlorophyll` → Chl-a series
7. Orchestrator returns JSON → dashboard renders Panel A

**Flow B — User clicks a Fishing Office:**
1. Dashboard calls orchestrator with `{office_filter, state_filter, nombre_principal?, nombre_cientifico_canonico?, year_range?, tipo_aviso?}`
2. Orchestrator runs `conapesca-national-ranking` → Rank Volumen, Rank Valor, % nacional (static, all-species)
3. Orchestrator runs `conapesca-tmca` → TMCA %, category (static, all-species)
4. Orchestrator runs `conapesca-cpue` → CPUE KPI cards + timeseries (MENORES / MAYORES)
5. Orchestrator runs `conapesca-landings-timeseries` → Volumen (kg) + Valor (MXN) timeseries per fleet
6. Orchestrator runs `conapesca-catch-composition` → % captura vs acuacultura
7. If `nombre_cientifico_canonico` non-NULL: orchestrator runs `conapesca-species-status` → Estatus de Especie
8. Orchestrator returns JSON → dashboard renders Panel B

Skills 2–3 are always called without filters (all-species). Skills 4–7 are called with the active filter combination.

`demo_data.json` short-circuits both flows with pre-computed results.

---

## 10. Skills reference

| Skill | Panel | What it computes |
|-------|-------|-----------------|
| `ltem-fish-biomass` | A | Biomass T/ha: annual means + GAM trend + trophic group breakdown |
| `ltem-invertebrate-abundance` | A | Abundance per transect for 4 taxa (Echinoidea, Asteroidea, Holaxonia, Scleractinia) |
| `ltem-nrsi-index` | A | Reef trophic health index (−1 to +1) |
| `erddap-sst-anomaly` | A | SST °C + MHW annual days (OISST, GoC only) |
| `erddap-chlorophyll` | A | Chl-a mg/m³ annual mean (MODIS) |
| `conapesca-national-ranking` | B | National rank by volume and value; % of national total — feeds KPI row (static) |
| `conapesca-tmca` | B | Mean annual growth rate of landed volume + trend category — feeds KPI row (static) |
| `conapesca-cpue` | B | CPUE kg/eff.day per fleet (MENORES/MAYORES) — feeds CPUE KPI cards + timeseries |
| `conapesca-landings-timeseries` | B | Annual kg + MXN per fleet — feeds both Volumen and Valor charts |
| `conapesca-catch-composition` | B | % capture vs aquaculture in volume and value — feeds composition bars |
| `conapesca-species-status` *(pending)* | B | Species regulatory and ecological profile — feeds Estatus de Especie (especie filter only) |
