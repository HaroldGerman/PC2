# ===========================
# Makefile - Proyecto 9: Normalizador de logs
# ===========================

SHELL := /bin/bash
OUT_DIR := out
SCRIPTS_DIR := src
TESTS_DIR := tests

# Variables de entorno
JQL_FILTER ?= 
DEFAULT_FILTER ?= --since "1 hour ago"

.PHONY: tools build test run pack clean help all normalize analyze test-data http-logs dns-logs network-logs docker-logs monitor

# Comando principal - ejecuta todo el pipeline
all: build normalize analyze

tools:
	@echo "Verificando herramientas necesarias..."
	@command -v journalctl >/dev/null 2>&1 || echo "journalctl no encontrado (puede ser normal en algunos sistemas)"
	@command -v jq >/dev/null 2>&1 || { echo "Falta jq"; exit 1; }
	@command -v grep >/dev/null 2>&1 || { echo "Falta grep"; exit 1; }
	@command -v awk >/dev/null 2>&1 || { echo "Falta awk"; exit 1; }
	@command -v bats >/dev/null 2>&1 || { echo "Falta bats"; exit 1; }
	@command -v python3 >/dev/null 2>&1 || { echo "Falta python3"; exit 1; }
	@echo "Todas las herramientas están disponibles."

# Extracción solo si logs.csv no existe o src/extract.sh cambió
$(OUT_DIR)/logs.csv: src/extract.sh
	@echo "Extrayendo logs..."
	@mkdir -p $(OUT_DIR)
	bash src/extract.sh

# Normalización solo si normalized.csv no existe o src/normalize.sh cambió
$(OUT_DIR)/normalized.csv: src/normalize.sh $(OUT_DIR)/logs.csv
	@echo "Normalizando logs..."
	bash src/normalize.sh

# Análisis de logs normalizados
analyze: $(OUT_DIR)/normalized.csv
	@echo "Analizando logs..."
	@python3 src/analyze.py

build: tools $(OUT_DIR)/logs.csv

normalize: $(OUT_DIR)/normalized.csv

run: analyze

test: tools
	@echo "Ejecutando pruebas con Bats..."
	@bats $(TESTS_DIR)/

pack:
	@echo "Empaquetando resultados..."
	@mkdir -p dist
	tar -czf dist/proyecto-logs.tar.gz $(SCRIPTS_DIR) $(TESTS_DIR) $(OUT_DIR) Makefile analyze.py README.md 2>/dev/null || \
	tar -czf dist/proyecto-logs.tar.gz $(SCRIPTS_DIR) $(TESTS_DIR) Makefile analyze.py README.md
	@echo "Paquete generado en dist/proyecto-logs.tar.gz"

clean:
	@echo "Limpiando archivos..."
	rm -rf $(OUT_DIR) dist
	@echo "Limpieza completa."

# Comandos específicos para filtros
http-logs:
	@echo "Extrayendo logs HTTP..."
	JQL_FILTER="_SYSTEMD_UNIT=nginx.service OR _SYSTEMD_UNIT=apache2.service" bash $(SCRIPTS_DIR)/extract.sh
	@make normalize analyze

dns-logs:
	@echo "Extrayendo logs DNS..."
	JQL_FILTER="_SYSTEMD_UNIT=systemd-resolved.service" bash $(SCRIPTS_DIR)/extract.sh
	@make normalize analyze

network-logs:
	@echo "Extrayendo logs de red..."
	JQL_FILTER="_SYSTEMD_UNIT=NetworkManager.service OR _SYSTEMD_UNIT=systemd-networkd.service" bash $(SCRIPTS_DIR)/extract.sh
	@make normalize analyze

docker-logs:
	@echo "Extrayendo logs de Docker..."
	JQL_FILTER="_SYSTEMD_UNIT=docker.service OR _SYSTEMD_UNIT=containerd.service" bash $(SCRIPTS_DIR)/extract.sh
	@make normalize analyze

