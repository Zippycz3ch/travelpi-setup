#!/bin/bash
set -e
echo "[INFO] Configuring hostapd..."
cp "$(dirname "$0")/../hostapd.conf" /etc/hostapd/hostapd.conf
sed -i 's|^#*DAEMON_CONF=.*|DAEMON_CONF="/etc/hostapd/hostapd.conf"|' /etc/default/hostapd
systemctl unmask hostapd
systemctl enable hostapd
systemctl restart hostapd
