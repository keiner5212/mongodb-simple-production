# Installation Guide

## 1. Transfer & Navigate

```bash
# Option A: git clone
git clone https://github.com/keiner5212/mongodb-simple-production /opt/mongodb/
cd /opt/mongodb

# Option B: scp
scp -r /path/to/mongodb-simple-production/* user@ec2:/opt/mongodb/
cd /opt/mongodb
```

## 2. Configure

```bash
cp .env.example .env
nano .env
```

Key variables:
- `MONGO_ROOT_PASSWORD` — **required**, set strong password
- `MONGO_ROOT_USERNAME` — default `admin`
- `COMPOSE_PROJECT_NAME` — default `mongodb-prod`
- `MONGO_DATA_DIR` — default `/var/lib/mongodb/data`
- `BACKUP_HOST_DIR` — default `/var/backups/mongodb`

## 3. Deploy

```bash
docker compose up -d
docker compose ps
```

## 4. Verify

```bash
docker compose logs mongo --tail=20
```

## Uninstall

```bash
docker compose down -v
rm -rf /var/lib/mongodb /var/backups/mongodb
```