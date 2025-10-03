# Normalizador de logs de journalctl para incidentes HTTP/DNS/TLS

## Instrucciones de uso

1. Verifica herramientas:
   ```bash
   make tools
   ```
2. Extrae logs:
   ```bash
   make build
   ```
3. Normaliza y deduplica:
   ```bash
   make run
   ```
4. Ejecuta pruebas:
   ```bash
   make test
   ```
5. Empaqueta resultados:
   ```bash
   make pack
   ```

## Variables de entorno

| Variable     | Efecto observable                                      |
|-------------|--------------------------------------------------------|
| JQL_FILTER  | Filtro para journalctl (ej: _SYSTEMD_UNIT=systemd)     |
| OUT_DIR     | Directorio de salida para archivos intermedios         |
| INPUT       | Ruta de entrada para normalización (por defecto logs.csv) |

## Contrato de salidas

- `out/logs.csv`: Extracción de logs en formato CSV (timestamp, unidad, pid, nivel, mensaje)
- `out/normalized.csv`: Logs normalizados y deduplicados en minúsculas
- `out/normalized.json`: Logs normalizados en formato JSON

## Ejemplo de validación

```bash
grep 'http' out/normalized.csv
jq '.' out/normalized.json
```

## Métodos de validación
- Verificar formato CSV: campos separados por coma
- Validar deduplicación: líneas únicas
- Validar JSON: campos clave presentes
