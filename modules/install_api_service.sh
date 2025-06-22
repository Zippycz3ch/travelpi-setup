#!/bin/bash
set -e
echo "[INFO] Installing TravelPi API..."
mkdir -p /opt/travelpi-api
cp -r "$(dirname "$0")/../flask/"* /opt/travelpi-api/
cd /opt/travelpi-api
python3 -m venv venv
./venv/bin/pip install -r requirements.txt
cp "$(dirname "$0")/../travelpi-api.service" /etc/systemd/system/
systemctl enable travelpi-api.service
systemctl restart travelpi-api.service
