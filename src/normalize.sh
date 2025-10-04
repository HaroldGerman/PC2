#!/usr/bin/env bash

set -euo pipefail
trap 'rm -f /tmp/normalize.$$' EXIT

INPUT="${INPUT:-out/logs.csv}"
OUT_DIR="${OUT_DIR:-out}"
OUT_CSV="$OUT_DIR/normalized.csv"
OUT_JSON="$OUT_DIR/normalized.json"
METRICS_FILE="$OUT_DIR/metrics.txt"

start=$SECONDS

if [ ! -f "$INPUT" ]; then
  echo "Error: No existe $INPUT" >&2
  echo "normalize,FAIL,$((SECONDS-start))s" >> "$METRICS_FILE"
  exit 1
fi

# Verificar si el archivo está vacío
if [ ! -s "$INPUT" ]; then
  echo "Error: $INPUT está vacío" >&2
  echo "normalize,FAIL,$((SECONDS-start))s" >> "$METRICS_FILE"
  exit 1
fi

echo "Procesando $INPUT..."

# Normalizar: limpiar comillas, espacios, pasar a minúsculas, deduplicar
# Manejar tanto CSV con comillas como sin comillas
{
  # Probar si es CSV con comillas
  if head -1 "$INPUT" | grep -q '^"[^"]*","[^"]*"'; then
    # CSV con comillas - limpiar y procesar
    sed 's/^"//g; s/"$//g; s/","/,/g' "$INPUT" | \
    awk 'BEGIN{FS=","; OFS=","} {
      for(i=1;i<=NF;i++) {
        gsub(/^[ \t]+|[ \t]+$/, "", $i);  # Trim spaces
        $i = tolower($i);                  # To lowercase
      }
      print $0
    }'
  else
    # CSV sin comillas o formato diferente
    awk 'BEGIN{FS=","; OFS=","} {
      for(i=1;i<=NF;i++) {
        gsub(/^[ \t]+|[ \t]+$/, "", $i);  # Trim spaces
        $i = tolower($i);                  # To lowercase
      }
      print $0
    }' "$INPUT"
  fi
} | sort | uniq > /tmp/normalize.$$

# Contar líneas antes y después para métricas
original_lines=$(wc -l < "$INPUT")
normalized_lines=$(wc -l < /tmp/normalize.$$)
duplicates_removed=$((original_lines - normalized_lines))

# Mover el archivo temporal al destino
mv /tmp/normalize.$$ "$OUT_CSV"

# Generar JSON
if [ -s "$OUT_CSV" ]; then
  awk -F',' -v total="$normalized_lines" 'BEGIN{print "["} 
    {
      # Limpiar cada campo
      for(i=1;i<=NF;i++) {
        gsub(/^[ \t]+|[ \t]+$/, "", $i);  # Trim
        gsub(/\"/, "\\\"", $i);           # Escape comillas para JSON
      }
      
      printf "  {\"timestamp\":\"%s\",\"unit\":\"%s\",\"pid\":\"%s\",\"level\":\"%s\",\"message\":\"%s\"}", $1, $2, $3, $4, $5;
      if (NR < total) print ","; else print "";
    } 
  END{print "]"}' "$OUT_CSV" > "$OUT_JSON"
else
  # JSON vacío si no hay datos
  echo "[]" > "$OUT_JSON"
fi

# Registrar métricas
echo "normalize,OK,$((SECONDS-start))s,$normalized_lines,$duplicates_removed" >> "$METRICS_FILE"
echo "Normalización y deduplicación completa:"
echo "   CSV:  $OUT_CSV ($normalized_lines registros)"
echo "   JSON: $OUT_JSON" 
echo "   Duplicados eliminados: $duplicates_removed"
echo "   Tiempo: $((SECONDS-start))s"