# Datos de prueba para desarrollo y testing
test-data:
	@echo "Generando datos de prueba..."
	@mkdir -p $(OUT_DIR)
	@echo '"1737835200000000","systemd","1234","6","Servicio del sistema iniciado"' > $(OUT_DIR)/logs.csv
	@echo '"1737835260000000","NetworkManager.service","5678","5","Gestor de redes activo - Configuración DNS aplicada"' >> $(OUT_DIR)/logs.csv
	@echo '"1737835320000000","docker.service","9012","4","Contenedor iniciado - Servicio HTTP en puerto 8080"' >> $(OUT_DIR)/logs.csv
	@echo '"1737835380000000","nginx.service","3456","3","Solicitud HTTP GET /index.html procesada - TLS v1.3"' >> $(OUT_DIR)/logs.csv
	@echo '"1737835440000000","systemd-resolved.service","7890","2","Consulta DNS para example.com resuelta"' >> $(OUT_DIR)/logs.csv
	@echo '"1737835500000000","apache2.service","2345","4","Error TLS: certificado expirado en dominio example.com"' >> $(OUT_DIR)/logs.csv
	@echo "Datos de prueba generados en $(OUT_DIR)/logs.csv (6 registros)"

# Monitoreo en tiempo real
monitor:
	@echo "Monitoreo en tiempo real (Ctrl+C para detener)..."
	@echo "Filtrando logs HTTP/DNS/TLS:"
	@sudo journalctl -f | grep -E -i "http|https|dns|tls|ssl|certificate" || \
	echo "No se encontraron logs en tiempo real con los filtros aplicados"

# Verificación del sistema
status:
	@echo "Estado del proyecto:"
	@echo "Directorio de salida: $(OUT_DIR)"
	@if [ -d "$(OUT_DIR)" ]; then \
		echo "$(OUT_DIR) existe"; \
		ls -la $(OUT_DIR)/ 2>/dev/null || echo "   (vacío)"; \
	else \
		echo "$(OUT_DIR) no existe"; \
	fi
	@echo ""
	@echo "Archivos de datos:"
	@for file in logs.csv normalized.csv normalized.json metrics.txt; do \
		if [ -f "$(OUT_DIR)/$$file" ]; then \
			lines=$$(wc -l < "$(OUT_DIR)/$$file" 2>/dev/null || echo 0); \
			size=$$(du -h "$(OUT_DIR)/$$file" 2>/dev/null | cut -f1 || echo "0B"); \
			echo "$(OUT_DIR)/$$file ($$lines líneas, $$size)"; \
		else \
			echo "$(OUT_DIR)/$$file (no existe)"; \
		fi; \
	done

help:
	@echo "Proyecto 9: Normalizador de logs de journalctl"
	@echo ""
	@echo "Comandos disponibles:"
	@echo "  make all          → Ejecuta pipeline completo (build+normalize+analyze)"
	@echo "  make tools        → Verifica herramientas necesarias"
	@echo "  make build        → Extrae logs a out/logs.csv"
	@echo "  make normalize    → Normaliza a out/normalized.csv/json"
	@echo "  make analyze      → Analiza logs normalizados"
	@echo "  make run          → Ejecuta pipeline completo"
	@echo "  make test         → Ejecuta pruebas Bats"
	@echo "  make pack         → Empaqueta proyecto en dist/"
	@echo "  make clean        → Limpia archivos generados"
	@echo ""
	@echo "Comandos específicos:"
	@echo "  make http-logs    → Filtra y analiza logs HTTP"
	@echo "  make dns-logs     → Filtra y analiza logs DNS" 
	@echo "  make network-logs → Filtra y analiza logs de red"
	@echo "  make docker-logs  → Filtra y analiza logs de Docker"
	@echo "  make test-data    → Genera datos de prueba para desarrollo"
	@echo "  make monitor      → Monitoreo en tiempo real"
	@echo "  make status       → Muestra estado actual del proyecto"
	@echo "  make help         → Muestra esta ayuda"
	@echo ""
	@echo "Variables de entorno:"
	@echo "  JQL_FILTER    → Filtro personalizado para journalctl (ej: JQL_FILTER='_SYSTEMD_UNIT=nginx.service')"
	@echo "  OUT_DIR       → Directorio de salida (por defecto: out)"
	@echo ""
	@echo "Ejemplos de uso:"
	@echo "  JQL_FILTER='_SYSTEMD_UNIT=nginx.service' make all"
	@echo "  make test-data && make run"
	@echo "  make http-logs"