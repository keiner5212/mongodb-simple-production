#!/usr/bin/env bash
set -Eeuo pipefail

: "${MONGO_HOST:=mongo}"
: "${MONGO_PORT:=27017}"
: "${MONGO_ROOT_USERNAME:?MONGO_ROOT_USERNAME is required}"
: "${MONGO_ROOT_PASSWORD:?MONGO_ROOT_PASSWORD is required}"
: "${BACKUP_PATH:=/backup}"
: "${BACKUP_INTERVAL_HOURS:=24}"
: "${BACKUP_MAX_COUNT:=14}"
: "${MONGO_TLS_ENABLED:=false}"

unset ALL_PROXY HTTP_PROXY HTTPS_PROXY http_proxy https_proxy all_proxy 2>/dev/null || true

log() {
  printf '[%s] %s\n' "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" "$*"
}

if ! [[ "${BACKUP_INTERVAL_HOURS}" =~ ^[0-9]+$ ]] || (( BACKUP_INTERVAL_HOURS < 1 )); then
  log "ERROR: BACKUP_INTERVAL_HOURS must be a positive integer"
  exit 1
fi

if ! [[ "${BACKUP_MAX_COUNT}" =~ ^[0-9]+$ ]] || (( BACKUP_MAX_COUNT < 1 )); then
  log "ERROR: BACKUP_MAX_COUNT must be a positive integer"
  exit 1
fi

interval_seconds=$(( BACKUP_INTERVAL_HOURS * 3600 ))

# Same URI as external clients (?tls=true). Credentials via -u/-p (no python in backup image).
mongo_uri() {
  local host params

  if [[ "${MONGO_TLS_ENABLED:-false}" == "true" ]]; then
    if [[ -z "${MONGO_TLS_DOMAIN:-}" ]]; then
      log "ERROR: MONGO_TLS_DOMAIN is required in .env when MONGO_TLS_ENABLED=true"
      return 1
    fi
    host="${MONGO_TLS_DOMAIN}"
    params="tls=true&authSource=admin&directConnection=true"
  else
    host="${MONGO_HOST:-mongo}"
    params="authSource=admin&directConnection=true"
  fi

  printf 'mongodb://%s:%s/?%s' "${host}" "${MONGO_PORT}" "${params}"
}

wait_for_mongo() {
  local retries=30
  local delay=5
  local i
  local uri

  uri="$(mongo_uri)" || return 1

  for (( i = 1; i <= retries; i++ )); do
    if mongosh "${uri}" --quiet \
      -u "${MONGO_ROOT_USERNAME}" \
      -p "${MONGO_ROOT_PASSWORD}" \
      --eval "db.adminCommand('ping').ok" >/dev/null 2>&1; then
      if [[ "${MONGO_TLS_ENABLED:-false}" == "true" ]]; then
        log "MongoDB reachable at ${MONGO_TLS_DOMAIN}:${MONGO_PORT} (external-style TLS)"
      else
        log "MongoDB reachable at ${MONGO_HOST}:${MONGO_PORT}"
      fi
      return 0
    fi
    log "Waiting for MongoDB (${i}/${retries})..."
    sleep "${delay}"
  done

  log "ERROR: MongoDB not reachable after ${retries} attempts"
  return 1
}

run_backup() {
  local stamp
  local dest
  local uri

  stamp="$(date -u +'%Y%m%dT%H%M%SZ')"
  dest="${BACKUP_PATH}/${stamp}"
  uri="$(mongo_uri)" || return 1

  mkdir -p "${dest}"

  log "Starting backup -> ${dest}"
  mongodump --uri="${uri}" \
    -u "${MONGO_ROOT_USERNAME}" \
    -p "${MONGO_ROOT_PASSWORD}" \
    --gzip --out "${dest}"

  log "Backup finished: ${dest}"
}

prune_old_backups() {
  local count
  local to_remove
  local i
  local old

  mapfile -t backups < <(find "${BACKUP_PATH}" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null | sort)
  count="${#backups[@]}"

  if (( count <= BACKUP_MAX_COUNT )); then
    log "Retention OK: ${count}/${BACKUP_MAX_COUNT} backups"
    return 0
  fi

  to_remove=$(( count - BACKUP_MAX_COUNT ))
  log "Pruning ${to_remove} old backup(s), keeping ${BACKUP_MAX_COUNT}"

  for (( i = 0; i < to_remove; i++ )); do
    old="${BACKUP_PATH}/${backups[$i]}"
    log "Removing ${old}"
    rm -rf "${old}"
  done
}

mkdir -p "${BACKUP_PATH}"
wait_for_mongo

log "Backup scheduler: every ${BACKUP_INTERVAL_HOURS}h, max ${BACKUP_MAX_COUNT} backups at ${BACKUP_PATH}"

while true; do
  if run_backup; then
    prune_old_backups
  else
    log "ERROR: backup run failed"
  fi
  log "Next backup in ${BACKUP_INTERVAL_HOURS} hour(s)"
  sleep "${interval_seconds}"
done
