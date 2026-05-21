#!/usr/bin/env bash
# SOURCE ONLY
MONGO_TLS_CLI_ARGS=()

if [[ "${MONGO_TLS_ENABLED:-false}" == "true" ]]; then
  MONGO_TLS_CLI_ARGS=(--tls --directConnection)
fi
