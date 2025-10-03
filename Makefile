# ===========================
# Makefile - Sprint 1
# ===========================

SHELL := /bin/bash
OUT_DIR := out

# Variables de entorno (ejemplo)
JQL_FILTER ?= _SYSTEMD_UNIT=systemd

.PHONY: tools build test run pack clean help

tools:
	@echo "🔍 Verificando herramientas necesarias..."
	@command -v journalctl >/dev/null 2>&1 || { echo "Falta journalctl"; exit 1; }
	@command -v grep >/dev/null 2>&1 || { echo "Falta grep"; exit 1; }
	@command -v awk >/dev/null 2>&1 || { echo "Falta awk"; exit 1; }
	@command -v bats >/dev/null 2>&1 || { echo "Falta bats"; exit 1; }
	@echo "✅ Todas las herramientas están disponibles."


# Extracción solo si logs.csv no existe o src/extract.sh cambió
$(OUT_DIR)/logs.csv: src/extract.sh
	@echo "⚙️ Extrayendo logs..."
	bash src/extract.sh

# Normalización solo si normalized.csv no existe o src/normalize.sh cambió
$(OUT_DIR)/normalized.csv: src/normalize.sh $(OUT_DIR)/logs.csv
	@echo "🔄 Normalizando logs..."
	bash src/normalize.sh

build: $(OUT_DIR)/logs.csv

run: $(OUT_DIR)/normalized.csv

test:
	@echo "🧪 Ejecutando pruebas con Bats..."
	bats tests/


pack:
	@echo "📦 Empaquetando resultados..."
	@mkdir -p dist
	tar -czf dist/proyecto-sprint1.tar.gz src tests out Makefile docs
	@echo "✅ Paquete generado en dist/proyecto-sprint1.tar.gz"


clean:
	@echo "🧹 Limpiando archivos..."
	rm -rf $(OUT_DIR) dist
	@echo "✅ Limpieza completa."


help:
	@echo "Targets disponibles:"
	@echo "  make tools      -> Verifica herramientas"
	@echo "  make build      -> Extrae logs a out/logs.csv"
	@echo "  make run        -> Normaliza y deduplica a out/normalized.csv/json"
	@echo "  make test       -> Corre pruebas Bats"
	@echo "  make pack       -> Empaqueta en dist/"
	@echo "  make clean      -> Limpia salidas"
	@echo "  make help       -> Muestra esta ayuda"
