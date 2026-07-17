"""Utilidades compartidas: carga de credenciales desde el CSV de la raíz.

Los scripts de conexión leen las credenciales de un CSV en la raíz del proyecto.
Se busca, en orden: credentials.csv, credentials_AWS.csv, credentials.example.csv.
Todos (menos el .example) están en .gitignore y NUNCA deben subirse.

Los CSV pueden tener columnas distintas; sólo se exige que las filas relevantes
tengan las que use cada script (p. ej. connect_rds.py usa db_host/db_port/
username/password/db_name).
"""

from __future__ import annotations

import base64
import csv
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
# Candidatos en orden de preferencia (el primero que exista se usa).
CANDIDATES = ["credentials.csv", "credentials_AWS.csv", "credentials.example.csv"]


def _cred_file() -> Path:
    for name in CANDIDATES:
        p = ROOT / name
        if p.exists():
            return p
    raise FileNotFoundError(
        f"No se encontró ningún CSV de credenciales en {ROOT} "
        f"(buscados: {', '.join(CANDIDATES)})."
    )


def load_credentials() -> list[dict]:
    """Devuelve todas las filas del CSV de credenciales como lista de dicts.

    Tolerante a la codificación: intenta UTF-8 y cae a Latin-1 (algunos CSV se
    guardan en Windows-1252 y traen acentos no-UTF8 en columnas de notas).
    """
    path = _cred_file()
    for enc in ("utf-8", "latin-1"):
        try:
            with path.open(newline="", encoding=enc) as fh:
                return list(csv.DictReader(fh))
        except UnicodeDecodeError:
            continue
    with path.open(newline="", encoding="utf-8", errors="replace") as fh:
        return list(csv.DictReader(fh))


def get_cred(source: str, method: str) -> dict:
    """Devuelve la fila que coincide con (source, method).

    Ej: get_cred("ltem", "mcp_http") o get_cred("conapesca", "rds_mysql").
    """
    for row in load_credentials():
        if row["source"] == source and row["method"] == method:
            return row
    raise KeyError(f"No hay credencial para source={source!r} method={method!r}")


def basic_auth_header(row: dict) -> str:
    """Construye el header 'Basic <b64>' a partir de una fila de credenciales.

    Usa basic_auth_b64 si está presente; si no, lo calcula de username:password.
    """
    b64 = (row.get("basic_auth_b64") or "").strip()
    if not b64 or b64.startswith("CHANGEME"):
        raw = f"{row['username']}:{row['password']}".encode()
        b64 = base64.b64encode(raw).decode()
    return f"Basic {b64}"
