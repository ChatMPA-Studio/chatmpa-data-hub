#!/usr/bin/env python3
"""Descarga de SST y Chl-a desde ERDDAP — réplica en Python de la forma real.

Basado en scripts/01-SST_data_download.R (rerddap::griddap). Puntos clave que se
replican de la forma real:
  - SST = **OISST v2.1** (`ncdcOisst21Agg_LonPM180`), variable `sst` en °C.
  - Descarga **en trozos anuales** (`--chunk-years`) para no exceder los límites
    de ERDDAP en series largas.
  - Salida **tabular tidy** (long): columnas lon, lat, date, value — igual que el
    data.frame que devuelve rerddap (que en R se guarda como .fst/.RDS).

Variables
---------
  sst  → ncdcOisst21Agg_LonPM180   var 'sst'          (°C, diario, 1981–hoy, 0.25°)
  chl  → erdMH1chla1day            var 'chlorophyll'  (mg/m³, diario, MODIS-Aqua 4 km)
         ⚠️ MODIS-Aqua cubre 2003-01-01 … 2022-07-25. Para datos recientes usa
         VIIRS: edita DATASETS['chl'] a id='nesdisVHNSQchlaDaily' (2012–hoy).

Uso
----
    # SST OISST para el Golfo de California, 1982–2025 (como el script de R)
    python scripts/download_erddap.py sst \
        --bbox 22 32 -116 -106 --start 1982-01-01 --end 2025-12-31

    # Clorofila-a, mismo box, un año
    python scripts/download_erddap.py chl \
        --bbox 22 32 -116 -106 --start 2024-01-01 --end 2024-12-31

  --bbox toma: LAT_MIN LAT_MAX LON_MIN LON_MAX  (longitudes negativas al oeste)
  --chunk-years N  tamaño del trozo temporal (default 1 año)
  --stride N       submuestrea 1 de cada N píxeles
  --out DIR        carpeta de salida (default: ../data/erddap)

Requisitos: requests, pandas  (pip install requests pandas)
Equivalente en R: scripts/01-SST_data_download.R (rerddap + fst).
"""

from __future__ import annotations

import argparse
import io
from datetime import date
from pathlib import Path

import pandas as pd
import requests

SERVER = "https://coastwatch.pfeg.noaa.gov/erddap/griddap"

# zlev: OISST tiene una dimensión de profundidad (zlev=0.0) entre time y latitude;
# MODIS clorofila no la tiene. Se inserta en la URL según corresponda.
DATASETS = {
    "sst": {"id": "ncdcOisst21Agg_LonPM180", "var": "sst",         "units": "degC",  "zlev": True},
    "chl": {"id": "erdMH1chla1day",          "var": "chlorophyll", "units": "mg m-3", "zlev": False},
}


def year_chunks(start: str, end: str, chunk_years: int):
    """Divide [start, end] en trozos de `chunk_years` años (como make_chunks en R)."""
    s = date.fromisoformat(start)
    e = date.fromisoformat(end)
    out = []
    d = s
    while d <= e:
        try:
            nxt = d.replace(year=d.year + chunk_years)
        except ValueError:            # 29-feb → 28-feb
            nxt = d.replace(year=d.year + chunk_years, day=28)
        chunk_end = min(nxt.fromordinal(nxt.toordinal() - 1), e)
        out.append((d.isoformat(), chunk_end.isoformat()))
        d = date.fromordinal(chunk_end.toordinal() + 1)
    return out


def chunk_url(kind: str, bbox, start: str, end: str, stride: int) -> str:
    d = DATASETS[kind]
    lat_min, lat_max, lon_min, lon_max = bbox
    t    = f"[({start}T00:00:00Z):({end}T00:00:00Z)]"
    zlev = "[(0.0)]" if d["zlev"] else ""     # OISST lleva dimensión zlev; MODIS no
    lat  = f"[({lat_min}):{stride}:({lat_max})]"
    lon  = f"[({lon_min}):{stride}:({lon_max})]"
    # ERDDAP griddap en formato .csv → tabla long (time, [zlev,] latitude, longitude, var)
    return f"{SERVER}/{d['id']}.csv?{d['var']}{t}{zlev}{lat}{lon}"


def fetch_chunk(url: str, var: str) -> pd.DataFrame:
    r = requests.get(url, timeout=600)
    r.raise_for_status()
    # La respuesta .csv trae una fila de encabezado y una de unidades → skiprows=[1].
    df = pd.read_csv(io.StringIO(r.text), skiprows=[1])
    df = df.rename(columns={"longitude": "lon", "latitude": "lat",
                            "time": "date", var: "value"})
    df["date"] = pd.to_datetime(df["date"]).dt.date
    return df[["lon", "lat", "date", "value"]].dropna()


def main() -> int:
    ap = argparse.ArgumentParser(description="Descargar SST/Chl-a desde ERDDAP (OISST, chunked).")
    ap.add_argument("kind", choices=["sst", "chl"])
    ap.add_argument("--bbox", nargs=4, type=float, required=True,
                    metavar=("LAT_MIN", "LAT_MAX", "LON_MIN", "LON_MAX"))
    ap.add_argument("--start", required=True, help="YYYY-MM-DD")
    ap.add_argument("--end", required=True, help="YYYY-MM-DD")
    ap.add_argument("--chunk-years", type=int, default=1, help="Años por trozo (default 1)")
    ap.add_argument("--stride", type=int, default=1, help="Submuestreo de píxeles (default 1)")
    ap.add_argument("--out", default=str(Path(__file__).resolve().parent.parent / "data" / "erddap"))
    args = ap.parse_args()

    out_dir = Path(args.out); out_dir.mkdir(parents=True, exist_ok=True)
    d = DATASETS[args.kind]
    chunks = year_chunks(args.start, args.end, args.chunk_years)

    print(f"=== ERDDAP {args.kind.upper()} — {d['id']} ({d['var']}, {d['units']}) ===")
    print(f"  bbox lat {args.bbox[0]}..{args.bbox[1]}  lon {args.bbox[2]}..{args.bbox[3]}  stride={args.stride}")
    print(f"  {args.start} → {args.end}  en {len(chunks)} trozo(s) de {args.chunk_years} año(s)\n")

    frames = []
    for i, (cs, ce) in enumerate(chunks, 1):
        url = chunk_url(args.kind, args.bbox, cs, ce, args.stride)
        print(f"[{i}/{len(chunks)}] {cs} → {ce} ... ", end="", flush=True)
        try:
            df = fetch_chunk(url, d["var"])
            frames.append(df)
            print(f"{len(df):,} filas")
        except Exception as e:            # noqa: BLE001 — igual que el tryCatch de R
            print(f"ERROR: {e}")

    if not frames:
        print("Sin datos descargados."); return 1

    full = pd.concat(frames, ignore_index=True).sort_values(["date", "lat", "lon"])
    out_csv = out_dir / f"{args.kind}_{d['id']}_{args.start}_{args.end}.csv"
    full.to_csv(out_csv, index=False)
    print(f"\n✓ {len(full):,} filas  →  {out_csv}")
    print(f"  rango fechas: {full['date'].min()} → {full['date'].max()}")
    print(f"  {args.kind} ({d['units']}): min {full['value'].min():.2f}  max {full['value'].max():.2f}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
