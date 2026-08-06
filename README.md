# chatMPA-data-hub

Hub central de **conexiones, credenciales, datos y skills** para el ecosistema
chatMPA. Reúne el acceso a las bases **LTEM** y **CONAPESCA**, la descarga de
variables oceanográficas (**SST** y **Chl-a**) desde ERDDAP, y un espacio
organizado para capas geoespaciales (polígonos de AMPs) y skills.

## Estructura

```
chatMPA-data-hub/
├── README.md
├── requirements.txt
├── .gitignore
├── credentials_AWS.csv         # credenciales REALES de AWS/RDS (NO se sube — gitignored)
├── dashboard/                  # spec y demo del panel de visualización
│   ├── DASHBOARD.md            # spec completa para ingenieros (layout, KPIs, charts, JSON schema)
│   ├── display_spec.json       # spec KPI/plot legible por máquina, un entry por skill
│   └── demo/
│       ├── README.md           # cómo correr el demo localmente
│       ├── demo.html           # mapa + panel interactivo (Leaflet + Chart.js)
│       ├── demo_data.json      # datos pre-computados para 12 AMPs (~1.1 MB)
│       └── chatMPA-site-standalone.html  # sitio completo con demo embebido
├── docs/
│   ├── mcp_connection.example.md # config MCP con placeholder (SE SUBE)
│   └── mcp_connection.md         # config MCP con token real (NO se sube — gitignored)
├── scripts/
│   ├── _common.py               # carga de credenciales desde el CSV
│   ├── connect_rds.py           # conexión directa a RDS/MySQL (SSL sin verificación)
│   ├── download_erddap.py       # descarga SST (OISST) / Chl-a — Python, chunked
│   └── fetch_erddap.sh          # descarga SST (OISST) / Chl-a — bash/curl, chunked
├── data/                        # AMPs, ERDDAP y otras fuentes (tú agregas)
│   └── README.md
└── skills/                      # skills en R (per-database, interdatabase, shared)
    └── README.md
```

## Setup para colaboradores

El repo **no** trae credenciales ni datos: los archivos con secretos están en
`.gitignore`. Tras clonar, crea tus copias locales a partir de las plantillas
`.example` y pídele al equipo los valores reales.

```bash
git clone https://github.com/ChatMPA-Studio/chatmpa-data-hub.git
cd chatmpa-data-hub

# 1. Credenciales AWS/RDS (LTEM y CONAPESCA) — pide los valores al equipo
cp credentials_AWS.example.csv credentials_AWS.csv
#   edita credentials_AWS.csv: CHANGEME_RDS_HOST / CHANGEME_USER / CHANGEME_PASS

# 2. Config de los MCPs (URL del servidor + token Basic Auth) — pide al equipo
cp docs/mcp_connection.example.md docs/mcp_connection.md
#   reemplaza <MCP_SERVER> y <BASIC_AUTH_TOKEN>, luego pega el bloque JSON
#   en ~/.claude/mcp.json (o .mcp.json) y reinicia el cliente

# 3. Dependencias
pip install -r requirements.txt          # scripts Python (ERDDAP, RDS)
# Skills en R: install.packages(c("sf","dplyr","rerddap","RMySQL","fst"))
```

Los archivos que creas (`credentials_AWS.csv`, `docs/mcp_connection.md`) están
gitignored: nunca se suben. Verifícalo con
`git check-ignore credentials_AWS.csv docs/mcp_connection.md` (debe listar ambos).

> ⚠️ **Datos de CONAPESCA son sensibles** (unidades económicas, RNP, capturas
> individuales). No los subas ni generes salidas que puedan re-identificar una
> unidad económica. Ver `skills/README.md`.

## Seguridad de credenciales

Archivos con secretos, **todos en `.gitignore`** (nunca se suben):
- `credentials_AWS.csv` — credenciales reales de AWS/RDS (LTEM y CONAPESCA).
- `docs/mcp_connection.md` — config MCP con el token Basic Auth real.

Sus contrapartes públicas (con placeholders) **sí** se versionan:
`credentials_AWS.example.csv` y `docs/mcp_connection.example.md`.

## Uso rápido

```bash
# 1. Instalar dependencias
pip install -r requirements.txt

# 2. Conectar a los MCPs → NO requiere scripts: pega la config de
#    docs/mcp_connection.md en ~/.claude/mcp.json (o .mcp.json) y reinicia.

# 3. Descargar SST y Chl-a (Golfo de California)
# SST = OISST v2.1 (chunked por año), salida CSV tidy (lon,lat,date,value)
python scripts/download_erddap.py sst --bbox 22 32 -116 -106 --start 1982-01-01 --end 2025-12-31
python scripts/download_erddap.py chl --bbox 22 32 -116 -106 --start 2020-01-01 --end 2022-07-25
```

## Fuentes de datos

| Fuente     | Acceso                                  | Detalle                          |
|------------|-----------------------------------------|----------------------------------|
| LTEM       | MCP HTTP + AWS RDS MySQL (solo lectura) | Monitoreo ecológico Baja California |
| CONAPESCA  | MCP HTTP + MySQL                        | Producción pesquera (landings)   |
| ERDDAP     | HTTP público (NOAA CoastWatch)          | SST (MUR) y Chl-a (MODIS-Aqua)   |

Ver `docs/mcp_connection.md` para el detalle de conexión.

## Pendientes

- [x] Credenciales RDS de LTEM y CONAPESCA (en `credentials_AWS.csv`, gitignored).
- [x] Conexión a MCPs documentada en `docs/mcp_connection.md` (config lista para pegar).
- [x] Consolidar AMPs → `data/MPAs/chatmpa_amps.gpkg`.
- [x] Skills en `skills/` (ver `skills/README.md`): ltem-fish-biomass, ltem-invertebrate-abundance, conapesca-cpue, conapesca-lfo-regions, erddap-sst-anomaly, erddap-chlorophyll, ltem-nrsi-index, reef-drivers-lm.
- [x] Dashboard spec + demo en `dashboard/` — panel de 6 KPIs, gráfica de grupos tróficos, MHW y Chl-a para 12 AMPs.
- [ ] Integrar skills con el resto del hub (compartir geometrías/descargas ERDDAP).
