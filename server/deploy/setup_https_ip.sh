#!/usr/bin/env bash
set -euo pipefail

# Хватайка 2.0.0 — HTTPS setup for the current public VDS IP.
# Requires root, DNS is NOT required for an IP certificate.
# Let's Encrypt IP certificates are short-lived, so renewal must be automated.

PUBLIC_IP="${PUBLIC_IP:-135.106.209.40}"
EMAIL="${EMAIL:-}"

if [[ "$(id -u)" != "0" ]]; then
  echo "Run as root: sudo $0"
  exit 1
fi
if [[ -z "$EMAIL" ]]; then
  echo "Usage: EMAIL=you@example.com sudo -E $0"
  exit 1
fi

apt-get update
apt-get install -y certbot caddy

systemctl stop caddy || true
certbot certonly --standalone \
  --non-interactive --agree-tos \
  --email "$EMAIL" \
  --preferred-profile shortlived \
  --ip-address "$PUBLIC_IP"

install -d -m 0755 /etc/caddy
cp "$(dirname "$0")/Caddyfile.ip.example" /etc/caddy/Caddyfile
sed -i "s/135\.106\.209\.40/${PUBLIC_IP}/g" /etc/caddy/Caddyfile

# Ensure the Node backend is local-only when running directly under systemd/PM2.
cat >/etc/default/khvataika <<ENV
HOST=127.0.0.1
PORT=8080
ENV

systemctl enable caddy
systemctl restart caddy

# Renew every day; the IP certificate is intentionally short-lived.
cat >/etc/cron.d/khvataika-cert-renew <<CRON
17 3 * * * root certbot renew --quiet --deploy-hook 'systemctl reload caddy' >>/var/log/khvataika-cert-renew.log 2>&1
CRON
chmod 0644 /etc/cron.d/khvataika-cert-renew

echo "HTTPS is configured for https://${PUBLIC_IP}"
echo "Check: curl -fsS https://${PUBLIC_IP}/health"
