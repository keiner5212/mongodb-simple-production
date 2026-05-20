# MongoDB Simple Production

Single-node MongoDB 7.0 deployment on Debian EC2 with Docker Compose.

## Stack

- **mongo**: MongoDB 7.0 container with host bind-mounted volumes
- **mongo-backup**: Automated mongodump service (24h interval, 14-day retention)

## Security

- MongoDB binds to all interfaces (`0.0.0.0:27017`)
- Secure with firewall or cloud security group

## Volumes

| Host path | Container path | Purpose |
|---|---|---|
| `/var/lib/mongodb/data` | `/data/db` | Database files |
| `/var/lib/mongodb/config` | `/data/configdb` | Config data |
| `/var/backups/mongodb` | `/backup` | Backup output |

## Quick Start

```bash
cp .env.example .env
# Edit .env with strong passwords

docker compose up -d
docker compose ps
```

## Backup Location

Backups stored at `BACKUP_HOST_DIR` (default: `/var/backups/mongodb`)
Format: `YYYYMMDDTHHMMSSZ/` directories containing gzip compressed BSON files.
