#!/usr/bin/env bats


setup() {
  mkdir -p ../out
  rm -f ../out/logs.csv
}

@test "Extrae logs y genera CSV normalizado" {
  run bash src/extract.sh
  [ "$status" -eq 0 ]
  [ -f out/logs.csv ]
  head -n 1 out/logs.csv | grep ','
}

#@test "Falla si journalctl no está" {
#  PATH="/dev/null:$PATH" run bash src/extract.sh
#  [ "$status" -eq 2 ]
#  [[ "$output" == *"journalctl no está disponible"* ]]
#}
