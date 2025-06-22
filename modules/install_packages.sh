#!/bin/bash
set -e
echo "[INFO] Installing required packages..."
apt-get install -y hostapd dnsmasq iptables-persistent unbound curl git python3-flask python3-venv network-manager
