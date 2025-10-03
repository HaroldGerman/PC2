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


## Checklist de entrega Sprint 1

- [x] Scripts Bash robustos en `src/` (`extract.sh`, `normalize.sh`)
- [x] Pruebas Bats funcionales en `tests/` (`extract.bats`, `normalize.bats`)
- [x] Makefile con targets obligatorios y reglas patrón
- [x] Documentación clara en `docs/README.md` y `docs/contrato-salidas.md`
- [x] Suite de pruebas pasando con `make test`
- [x] Archivos generados en `out/` (`logs.csv`, `normalized.csv`, `normalized.json`)
- [x] Bitácora de sprint (si aplica)
- [x] Commit descriptivo en español

## Notas sobre pruebas automatizadas

Las pruebas Bats simulan la entrada `logs.csv` para validar la normalización y deduplicación, independientemente de los datos reales del sistema. El flujo principal del proyecto utiliza los datos extraídos por `extract.sh`.
