#!/usr/bin/env bash

set -euo pipefail
trap 'rm -f /tmp/extract.$$' EXIT

# Variables de entorno
JQL_FILTER="_SYSTEMD_UNIT=NetworkManager.service"
OUT_DIR="${OUT_DIR:-out}"
OUT_FILE="$OUT_DIR/logs.csv"

mkdir -p "$OUT_DIR"

# Si journalctl no está, error explícito
if ! command -v journalctl &>/dev/null; then
  echo "Error: journalctl no está disponible" >&2
  exit 2
fi

# Extracción y normalización
journalctl -o json -q -n 100 $JQL_FILTER |
  jq -r '[.["__REALTIME_TIMESTAMP"], .["_SYSTEMD_UNIT"], .["_PID"], .["PRIORITY"], .["MESSAGE"]] | @csv' | \sort -u > "$OUT_FILE"

echo "Logs extraídos y normalizados en $OUT_FILE"
