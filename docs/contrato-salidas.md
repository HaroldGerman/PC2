# Contrato de salidas

## Archivos generados

| Archivo                | Formato | Descripción                                      | Validación                  |
|------------------------|---------|--------------------------------------------------|-----------------------------|
| out/logs.csv           | CSV     | Extracción de logs (timestamp, unidad, pid, nivel, mensaje) | grep, wc -l, head          |
| out/normalized.csv     | CSV     | Logs normalizados y deduplicados                 | grep, uniq, head            |
| out/normalized.json    | JSON    | Logs normalizados en formato JSON                | jq, grep 'timestamp'        |

## Ejemplo de validación

- Verificar que los archivos existen y tienen formato correcto:
  ```bash
  head -n 2 out/logs.csv
  grep ',' out/normalized.csv
  jq '.' out/normalized.json
  ```
- Validar deduplicación:
  ```bash
  sort out/normalized.csv | uniq -d
  ```
