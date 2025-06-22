#!/bin/bash
set -e
echo "[INFO] Enabling IPv4 forwarding..."
sed -i 's/^#* *net.ipv4.ip_forward=.*/net.ipv4.ip_forward=1/' /etc/sysctl.conf || echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p /etc/sysctl.conf
