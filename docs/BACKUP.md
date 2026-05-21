# Backups

The `mongo-backup` container runs `mongodump` every 24 hours (default). Files land in:

```text
/var/backups/mongodb/YYYYMMDDTHHMMSSZ/
```

Change schedule in `.env`: `BACKUP_INTERVAL_HOURS`, `BACKUP_MAX_COUNT`.

## Restore on the server

Stop backups, restore, start again:

```bash
cd /opt/mongo/mongodb-simple-production
docker compose stop mongo-backup

# Pick the folder name you want
ls /var/backups/mongodb

# With TLS (after Part B in INSTALACION.md)
mongorestore \
  --host mongo.YOURDOMAIN.com \
  --port 27017 \
  --tls \
  -u admin -p \
  --authenticationDatabase admin \
  --gzip --drop \
  /var/backups/mongodb/20240115T030000Z/

docker compose start mongo-backup
```

Use `--host 127.0.0.1` without `--tls` only if TLS is still disabled.

Enter the admin password when `-p` prompts you.
