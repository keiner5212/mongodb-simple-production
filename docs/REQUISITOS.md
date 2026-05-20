# Server Requirements (Debian)

## OS

Debian 11 (Bullseye) or Debian 12 (Bookworm)

## Packages

```bash
apt-get update
apt-get install -y docker.io docker-compose-v2 || apt-get install -y docker.io docker-compose
```

## Docker

- Docker Engine 20.10+
- Docker Compose plugin (v2) or standalone docker-compose

Verify:
```bash
docker --version
docker compose version  # or docker-compose version
```

## Directory Structure (create before deploy)

```bash
mkdir -p /var/lib/mongodb/data
mkdir -p /var/lib/mongodb/config
mkdir -p /var/backups/mongodb
```
