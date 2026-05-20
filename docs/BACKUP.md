# Backup & Restore

## Variables

| Variable | Default | Description |
|---|---|---|
| `MONGO_HOST` | `mongo` (container name) | Use EC2 public DNS/IP for remote restore |
| `MONGO_PORT` | `27017` | MongoDB port |
| `MONGO_ROOT_USERNAME` | `admin` | From `.env` |
| `MONGO_ROOT_PASSWORD` | - | From `.env` |
| `BACKUP_HOST_DIR` | `/var/backups/mongodb` | Backup directory on host |

## Restore

Stop backup service, then restore:

```bash
docker compose stop mongo-backup

# Local restore (from EC2)
mongorestore --host=127.0.0.1 --port=27017 -u=admin -p --authenticationDatabase=admin --gzip --drop /var/backups/mongodb/YYYYMMDDTHHMMSSZ/

# Remote restore (from your machine)
mongorestore --host=[EC2_PUBLIC_DNS] --port=27017 -u=admin -p --authenticationDatabase=admin --gzip --drop /var/backups/mongodb/YYYYMMDDTHHMMSSZ/

docker compose start mongo-backup
```

Enter password interactively when prompted with `-p`.

## Backup Directory

Format: `YYYYMMDDTHHMMSSZ/` (e.g., `20240115T030000Z/`)
Location: `BACKUP_HOST_DIR` (default: `/var/backups/mongodb`)