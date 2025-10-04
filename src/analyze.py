#!/usr/bin/env python3
"""
analyze.py - Analizador de logs normalizados para incidentes HTTP/DNS/TLS
"""

import csv
import json
import os
import sys
from collections import Counter
from datetime import datetime

# Configuración
CSV_INPUT = "out/normalized.csv"
JSON_INPUT = "out/normalized.json"
METRICS_FILE = "out/metrics.txt"

def log_metric(operation, status, duration, records=0):
    """Registra métricas de ejecución"""
    try:
        with open(METRICS_FILE, "a", encoding="utf-8") as f:
            timestamp = datetime.now().isoformat()
            f.write(f"{operation},{status},{duration},{records},{timestamp}\n")
    except Exception as e:
        print(f"No se pudieron guardar métricas: {e}")

def analyze_csv():
    """Analiza archivo CSV normalizado"""
    counts = Counter()
    units = Counter()
    try:
        with open(CSV_INPUT, 'r', encoding='utf-8') as f:
            # Detectar delimitador
            first_line = f.readline().strip()
            delimiter = ',' if ',' in first_line else ';'
            f.seek(0)
            
            reader = csv.reader(f, delimiter=delimiter)
            for row_num, row in enumerate(reader, 1):
                if len(row) >= 5:
                    try:
                        timestamp, unit, pid, level, message = row[:5]
                        
                        # Limpiar y normalizar campos
                        level = level.strip().upper() if level else 'UNKNOWN'
                        unit = unit.strip() if unit else 'UNKNOWN'
                        message = message.strip() if message else ''
                        
                        # Contar por nivel de severidad
                        counts[level] += 1
                        
                        # Contar por unidad de sistema
                        units[unit] += 1
                        
                        # Detectar incidentes específicos
                        message_lower = message.lower()
                        
                        # HTTP/HTTPS
                        if any(term in message_lower for term in ['http', 'https', 'web', 'request', 'response', 'get ', 'post ', 'put ', 'delete ']):
                            counts['HTTP_RELATED'] += 1
                            counts['INCIDENT_HTTP'] += 1
                            
                        # DNS
                        if any(term in message_lower for term in ['dns', 'resolve', 'domain', 'nameserver', 'query', 'lookup']):
                            counts['DNS_RELATED'] += 1
                            counts['INCIDENT_DNS'] += 1
                            
                        # TLS/SSL
                        if any(term in message_lower for term in ['tls', 'ssl', 'certificate', 'handshake', 'cipher', 'encryption']):
                            counts['TLS_RELATED'] += 1
                            counts['INCIDENT_TLS'] += 1
                            
                        # Errores y advertencias
                        if 'error' in message_lower or 'fail' in message_lower:
                            counts['CONTAINS_ERROR'] += 1
                        if 'warn' in message_lower:
                            counts['CONTAINS_WARN'] += 1
                            
                    except Exception as e:
                        print(f"Advertencia: Error procesando fila {row_num}: {e}")
                        continue
                        
        return counts, units
        
    except FileNotFoundError:
        print(f"Error: No se encuentra {CSV_INPUT}")
        return None, None
    except Exception as e:
        print(f"Error inesperado analizando CSV: {e}")
        return None, None

def analyze_json():
    """Analiza archivo JSON normalizado"""
    counts = Counter()
    units = Counter()
    try:
        with open(JSON_INPUT, 'r', encoding='utf-8') as f:
            data = json.load(f)
            for entry in data:
                level = entry.get('level', '').strip().upper()
                unit = entry.get('unit', '').strip()
                message = entry.get('message', '').strip()
                
                counts[level] += 1
                units[unit] += 1
                
                message_lower = message.lower()
                
                # HTTP/HTTPS
                if any(term in message_lower for term in ['http', 'https', 'web', 'request', 'response']):
                    counts['HTTP_RELATED'] += 1
                    counts['INCIDENT_HTTP'] += 1
                    
                # DNS
                if any(term in message_lower for term in ['dns', 'resolve', 'domain', 'nameserver']):
                    counts['DNS_RELATED'] += 1
                    counts['INCIDENT_DNS'] += 1
                    
                # TLS/SSL
                if any(term in message_lower for term in ['tls', 'ssl', 'certificate', 'handshake']):
                    counts['TLS_RELATED'] += 1
                    counts['INCIDENT_TLS'] += 1
                    
                # Errores y advertencias
                if 'error' in message_lower or 'fail' in message_lower:
                    counts['CONTAINS_ERROR'] += 1
                if 'warn' in message_lower:
                    counts['CONTAINS_WARN'] += 1
                    
        return counts, units
        
    except FileNotFoundError:
        print(f"Error: No se encuentra {JSON_INPUT}")
        return None, None
    except Exception as e:
        print(f"Error inesperado analizando JSON: {e}")
        return None, None

