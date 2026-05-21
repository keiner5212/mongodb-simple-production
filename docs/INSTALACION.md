# Install MongoDB on your EC2 server

Follow the steps in order. Replace `mongo.YOURDOMAIN.com` with your real hostname everywhere.

---

## Part A — MongoDB running

### 1. Install Docker

See [REQUISITOS.md](REQUISITOS.md) if Docker is not installed yet.

### 2. Clone the project

```bash
sudo mkdir -p /opt/mongo
sudo git clone https://github.com/keiner5212/mongodb-simple-production /opt/mongo/mongodb-simple-production
cd /opt/mongo/mongodb-simple-production
```

### 3. Create data folders

```bash
sudo mkdir -p /var/lib/mongodb/data /var/lib/mongodb/config /var/backups/mongodb /var/lib/mongodb/tls
sudo chown -R "$(id -u)":"$(id -g)" /var/lib/mongodb /var/backups/mongodb
```

### 4. Configure `.env`

```bash
cp .env.example .env
nano .env
```

Change at minimum:

- `MONGO_ROOT_PASSWORD` — long random password
- `MONGO_MEMORY_LIMIT` — see [HARDWARE.md](HARDWARE.md) (example: `3g` on a 4 GB instance)

Leave `MONGO_TLS_ENABLED=false` until Part B.

### 5. Disable Transparent Huge Pages (THP) on the host

MongoDB warns and performs poorly when THP is enabled. On Debian 11/12 (systemd), create a service unit that runs before Docker on every boot:

```bash
sudo tee /etc/systemd/system/disable-thp.service <<'EOF'
[Unit]
Description=Disable Transparent Huge Pages
DefaultDependencies=no
After=sysinit.target local-fs.target
Before=docker.service

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'echo never > /sys/kernel/mm/transparent_hugepage/enabled'
ExecStart=/bin/sh -c 'echo never > /sys/kernel/mm/transparent_hugepage/defrag'
ExecStart=/bin/sh -c 'echo 0 > /sys/kernel/mm/transparent_hugepage/khugepaged/max_ptes_none'

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now disable-thp.service
```

Verify:

```bash
cat /sys/kernel/mm/transparent_hugepage/enabled
# expected: always madvise [never]
```

The container entrypoint will also attempt to set these at startup and will print a warning with the commands above if THP is still enabled.

### 6. Start MongoDB

```bash
sed -i 's/\r$//' scripts/*.sh
chmod +x scripts/*.sh
docker compose up -d --build
docker compose ps
```

Both services should be up; `mongo` should be **healthy**.

Test login:

```bash
docker compose exec mongo mongosh -u admin -p --authenticationDatabase admin --eval 'db.adminCommand({ ping: 1 })'
```

Enter the password from `.env` when prompted.

---

## Part B — Encrypted connections (TLS)

Same idea as MongoDB Atlas: clients add `tls=true` and use your domain (not the EC2 IP). The server only accepts encrypted connections (`requireTLS`).

**Plan a short maintenance window:** when you turn TLS on, every app and Compass user must use the new connection string immediately.

### 7. DNS record

In your domain provider, add:

| Type | Name | Value |
|------|------|--------|
| A | `mongo` | Your EC2 **public** IP (use an Elastic IP so it does not change) |

```bash
dig +short mongo.YOURDOMAIN.com
```

Must return your EC2 public IP.

Security group: allow inbound **TCP 80** and **TCP 27017** (TCP 80 is only needed to get the certificate).

### 8. Get the certificate (on the server)

```bash
cd /opt/mongo/mongodb-simple-production

export MONGO_TLS_DOMAIN=mongo.YOURDOMAIN.com
export MONGO_TLS_LE_EMAIL=you@YOURDOMAIN.com
export MONGO_TLS_DIR=/var/lib/mongodb/tls

sudo -E ./scripts/setup-letsencrypt-tls.sh
```

Mongo stops for about one minute while certbot uses port 80. Your data in `/var/lib/mongodb/data` is not deleted.

Creates `server.pem`, `ca.pem`, and `chown 999:999` on the TLS directory.

### 9. Enable TLS on the server

Edit `.env`:

```env
MONGO_TLS_ENABLED=true
MONGO_TLS_MODE=requireTLS
```

Apply:

```bash
docker compose up -d --build --force-recreate
docker compose logs mongo --tail=15
```

Logs should show `TLS enabled mode=requireTLS`, then `Waiting for connections` with `ssl:on`. MongoDB 8 needs `ca.pem` ([SERVER-72839](https://jira.mongodb.org/browse/SERVER-72839)); the entrypoint also sets `--tlsAllowConnectionsWithoutCertificates` so clients only need `tls=true` (no client certificate).

### 10. Update every client (required)

Old connection (stops working):

```text
mongodb://admin:PASSWORD@13.x.x.x:27017/mydb
```

New connection:

```text
mongodb://admin:PASSWORD@mongo.YOURDOMAIN.com:27017/mydb?tls=true
```

**MongoDB Compass:** paste the new URI.

---

## Part C — After install

### Update the project

```bash
cd /opt/mongo/mongodb-simple-production
git pull
docker compose up -d --force-recreate mongo
```

### View logs

```bash
docker compose logs mongo --tail=30
```

### Backups

Automatic dumps run every 24 hours into `/var/backups/mongodb`. See [BACKUP.md](BACKUP.md).

---

## Common problems

### `invalid option name` when mongo starts

CRLF in scripts:

```bash
sed -i 's/\r$//' scripts/*.sh
docker compose up -d --force-recreate mongo
```

### `mongo` unhealthy but logs show `Waiting for connections`

`mongod` is up; the Docker healthcheck fails. `mongo-backup` waits for `healthy`.

```bash
docker compose exec mongo /bin/bash /usr/local/bin/mongo-healthcheck.sh
echo exit:$?
```

| Log | Fix |
|-----|-----|
| `SERVER-72839` / chain of trust | Run `setup-letsencrypt-tls.sh` (`ca.pem` missing) |
| `Permission denied` on `server.pem` | `sudo chown -R 999:999 /var/lib/mongodb/tls` |
| `only allow SSL connections` | Client needs `tls=true` and the domain hostname |
| `Ingress TLS handshake complete` then `No SSL certificate provided by peer; connection rejected` | `git pull`; entrypoint must pass `--tlsAllowConnectionsWithoutCertificates` |
| `MongoServerSelectionError` from healthcheck | Same as previous row; update scripts and recreate |

```bash
git pull
docker compose up -d --force-recreate mongo
```

### `certificate verify failed` in Compass or an app

The URI host must be `mongo.YOURDOMAIN.com`, not the IP address.

### `connection closed` after enabling TLS

The client is missing `tls=true`, or still using the IP. Use the URI from step 10.

### certbot fails

- DNS A record not pointing to this server yet
- Port 80 blocked in the security group
- Run again: `docker compose stop mongo` then `sudo -E ./scripts/setup-letsencrypt-tls.sh`

### Backup container does not start

Fix `mongo` health first. Backup uses `depends_on: service_healthy`.

---

## Remove everything

```bash
cd /opt/mongo/mongodb-simple-production
docker compose down
sudo rm -rf /var/lib/mongodb /var/backups/mongodb
```

This deletes all databases and backups.
