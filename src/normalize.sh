
#!/usr/bin/env bash
set -euo pipefail
trap 'rm -f /tmp/normalize.$$' EXIT

INPUT="${INPUT:-out/logs.csv}"
OUT_DIR="${OUT_DIR:-out}"
OUT_CSV="$OUT_DIR/normalized.csv"
OUT_JSON="$OUT_DIR/normalized.json"

if [ ! -f "$INPUT" ]; then
  echo "Error: No existe $INPUT" >&2
  exit 1
fi

# Normalizar: quitar espacios, pasar a minúsculas, deduplicar
awk 'BEGIN{FS=","; OFS=","} {for(i=1;i<=NF;i++) $i=tolower($i); print $0}' "$INPUT" | sort | uniq > "$OUT_CSV"

# Exportar a JSON simple
awk -F',' 'BEGIN{print "["} {printf "  {\"timestamp\":\"%s\",\"unit\":\"%s\",\"pid\":\"%s\",\"level\":\"%s\",\"message\":\"%s\"},\n", $1,$2,$3,$4,$5} END{print "]"}' "$OUT_CSV" > "$OUT_JSON"

echo "Normalización y deduplicación completa: $OUT_CSV y $OUT_JSON"
