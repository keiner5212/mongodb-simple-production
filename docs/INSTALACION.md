# Installation Guide

## 1. Transfer & Navigate

```bash
git clone https://github.com/keiner5212/mongodb-simple-production /opt/mongo/mongodb-simple-production
cd /opt/mongo/mongodb-simple-production
```

Create host data directories before first deploy:

```bash
sudo mkdir -p /var/lib/mongodb/data /var/lib/mongodb/config /var/backups/mongodb
sudo chown -R "$(id -u)":"$(id -g)" /var/lib/mongodb /var/backups/mongodb
```

## 2. Configure

```bash
cp .env.example .env
nano .env
```

| Variable | Purpose |
|----------|---------|
| `MONGO_ROOT_PASSWORD` | **Required.** Strong admin password |
| `MONGO_ROOT_USERNAME` | Admin user (default `admin`) |
| `COMPOSE_PROJECT_NAME` | Stack name prefix (default `mongodb-prod`) |
| `MONGO_DATA_DIR` | Host path → `/data/db` |
| `MONGO_CONFIG_DIR` | Host path → `/data/configdb` |
| `BACKUP_HOST_DIR` | Host path for mongodump archives |
| `MONGO_MEMORY_LIMIT` | Container RAM cap (`6g`, `2g`, `512m`, …) |

### WiredTiger cache (automatic)

`scripts/mongod-entrypoint.sh` runs before the official MongoDB image entrypoint. It reads `MONGO_MEMORY_LIMIT` from `.env` (same value as `mem_limit` in `docker-compose.yml`) and starts `mongod` with:

- `--wiredTigerCacheSizeGB` = **50%** of that limit  
- `--bind_ip_all`  
- `--auth`

Examples:

| `MONGO_MEMORY_LIMIT` | Cache (`wiredTigerCacheSizeGB`) |
|----------------------|----------------------------------|
| `6g` | `3` |
| `2g` | `1` |
| `512m` | `0.25` (minimum) |

On successful start, logs must show:

```text
mongod-entrypoint: MONGO_MEMORY_LIMIT=6g -> wiredTigerCacheSizeGB=3
```

Change only `MONGO_MEMORY_LIMIT` in `.env`, then recreate the mongo container (section 4).

## 3. Deploy

```bash
docker compose up -d --build
docker compose ps
```

## 4. Verify

```bash
docker compose logs mongo --tail=30
docker compose exec mongo mongosh -u "$MONGO_ROOT_USERNAME" -p "$MONGO_ROOT_PASSWORD" --authenticationDatabase admin --eval 'db.adminCommand({ ping: 1 })'
```

Expected: mongo service **healthy**, backup service **running** (depends on healthy mongo).

## 5. Troubleshooting

### `mongod-custom-entrypoint.sh: lin: invalid option name` (exit code 2)

**Cause:** `scripts/mongod-entrypoint.sh` has Windows CRLF line endings (`\r\n`). Linux bash misreads `set -o pipefail` and fails at startup.

**Fix on EC2:**

```bash
sed -i 's/\r$//' scripts/mongod-entrypoint.sh
file scripts/mongod-entrypoint.sh   # should NOT say "CRLF"
docker compose up -d --force-recreate mongo
```

Or: `dos2unix scripts/mongod-entrypoint.sh` if `dos2unix` is installed.

**Prevent:** deploy with `git clone` / `git pull` on the server (not manual copy). Repo enforces LF on `*.sh` via `.gitattributes` and `.editorconfig`.

**Check for CRLF:**

```bash
cat -A scripts/mongod-entrypoint.sh | head -5
```

`^M` at line ends = CRLF → run `sed` above.

### `unexpected "js-yaml.js" output while parsing config: null`

Removed in current stack: mongo no longer mounts `config/mongod.conf`. Pull latest `docker-compose.yml` and recreate.

### `dependency failed to start: container mongodb-prod-mongo is unhealthy`

1. Fix mongo startup first (`docker compose logs mongo`).
2. Backup service waits for healthy mongo — it will start after mongo is OK.

### Healthcheck / auth errors

Confirm `.env` has `MONGO_ROOT_USERNAME` and `MONGO_ROOT_PASSWORD` set. Recreate after changing password on existing data dir may require manual user fix — on **first** deploy only init creates the root user.

## 6. Apply changes on running EC2

```bash
git pull
# edit .env if MONGO_MEMORY_LIMIT or passwords changed
docker compose up -d --force-recreate mongo
docker compose ps
docker compose logs mongo --tail=10
```

## 7. Uninstall

```bash
docker compose down
sudo rm -rf /var/lib/mongodb /var/backups/mongodb
```

Use `docker compose down -v` only if you use named volumes (this stack uses host bind mounts; remove paths manually as above).
