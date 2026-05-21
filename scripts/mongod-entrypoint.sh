#!/usr/bin/env bash
# WiredTiger cache = 50% of MONGO_MEMORY_LIMIT (same units as compose mem_limit).
set -eu
set -o pipefail

limit="${MONGO_MEMORY_LIMIT:-2g}"
limit="$(printf '%s' "$limit" | tr '[:upper:]' '[:lower:]')"

if [[ "$limit" =~ ^([0-9]+(\.[0-9]+)?)([bkmg])?$ ]]; then
  num="${BASH_REMATCH[1]}"
  unit="${BASH_REMATCH[3]:-g}"
else
  echo "mongod-entrypoint: invalid MONGO_MEMORY_LIMIT: ${limit}" >&2
  exit 1
fi

mem_mb=$(awk -v n="$num" -v u="$unit" '
BEGIN {
  if (u == "b") mb = n / 1024 / 1024;
  else if (u == "k") mb = n / 1024;
  else if (u == "m") mb = n;
  else mb = n * 1024;
  printf "%.0f", mb
}')

cache_mb=$((mem_mb / 2))
cache_gb=$(awk -v mb="$cache_mb" '
BEGIN {
  g = mb / 1024;
  if (g < 0.25) g = 0.25;
  printf "%g", g
}')

echo "mongod-entrypoint: MONGO_MEMORY_LIMIT=${limit} -> wiredTigerCacheSizeGB=${cache_gb}" >&2

exec docker-entrypoint.sh mongod \
  --bind_ip_all \
  --wiredTigerCacheSizeGB "${cache_gb}" \
  --auth \
  "$@"
