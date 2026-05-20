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
- `MONGO_MEMORY_LIMIT` — container RAM cap; set matching `cacheSizeGB` in `config/mongod.conf` (~50%)

## 3. Deploy

```bash
docker compose up -d
docker compose ps
```

## 4. Verify

```bash
docker compose logs mongo --tail=20
```

## Apply config on running EC2

Pull or copy updated project files. Edit `config/mongod.conf` (`cacheSizeGB` vs `MONGO_MEMORY_LIMIT`), then:

Recreate mongo (short downtime; data volumes unchanged):

```bash
docker compose up -d mongo
docker compose ps
```

## Uninstall

```bash
docker compose down -v
rm -rf /var/lib/mongodb /var/backups/mongodb
```