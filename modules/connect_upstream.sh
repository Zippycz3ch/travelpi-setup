#!/bin/bash
set -e
echo "[INFO] Connecting to upstream Wi-Fi..."
nmcli device set wlan1 managed yes
nmcli device wifi connect "iot" password "greta691337" ifname wlan1
