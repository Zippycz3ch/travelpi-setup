#!/bin/bash
set -e
echo "[INFO] Updating system packages..."
apt-get update && apt-get upgrade -y
