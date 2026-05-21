# Hardware

This stack runs one MongoDB container on a single EC2 instance.

## Pick an instance

| Your case | EC2 type | RAM | Set in `.env` |
|-----------|----------|-----|----------------|
| First deploy / light use | t3.medium | 4 GB | `MONGO_MEMORY_LIMIT=3g` |
| More data or traffic | t3.large | 8 GB | `MONGO_MEMORY_LIMIT=7g` |

`MONGO_MEMORY_LIMIT` is the RAM cap for the mongo container. WiredTiger cache is half of that (set automatically).

Example: `MONGO_MEMORY_LIMIT=3g` → about 1.5 GB cache. You will see it in the logs:

```text
mongod-entrypoint: MONGO_MEMORY_LIMIT=3g -> wiredTigerCacheSizeGB=1.5
```

Leave about 1 GB RAM for Debian, Docker, and the backup container.

## Disk

| Path | What |
|------|------|
| `/var/lib/mongodb/data` | Database files — size your data + ~30% |
| `/var/backups/mongodb` | mongodump copies — keep ~2× your largest backup |

Use gp3 EBS volumes on AWS.

## Network

Security group inbound:

- **22** — your IP (SSH)
- **27017** — MongoDB (world or `0.0.0.0/0` if everyone uses TLS + strong password)
- **80** — only when running `setup-letsencrypt-tls.sh` (can remove later)

Use an **Elastic IP** so your DNS record and certificate stay valid after a reboot.
