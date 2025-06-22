#!/bin/bash
set -e
echo "[INFO] Configuring dnsmasq..."
cp "$(dirname "$0")/../dnsmasq.conf" /etc/dnsmasq.conf
systemctl enable dnsmasq
systemctl restart dnsmasq
