#!/bin/bash
# Descarga SST (OISST v2.1) o Chl-a desde ERDDAP con curl, en trozos anuales.
# Réplica ligera de scripts/01-SST_data_download.R / download_erddap.py.
#
# Uso:
#   ./fetch_erddap.sh sst --bbox 22,32 -116,-106 --start 1982-01-01 --end 2025-12-31
#   ./fetch_erddap.sh chl --bbox 22,32 -116,-106 --start 2024-01-01 --end 2024-12-31
#
# Args:
#   1º posicional  sst | chl
#   --bbox LAT_MIN,LAT_MAX LON_MIN,LON_MAX
#   --start YYYY-MM-DD  --end YYYY-MM-DD
#   --stride N   (opcional) submuestreo, default 1
#   --out DIR    (opcional) carpeta salida, default ../data/erddap
#
# Salida: un CSV tidy (time,latitude,longitude,var) concatenando los trozos.
set -e

KIND="$1"; shift || true
case "$KIND" in
  sst) DATASET="ncdcOisst21Agg_LonPM180"; VAR="sst";         ZLEV="[(0.0)]" ;; # OISST v2.1, °C (lleva zlev)
  chl) DATASET="erdMH1chla1day";          VAR="chlorophyll"; ZLEV="" ;;        # MODIS-Aqua, mg/m³ (2003–2022-07)
  *) echo "Primer argumento debe ser 'sst' o 'chl'"; exit 1 ;;
esac

STRIDE=1
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="$SCRIPT_DIR/../data/erddap"

while [[ $# -gt 0 ]]; do
  case $1 in
    --bbox)   IFS=',' read -r LAT_MIN LAT_MAX <<< "$2"
              IFS=',' read -r LON_MIN LON_MAX <<< "$3"; shift 3 ;;
    --start)  START_DATE="$2"; shift 2 ;;
    --end)    END_DATE="$2"; shift 2 ;;
    --stride) STRIDE="$2"; shift 2 ;;
    --out)    OUTPUT_DIR="$2"; shift 2 ;;
    *) echo "Opción desconocida: $1"; exit 1 ;;
  esac
done

if [ -z "$LAT_MIN" ] || [ -z "$LON_MIN" ] || [ -z "$START_DATE" ] || [ -z "$END_DATE" ]; then
  echo "Uso: $0 sst|chl --bbox LAT_MIN,LAT_MAX LON_MIN,LON_MAX --start YYYY-MM-DD --end YYYY-MM-DD [--stride N] [--out DIR]"
  exit 1
fi

mkdir -p "$OUTPUT_DIR"
BASE_URL="https://coastwatch.pfeg.noaa.gov/erddap/griddap"
OUTPUT_FILE="${OUTPUT_DIR}/${KIND}_${DATASET}_${START_DATE}_${END_DATE}.csv"
: > "$OUTPUT_FILE"

echo "Variable : $KIND ($VAR)  Dataset: $DATASET"
echo "Región   : lat ${LAT_MIN},${LAT_MAX}  lon ${LON_MIN},${LON_MAX}  stride=${STRIDE}"
echo "Periodo  : ${START_DATE} → ${END_DATE}  (trozos anuales)"

START_YEAR=${START_DATE:0:4}
END_YEAR=${END_DATE:0:4}
FIRST=1
for YEAR in $(seq "$START_YEAR" "$END_YEAR"); do
  C_START="$YEAR-01-01"; C_END="$YEAR-12-31"
  [ "$YEAR" = "$START_YEAR" ] && C_START="$START_DATE"
  [ "$YEAR" = "$END_YEAR" ]   && C_END="$END_DATE"
  CONSTRAINTS="[(${C_START}T00:00:00Z):(${C_END}T00:00:00Z)]${ZLEV}[(${LAT_MIN}):${STRIDE}:(${LAT_MAX})][(${LON_MIN}):${STRIDE}:(${LON_MAX})]"
  URL="${BASE_URL}/${DATASET}.csv?${VAR}${CONSTRAINTS}"
  echo -n "  [$YEAR] descargando ... "
  if [ "$FIRST" = "1" ]; then
    curl -g -s "$URL" >> "$OUTPUT_FILE"; FIRST=0            # incluye encabezado
  else
    curl -g -s "$URL" | tail -n +3 >> "$OUTPUT_FILE"        # sin encabezado ni unidades
  fi
  echo "ok"
done

echo "✓ $OUTPUT_FILE  ($(ls -lh "$OUTPUT_FILE" | awk '{print $5}'))"
echo "Cargar en R:      d <- readr::read_csv('$OUTPUT_FILE')"
echo "Cargar en Python: import pandas as pd; d = pd.read_csv('$OUTPUT_FILE')"