def display_results(counts, units):
    """Muestra resultados del análisis"""
    if not counts:
        print("No hay datos para analizar")
        return
    
    # Calcular total de registros únicos (excluyendo categorías especiales)
    base_categories = [level for level in counts if not level.startswith(('INCIDENT_', 'CONTAINS_', 'HTTP_RELATED', 'DNS_RELATED', 'TLS_RELATED'))]
    total_records = sum(counts[level] for level in base_categories)
    
    print("\n" + "="*60)
    print("ANÁLISIS DE LOGS NORMALIZADOS")
    print("="*60)
    
    print(f"\nESTADÍSTICAS GENERALES")
    print(f"   Total de registros: {total_records}")
    
    # Niveles de severidad
    print(f"\nNIVELES DE SEVERIDAD")
    severity_levels = ['0', '1', '2', '3', '4', '5', '6', '7', 'EMERG', 'ALERT', 'CRIT', 'ERROR', 'WARN', 'NOTICE', 'INFO', 'DEBUG', 'UNKNOWN']
    found_levels = [(level, counts[level]) for level in severity_levels if counts[level] > 0]
    
    for level, count in sorted(found_levels, key=lambda x: x[1], reverse=True):
        percentage = (count / total_records) * 100 if total_records > 0 else 0
        print(f"   Nivel {level}: {count:3d} registros ({percentage:5.1f}%)")
    
    # Incidentes específicos
    print(f"\nINCIDENTES DETECTADOS")
    incidents = {
        'INCIDENT_HTTP': 'HTTP/HTTPS',
        'INCIDENT_DNS': 'DNS', 
        'INCIDENT_TLS': 'TLS/SSL',
        'CONTAINS_ERROR': 'Contiene errores',
        'CONTAINS_WARN': 'Contiene advertencias'
    }
    
    for incident_key, incident_name in incidents.items():
        count = counts.get(incident_key, 0)
        if count > 0:
            percentage = (count / total_records) * 100 if total_records > 0 else 0
            print(f"   {incident_name}: {count:3d} registros ({percentage:5.1f}%)")
    
    # Unidades de sistema
    print(f"\nUNIDADES DE SISTEMA (Top 5)")
    if units:
        for unit, count in units.most_common(5):
            percentage = (count / total_records) * 100 if total_records > 0 else 0
            print(f"   {unit}: {count:3d} registros ({percentage:5.1f}%)")
    
    # Resumen de protocolos
    print(f"\nRESUMEN DE PROTOCOLOS")
    protocol_counts = {
        'HTTP_RELATED': 'Registros HTTP/HTTPS',
        'DNS_RELATED': 'Registros DNS',
        'TLS_RELATED': 'Registros TLS/SSL'
    }
    
    for protocol_key, protocol_name in protocol_counts.items():
        count = counts.get(protocol_key, 0)
        if count > 0:
            percentage = (count / total_records) * 100 if total_records > 0 else 0
            print(f"   {protocol_name}: {count:3d} registros ({percentage:5.1f}%)")
    
    # Recomendaciones basadas en el análisis
    print(f"\nRECOMENDACIONES")
    if counts.get('CONTAINS_ERROR', 0) > 0:
        print("   Revisar registros con errores para identificar problemas críticos")
    if counts.get('INCIDENT_TLS', 0) > 0:
        print("   Verificar configuración TLS/SSL en servicios identificados")
    if counts.get('INCIDENT_DNS', 0) > 0:
        print("   Revisar resolución DNS y configuración de dominios")
    
    if total_records == 0:
        print("   No se encontraron registros para analizar")
    elif counts.get('CONTAINS_ERROR', 0) == 0 and counts.get('CONTAINS_WARN', 0) == 0:
        print("   No se detectaron problemas críticos en los logs analizados")

def main():
    """Función principal"""
    start_time = datetime.now()
    
    print("Iniciando análisis de logs normalizados...")
    
    # Verificar qué archivo existe
    if os.path.exists(CSV_INPUT):
        print(f"Analizando archivo CSV: {CSV_INPUT}")
        counts, units = analyze_csv()
    elif os.path.exists(JSON_INPUT):
        print(f"Analizando archivo JSON: {JSON_INPUT}")
        counts, units = analyze_json()
    else:
        print(f"Error: No se encuentran archivos de datos en {CSV_INPUT} o {JSON_INPUT}")
        print("   Ejecute 'make build' o 'make test-data' primero")
        log_metric("analyze", "FAIL", "0s", 0)
        sys.exit(1)
    
    if counts is None:
        log_metric("analyze", "FAIL", "0s", 0)
        sys.exit(1)
    
    # Mostrar resultados
    display_results(counts, units)
    
    # Calcular tiempo de ejecución
    duration = datetime.now() - start_time
    total_records = sum(counts[level] for level in counts if not level.startswith(('INCIDENT_', 'CONTAINS_', 'HTTP_RELATED', 'DNS_RELATED', 'TLS_RELATED')))

    # Registrar métricas
    log_metric("analyze", "OK", f"{duration.total_seconds():.2f}s", total_records)
    
    print(f"\nAnálisis completado en {duration.total_seconds():.2f} segundos")
    print(f"   {total_records} registros procesados")
    print(f"   Métricas guardadas en: {METRICS_FILE}")

if __name__ == "__main__":
    main()