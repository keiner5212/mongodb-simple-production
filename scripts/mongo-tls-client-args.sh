#!/usr/bin/env bash
# TLS client flags for mongosh/mongodump (public CA / Let's Encrypt).
# SOURCE ONLY — do not execute directly: source /usr/local/bin/mongo-tls-client-args.sh
MONGO_TLS_CLI_ARGS=()

if [[ "${MONGO_TLS_ENABLED:-false}" == "true" ]]; then
  tls_ca="/etc/mongo/tls/ca.pem"
  if [[ ! -f "$tls_ca" ]]; then
    echo "mongo-tls-client-args: missing ${tls_ca}" >&2
    return 1
  fi
  # Internal clients (healthcheck, backup) hit localhost or docker hostname "mongo",
  # not mongo.orga-ai.com — skip hostname check; still verify cert via ca.pem.
  MONGO_TLS_CLI_ARGS=(--tls --tlsCAFile "$tls_ca" --tlsAllowInvalidHostnames)
fi
