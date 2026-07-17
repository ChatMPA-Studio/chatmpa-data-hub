#!/usr/bin/env python3
"""Conexión DIRECTA a la base MySQL (AWS RDS) de LTEM / CONAPESCA.

Réplica en Python de la forma real de conexión (ver scripts/conapesca_db_config.r):
el RDS se conecta **con SSL/TLS sin verificación de peer** (en R: `ssl.mode = FALSE`
+ `MARIADB_TLS_DISABLE_PEER_VERIFICATION=1`). Ese es el detalle que hace que la
conexión directa funcione; aquí se replica desactivando la verificación de SSL.

Credenciales (en el CSV de credenciales, method=rds_mysql; mismo host RDS):
  - ltem      → user mcp_ltem_ro      · db ecological_monitoring
  - conapesca → user mcp_conapesca_ro · db conapesca

Cuándo usar la conexión directa en vez de los MCPs (ver docs/mcp_connection.md):
  - Cuando necesitas SQL arbitrario contra la base (no solo las herramientas MCP).
  - Cuando quieres cargar tablas completas a pandas para análisis local
    (equivalente al `tbl(con, "tabla") %>% collect()` de dplyr en R).

Uso
----
    # Probar conexión y listar tablas  (≈ dbListTables en R)
    python scripts/connect_rds.py ltem --tables
    python scripts/connect_rds.py conapesca --tables

    # Ejecutar un SELECT (solo lectura)
    python scripts/connect_rds.py conapesca --sql "SELECT * FROM avisos_arribo LIMIT 5"

    # Volcar el resultado a CSV
    python scripts/connect_rds.py ltem --sql "SELECT * FROM reefs" --out data/reefs.csv

Requisitos: pymysql, pandas  (pip install pymysql pandas)
Nota: la conexión directa requiere que tu IP esté autorizada en el security group
      del RDS. Si cuelga/da timeout, usa los MCPs (docs/mcp_connection.md).
"""

from __future__ import annotations

import argparse
import sys

import pymysql

from _common import get_cred


def get_connection(source: str) -> "pymysql.connections.Connection":
    """Abre la conexión al RDS replicando la forma real (SSL sin verificación).

    En R (RMySQL) esto es `ssl.mode = FALSE`; en pymysql se logra con una conexión
    SSL cuyo certificado no se verifica (ssl_verify_cert / ssl_verify_identity off).
    """
    row = get_cred(source, "rds_mysql")
    if str(row["password"]).startswith("CHANGEME"):
        print(
            f"ERROR: falta el password real del RDS de {source} en credentials_AWS.csv.",
            file=sys.stderr,
        )
        raise SystemExit(2)
    return pymysql.connect(
        host=row["db_host"],
        port=int(row["db_port"]),
        user=row["username"],
        password=row["password"],
        database=row["db_name"],
        cursorclass=pymysql.cursors.DictCursor,
        connect_timeout=10,
        read_timeout=120,
        charset="utf8mb4",
        # SSL/TLS sin verificación de peer (≈ ssl.mode = FALSE en R).
        ssl={"ca": None},
        ssl_verify_cert=False,
        ssl_verify_identity=False,
    )


def main() -> int:
    ap = argparse.ArgumentParser(description="Conexión directa MySQL/RDS (LTEM/CONAPESCA).")
    ap.add_argument("source", choices=["ltem", "conapesca"])
    ap.add_argument("--tables", action="store_true", help="Listar tablas (≈ dbListTables)")
    ap.add_argument("--sql", help="SELECT a ejecutar (solo lectura)")
    ap.add_argument("--out", help="Guardar resultado como CSV (requiere pandas)")
    args = ap.parse_args()

    sql = "SHOW TABLES" if args.tables else args.sql
    if not sql:
        ap.error("Especifica --tables o --sql")
    if not args.tables and not sql.lstrip().lower().startswith("select"):
        ap.error("Solo se permiten consultas SELECT (acceso de solo lectura).")

    conn = get_connection(args.source)
    try:
        with conn.cursor() as cur:
            cur.execute(sql)
            rows = cur.fetchall()
    finally:
        conn.close()

    if args.out:
        import pandas as pd
        pd.DataFrame(rows).to_csv(args.out, index=False)
        print(f"✓ {len(rows)} filas → {args.out}")
    else:
        for r in rows[:50]:
            print(r)
        print(f"... {len(rows)} filas" if len(rows) > 50 else f"{len(rows)} filas")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
