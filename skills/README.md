# skills/

Skills de análisis (en **R**) del ecosistema ChatMPA, para analizar AMPs del
Golfo de California encadenando acceso a datos (MCP/RDS) con métodos fijos.

**Procedencia:** copiadas de
[`ChatMPA-Studio/chatmpa-mvp`](https://github.com/ChatMPA-Studio/chatmpa-mvp)
@ commit `dc9e0af`. El subárbol se trajo **auto-contenido** (skills + `shared/` +
docs de gobernanza), así que corre desde esta carpeta igual que en el repo origen.

> Una skill es un **contrato**, no un tutorial: fija el contrato de datos, el
> método con sus parámetros, la semilla, un **valor de referencia verificado por
> humano** con tolerancia, y las reglas "no hagas". Detalle en `CONVENTIONS.md`.

## Catálogo

### per-database (una métrica por fuente)

| Skill | Fuente | Qué responde (trigger) |
|-------|--------|------------------------|
| `ltem-nrsi-index` ⭐ | LTEM | Salud trófica de un arrecife (NRSI): ¿sano, degradado o en recuperación? |
| `conapesca-cpue` | CONAPESCA | Presión pesquera sobre una especie: CPUE como serie de tiempo, regional y local. |
| `erddap-sst-anomaly` | ERDDAP (OISST) | Anomalías de SST y calentamiento en una AMP y su LME. |
| `erddap-chlorophyll` | ERDDAP (MODIS/VIIRS) | Productividad primaria: media geométrica y anomalías de Chl-a. |

⭐ `ltem-nrsi-index` es el "gold standard" (el ejemplo completo a copiar).

### interdatabase (combinan fuentes)

| Skill | Combina | Qué responde |
|-------|---------|--------------|
| `reef-drivers-lm` | LTEM + CONAPESCA + SST + Chl-a | Qué factores (pesca, temperatura, productividad) se asocian con la salud del arrecife (modelo lineal de NRSI). |

Además, cada categoría trae un `_TEMPLATE/` para crear skills nuevas.

## Estructura

```
skills/
├── per-database/      # una skill por métrica/fuente (+ _TEMPLATE)
├── interdatabase/     # skills que combinan fuentes (+ _TEMPLATE)
├── shared/            # helpers transversales + arnés de validación
│   ├── validation/    # las 3 verificaciones (self-consistency, referencia, coherencia)
│   ├── spatial_join/  temporal_align/  coverage/
│   └── geometries/    # setup_amp_geometries.R + conanp_overrides.gpkg
├── data/              # copia de staging — GIT-IGNORED, nunca se versiona
├── CONVENTIONS.md     # naming, versionado, reglas de referencia
└── ORCHESTRATION.md   # pipeline pregunta→salida (intake→…→render)
```

## Cómo validar una skill (las 3 verificaciones)

Desde esta carpeta (`skills/`):

```bash
Rscript -e 'source("shared/validation/run_checks.R"); run_all_checks("per-database/ltem-nrsi-index")'
```

Verifica: **self-consistency** (N corridas coinciden), **referencia** (coincide
con un valor verificado por humano; `PENDING` → `SKIP`, nunca pase silencioso) y
**coherencia** (los métodos declarados coinciden con `SKILL.md`).

## ⚠️ Datos sensibles — CONAPESCA

La base CONAPESCA contiene **nombres de unidades económicas, RNP y registros de
captura individuales**. Esos datos **nunca** deben entrar al control de versiones
ni a salidas públicas. `skills/data/` está git-ignored por diseño; trata como
sensible cualquier salida que pueda re-identificar una unidad económica.

## Sinergias con el resto de `chatMPA-data-hub` (para integrar después)

Estas skills se solapan con lo que ya construimos; posibles integraciones:

- `erddap-sst-anomaly` / `erddap-chlorophyll` ↔ `scripts/download_erddap.py`
  (misma familia de datos ERDDAP; podrían compartir la descarga/caché).
- `shared/geometries/setup_amp_geometries.R` + `conanp_overrides.gpkg` ↔
  `scripts/build_amps_gpkg.R` y `data/MPAs/chatmpa_amps.gpkg` (geometrías de AMP).
- `ltem-nrsi-index` / `conapesca-cpue` ↔ conexión a LTEM/CONAPESCA
  (`docs/mcp_connection.md`, `scripts/connect_rds.py`).

Por ahora las skills quedan **auto-contenidas**; la integración (compartir
geometrías/descargas) es un paso siguiente, no se forzó para no romper nada.
