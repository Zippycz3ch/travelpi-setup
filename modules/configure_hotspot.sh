#!/bin/bash
set -e
echo "[INFO] Configuring Wi-Fi hotspot..."
nmcli device set wlan0 managed yes
nmcli connection delete "travelpi-hotspot" 2>/dev/null || true
nmcli connection add type wifi ifname wlan0 con-name "travelpi-hotspot" ssid "travelPi"     wifi.mode ap 802-11-wireless.band bg 802-11-wireless.channel 7
nmcli connection modify "travelpi-hotspot" ipv4.method manual ipv4.addresses 192.168.50.1/24     ipv4.gateway 192.168.50.1 ipv4.dns 192.168.50.1
nmcli connection modify "travelpi-hotspot" wifi-sec.key-mgmt wpa-psk wifi-sec.psk "heslo123"
nmcli connection modify "travelpi-hotspot" connection.autoconnect yes
nmcli connection up "travelpi-hotspot"
