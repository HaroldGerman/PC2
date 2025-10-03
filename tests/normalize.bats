#!/usr/bin/env bats

setup() {
  mkdir -p out
  # Simular logs.csv de entrada
  echo '2025-09-25T22:00:00,systemd,1234,info,Primer log simulado' > out/logs.csv
  echo '2025-09-25T22:01:00,systemd,1235,info,Segundo log simulado' >> out/logs.csv
  echo '2025-09-25T22:00:00,systemd,1234,info,Primer log simulado' >> out/logs.csv # Duplicado
}

teardown() {
  rm -f out/logs.csv out/normalized.csv out/normalized.json
}

@test "Normaliza y deduplica registros en CSV" {
  run bash src/normalize.sh
  [ "$status" -eq 0 ]
  [ -f out/normalized.csv ]
  [ -s out/normalized.csv ]
}

@test "Genera JSON normalizado" {
  run bash src/normalize.sh
  [ -f out/normalized.json ]
  grep '"timestamp"' out/normalized.json
  grep '"unit"' out/normalized.json
}

@test "Falla si falta logs.csv" {
  rm -f out/logs.csv
  run bash src/normalize.sh
  [ "$status" -eq 1 ]
  [[ "$output" == *"No existe"* ]]
}
