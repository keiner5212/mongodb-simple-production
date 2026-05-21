#!/usr/bin/env bash
set -Eeuo pipefail

unset ALL_PROXY HTTP_PROXY HTTPS_PROXY http_proxy https_proxy all_proxy 2>/dev/null || true

user="${MONGO_INITDB_ROOT_USERNAME:?}"
pass="${MONGO_INITDB_ROOT_PASSWORD:?}"

urlencode() {
  python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1], safe=""))' "$1"
}

params="authSource=admin&directConnection=true"
if [[ "${MONGO_TLS_ENABLED:-false}" == "true" ]] || [[ -f /etc/mongo/tls/server.pem ]]; then
  params="${params}&tls=true&tlsAllowInvalidHostnames=true&tlsAllowInvalidCertificates=true"
fi

uri="mongodb://$(urlencode "$user"):$(urlencode "$pass")@127.0.0.1:27017/?${params}"

exec mongosh "$uri" --quiet --eval "db.adminCommand('ping').ok"
