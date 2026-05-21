#!/usr/bin/env bash
# TLS client flags for mongosh/mongodump (public CA / Let's Encrypt).
# SOURCE ONLY — do not execute directly: source /usr/local/bin/mongo-tls-client-args.sh
MONGO_TLS_CLI_ARGS=()

if [[ "${MONGO_TLS_ENABLED:-false}" == "true" ]] || [[ -f /etc/mongo/tls/server.pem ]]; then
  MONGO_TLS_CLI_ARGS=(--tls --tlsAllowInvalidHostnames --directConnection)
fi
