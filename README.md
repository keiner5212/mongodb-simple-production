# MongoDB Simple Production

Single-node MongoDB 7.0 deployment on Debian EC2 with Docker Compose.

## Stack

- **mongo**: MongoDB 7.0; WiredTiger cache auto = 50% of `MONGO_MEMORY_LIMIT` via `scripts/mongod-entrypoint.sh`
- **mongo-backup**: Automated mongodump service (24h interval)

## Docs

- [Installation & troubleshooting](docs/INSTALACION.md) — deploy, env vars, common errors
- [Hardware sizing](docs/HARDWARE.md)
- [Backups](docs/BACKUP.md)
