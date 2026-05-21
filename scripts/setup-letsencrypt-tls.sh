#!/usr/bin/env bash
# Let's Encrypt certificate for MongoDB (same idea as Atlas: clients only add tls=true).
# Requires: DNS A record for MONGO_TLS_DOMAIN pointing to this EC2 public IP.
set -Eeuo pipefail

domain="${MONGO_TLS_DOMAIN:?Set MONGO_TLS_DOMAIN (e.g. mongo.example.com)}"
email="${MONGO_TLS_LE_EMAIL:?Set MONGO_TLS_LE_EMAIL}"
tls_dir="${MONGO_TLS_DIR:-/var/lib/mongodb/tls}"
project_dir="${MONGO_TLS_PROJECT_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"

if [[ $EUID -ne 0 ]]; then
  echo "Run with: sudo -E ./scripts/setup-letsencrypt-tls.sh" >&2
  exit 1
fi

if ! command -v certbot >/dev/null 2>&1; then
  apt-get update
  apt-get install -y certbot
fi

mkdir -p "$tls_dir"
chmod 700 "$tls_dir"

echo "Stopping mongo (certbot needs port 80)..."
cd "$project_dir"
docker compose stop mongo

# Restart mongo on any failure after this point so the service is not left stopped.
trap 'echo "setup-letsencrypt-tls: error — restarting mongo" >&2; docker compose start mongo || true' ERR

certbot certonly --standalone --non-interactive --agree-tos \
  --email "$email" \
  -d "$domain"

live="/etc/letsencrypt/live/${domain}"
if [[ ! -f "${live}/fullchain.pem" || ! -f "${live}/privkey.pem" ]]; then
  echo "Certbot failed. Check DNS: ${domain} must point to this server's public IP." >&2
  exit 1
fi

umask 077
cat "${live}/fullchain.pem" "${live}/privkey.pem" >"${tls_dir}/server.pem"
chmod 600 "${tls_dir}/server.pem"
cp "${live}/chain.pem" "${tls_dir}/ca.pem"
chmod 644 "${tls_dir}/ca.pem"
chown -R 999:999 "${tls_dir}"

trap - ERR

echo "OK: ${tls_dir}/server.pem"
echo "OK: ${tls_dir}/ca.pem"
echo "Next in .env: MONGO_TLS_ENABLED=true, MONGO_TLS_MODE=requireTLS, MONGO_TLS_DOMAIN=${domain}"
echo "Then: docker compose up -d --force-recreate mongo"
echo "Every client must use: mongodb://USER:PASS@${domain}:27017/DB?tls=true"
echo "Enable TLS only after all clients are ready to switch."

docker compose start mongo

hook="/etc/letsencrypt/renewal-hooks/deploy/mongodb-tls.sh"
install -d "$(dirname "$hook")"
cat >"$hook" <<EOF
#!/usr/bin/env bash
set -Eeuo pipefail
umask 077
cat "${live}/fullchain.pem" "${live}/privkey.pem" >"${tls_dir}/server.pem"
chmod 600 "${tls_dir}/server.pem"
cp "${live}/chain.pem" "${tls_dir}/ca.pem"
chmod 644 "${tls_dir}/ca.pem"
chown -R 999:999 "${tls_dir}"
cd "${project_dir}"
docker compose restart mongo
EOF
chmod +x "$hook"
