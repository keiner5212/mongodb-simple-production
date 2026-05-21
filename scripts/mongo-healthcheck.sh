#!/usr/bin/env bash
set -Eeuo pipefail

user="${MONGO_INITDB_ROOT_USERNAME:?}"
pass="${MONGO_INITDB_ROOT_PASSWORD:?}"

# shellcheck source=/dev/null
source /usr/local/bin/mongo-tls-client-args.sh

args=(
  --quiet
  -u "$user"
  -p "$pass"
  --authenticationDatabase admin
)

if ((${#MONGO_TLS_CLI_ARGS[@]} > 0)); then
  args+=("${MONGO_TLS_CLI_ARGS[@]}")
fi

exec mongosh "${args[@]}" --eval "db.adminCommand('ping').ok"
