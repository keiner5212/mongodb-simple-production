#!/usr/bin/env bash
set -Eeuo pipefail

unset ALL_PROXY HTTP_PROXY HTTPS_PROXY http_proxy https_proxy all_proxy 2>/dev/null || true

user="${MONGO_INITDB_ROOT_USERNAME:?}"
pass="${MONGO_INITDB_ROOT_PASSWORD:?}"
port="${MONGO_PORT:-27017}"

if [[ "${MONGO_TLS_ENABLED:-false}" == "true" ]]; then
  domain="${MONGO_TLS_DOMAIN:?MONGO_TLS_DOMAIN must match the certificate (e.g. mongo.example.com)}"
  uri="mongodb://127.0.0.1:${port}/?tls=true&authSource=admin&directConnection=true&tlsServerName=${domain}"
else
  uri="mongodb://127.0.0.1:${port}/?authSource=admin&directConnection=true"
fi

exec mongosh "$uri" --quiet -u "$user" -p "$pass" --eval 'db.adminCommand("ping").ok'
