#!/bin/bash
set -e
echo "[INFO] Configuring Unbound..."
curl -o /var/lib/unbound/root.hints https://www.internic.net/domain/named.cache
mkdir -p /etc/unbound/unbound.conf.d
cp "$(dirname "$0")/../pi-hole.conf" /etc/unbound/unbound.conf.d/pi-hole.conf
systemctl enable unbound
systemctl restart unbound
