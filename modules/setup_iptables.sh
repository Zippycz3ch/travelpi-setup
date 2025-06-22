#!/bin/bash
set -e
echo "[INFO] Setting up iptables rules..."
iptables -t nat -A POSTROUTING -o wlan1 -j MASQUERADE
iptables -A FORWARD -i wlan1 -o wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i wlan0 -o wlan1 -j ACCEPT
iptables-save > /etc/iptables/rules.v4
