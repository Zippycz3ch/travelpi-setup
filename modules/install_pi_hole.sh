#!/bin/bash
set -e
echo "[INFO] Installing Pi-hole..."
cp "$(dirname "$0")/../setupVars.conf" /etc/pihole/setupVars.conf
curl -sSL https://install.pi-hole.net | bash /dev/stdin --unattended
