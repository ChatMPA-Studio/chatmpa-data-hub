# data/

Carpeta para fuentes de datos geoespaciales y tabulares del proyecto.

## Qué va aquí

- **Polígonos de AMPs** (Áreas Marinas Protegidas): shapefiles, GeoPackage,
  GeoJSON. Sugerido: `data/amps/`.
- **Otras capas** (batimetría, EEZ, zonas de pesca, etc.): `data/<fuente>/`.
- **Descargas de ERDDAP** (SST, Chl-a): los scripts las guardan en
  `data/erddap/` por defecto.

## Estructura sugerida

```
data/
├── MPAs/           # AMPs — fuentes crudas + GeoPackage consolidado (ver abajo)
├── erddap/         # SST y Chl-a descargados (generado por los scripts)
└── <otras_fuentes>/
```

## AMPs consolidadas — `data/MPAs/chatmpa_amps.gpkg`

GeoPackage consolidado con **solo nuestras 4 AMPs** en **una sola capa**
(`amps_subzonas`, 69 features): cada feature es una **subzona**, y la AMP, la
zonificación y el nivel de protección son **atributos/categorías**. Generado con
`scripts/build_amps_gpkg.R` (reproducible). CRS EPSG:4326.

**Fuentes:**
- **CONANP** (`MPAs/mpas/MPA_v2_2024-03-20.shp`) → subzonas (geometría base) y
  atributos oficiales de zonificación/pesca.
- **Protected Seas** (`MPAs/protected_seas/{fully,highly}/`) → clasificación
  *fully/highly* protegido contra la pesca, cruzada espacialmente sobre las
  subzonas (mejor delimitada **donde existe**).

**Capa `amps_subzonas`** — cada feature es una subzona, con estos campos:

| Campo | Descripción |
|-------|-------------|
| `amp_id`, `amp_name` | Identificador y nombre canónico de la AMP (categoría). |
| `subzona`, `categoria`, `zonificacion`, `subzonificacion` | Zonificación CONANP. |
| `pesca`, `buceo` | Uso permitido/prohibido según CONANP. |
| `no_take` | TRUE si la subzona es no-take contra la pesca (unifica ambas fuentes). |
| `protection_level` | `fully` / `highly` (Protected Seas) · `no_take_conanp` (CONANP, Pesca prohibida) · `aprovechamiento` (uso permitido). |
| `protection_source` | `ProtectedSeas` o `CONANP`, según de dónde salió el nivel. |
| `ps_fully_frac`, `ps_highly_frac` | Fracción de la subzona cubierta por Protected Seas fully/highly. |
| `area_km2` | Área geodésica de la subzona. |

**Regla de `protection_level`** (sigue: *subzonas de CONANP; fully/highly de
Protected Seas donde exista*): una subzona es `fully`/`highly` si ≥50 % de su
área cae dentro del polígono correspondiente de Protected Seas; si no, se marca
`no_take_conanp` cuando CONANP indica `Pesca = Prohibida`, o `aprovechamiento`
si la pesca está permitida.

> ⚠️ Cobertura de Protected Seas: de nuestras 4 AMPs, solo **Revillagigedo**
> aparece en las capas fully/highly (2 subzonas → `fully`; el resto del parque,
> también no-take, queda como `no_take_conanp`). Para Cabo Pulmo, Loreto y
> Espíritu Santo el no-take proviene de CONANP. Si consigues las capas de
> Protected Seas para esas 3, vuelve a correr el script para incorporarlas.

Regenerar: `Rscript scripts/build_amps_gpkg.R`

## Nota sobre archivos pesados

Por defecto, `.gitignore` **excluye** archivos grandes descargados (`.nc`,
`.tif`, `.zip`) para no inflar el repo. Si quieres versionar capas concretas
(p. ej. los polígonos de AMPs en GeoJSON), puedes:

1. Forzar su inclusión: `git add -f data/amps/mi_poligono.geojson`, o
2. Quitar el patrón correspondiente del `.gitignore`.

Para datos muy pesados considera **Git LFS** o un almacenamiento externo (S3,
Drive) referenciado desde aquí.

> Cuando agregues los polígonos de AMPs y otras fuentes, avísame y te ayudo a
> organizarlos, documentar su origen/CRS y escribir loaders si hace falta.
