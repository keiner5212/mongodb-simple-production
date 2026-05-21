#!/usr/bin/env bash
# WiredTiger cache = 50% of MONGO_MEMORY_LIMIT (same units as compose mem_limit).
set -Eeuo pipefail

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

# Disable Transparent Huge Pages (THP) to avoid MongoDB startup warnings and latency spikes.
# Requires the host to allow writes to sysfs from the container (privileged or custom udev rules).
# If the write fails, the container still starts but a warning is printed with the host-level fix.
_thp_dir="/sys/kernel/mm/transparent_hugepage"
for _thp_path in \
  "${_thp_dir}/enabled" \
  "${_thp_dir}/defrag"; do
  if [[ -w "${_thp_path}" ]]; then
    echo never > "${_thp_path}"
  fi
done
if [[ -f "${_thp_dir}/khugepaged/max_ptes_none" && -w "${_thp_dir}/khugepaged/max_ptes_none" ]]; then
  echo 0 > "${_thp_dir}/khugepaged/max_ptes_none"
fi
if [[ -f "${_thp_dir}/enabled" ]] && grep -qE '\[(always|madvise)\]' "${_thp_dir}/enabled" 2>/dev/null; then
  echo "mongod-entrypoint: WARNING: Transparent Huge Pages still enabled. Disable on the host:" >&2
  echo "  echo never | sudo tee /sys/kernel/mm/transparent_hugepage/enabled" >&2
  echo "  echo never | sudo tee /sys/kernel/mm/transparent_hugepage/defrag" >&2
  echo "  echo 0     | sudo tee /sys/kernel/mm/transparent_hugepage/khugepaged/max_ptes_none" >&2
fi

tls_args=()
if [[ "${MONGO_TLS_ENABLED:-false}" == "true" ]]; then
  tls_pem="/etc/mongo/tls/server.pem"
  tls_ca="/etc/mongo/tls/ca.pem"
  tls_mode="${MONGO_TLS_MODE:-requireTLS}"

  if [[ ! -f "$tls_pem" ]]; then
    echo "mongod-entrypoint: MONGO_TLS_ENABLED=true but missing ${tls_pem}. Run: sudo ./scripts/setup-letsencrypt-tls.sh" >&2
    exit 1
  fi
  if [[ ! -f "$tls_ca" ]]; then
    echo "mongod-entrypoint: MONGO_TLS_ENABLED=true but missing ${tls_ca}. Run: sudo ./scripts/setup-letsencrypt-tls.sh" >&2
    exit 1
  fi

  tls_args+=(--tlsMode "$tls_mode" --tlsCertificateKeyFile "$tls_pem" --tlsCAFile "$tls_ca")
  echo "mongod-entrypoint: TLS enabled mode=${tls_mode}" >&2
fi

mongod_args=(
  --bind_ip_all
  --wiredTigerCacheSizeGB "${cache_gb}"
  --auth
)
if ((${#tls_args[@]} > 0)); then
  mongod_args+=("${tls_args[@]}")
fi

exec docker-entrypoint.sh mongod "${mongod_args[@]}" "$@"
