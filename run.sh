#!/usr/bin/env bash
# Собирает базу demo.db с нуля, печатает результаты и сверяет их с expected.txt.
# Нужен только sqlite3.
set -euo pipefail
cd "$(dirname "$0")"

rm -f demo.db
sqlite3 demo.db < schema.sql
sqlite3 demo.db < seed.sql

out=$(sqlite3 -separator ' | ' demo.db < queries.sql; sqlite3 -separator ' | ' demo.db < diagnostics.sql)
echo "$out"
echo

if [ "$out" = "$(cat expected.txt)" ]; then
  echo "OK: результаты совпадают с expected.txt"
else
  echo "РАСХОЖДЕНИЕ с expected.txt:"
  diff <(echo "$out") expected.txt || true
  exit 1
fi
