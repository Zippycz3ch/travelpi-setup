#!/bin/bash
set -e
echo "[INFO] Configuring Pi-hole upstream DNS to Unbound..."
pihole -a setdns 127.0.0.1#5335
systemctl restart pihole-FTL
