#!/bin/bash
set -e

HOTSPOT_SSID="travelPi"
HOTSPOT_PASSWORD="heslo123"
HOTSPOT_INTERFACE="wlan0"
UPSTREAM_INTERFACE="wlan1"
STATIC_IP="192.168.50.1"
API_TOKEN="changeme123"

UPSTREAM_SSID="iot"
UPSTREAM_PASSWORD="greta691337"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🔄 Updating system..."
apt update && apt upgrade -y

echo "📦 Installing packages..."
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections
apt install -y hostapd dnsmasq iptables-persistent unbound curl git python3-flask python3-venv network-manager

echo "📶 Configuring hotspot on $HOTSPOT_INTERFACE using NetworkManager..."
nmcli device set $HOTSPOT_INTERFACE managed yes
nmcli connection delete travelpi-hotspot 2>/dev/null || true

nmcli connection add type wifi ifname $HOTSPOT_INTERFACE con-name travelpi-hotspot ssid "$HOTSPOT_SSID" \
    wifi.mode ap 802-11-wireless.band bg 802-11-wireless.channel 7

nmcli connection modify travelpi-hotspot ipv4.method manual ipv4.addresses "$STATIC_IP/24"
nmcli connection modify travelpi-hotspot ipv4.gateway "$STATIC_IP"
nmcli connection modify travelpi-hotspot ipv4.dns "$STATIC_IP"

# ✅ Add key management and password after defining the base connection
nmcli connection modify travelpi-hotspot wifi-sec.key-mgmt wpa-psk
nmcli connection modify travelpi-hotspot wifi-sec.psk "$HOTSPOT_PASSWORD"

nmcli connection modify travelpi-hotspot connection.autoconnect yes


echo "📡 Connecting to upstream Wi-Fi on $UPSTREAM_INTERFACE..."
nmcli device set $UPSTREAM_INTERFACE managed yes
nmcli device wifi connect "$UPSTREAM_SSID" password "$UPSTREAM_PASSWORD" ifname $UPSTREAM_INTERFACE
nmcli connection modify "$UPSTREAM_SSID" connection.autoconnect yes

echo "📄 Configuring hostapd..."
cp "$SCRIPT_DIR/hostapd.conf" /etc/hostapd/hostapd.conf
sed -i "s|#DAEMON_CONF=.*|DAEMON_CONF=\"/etc/hostapd/hostapd.conf\"|" /etc/default/hostapd
systemctl unmask hostapd
systemctl enable hostapd

echo "📄 Configuring dnsmasq..."
[ -f /etc/dnsmasq.conf ] && mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig
cp "$SCRIPT_DIR/dnsmasq.conf" /etc/dnsmasq.conf
systemctl enable dnsmasq
systemctl restart dnsmasq

echo "🔐 Installing and configuring Unbound..."
ROOT_HINTS="/var/lib/unbound/root.hints"
curl -o $ROOT_HINTS https://www.internic.net/domain/named.cache

mkdir -p /etc/unbound/unbound.conf.d
cp "$SCRIPT_DIR/pi-hole.conf" /etc/unbound/unbound.conf.d/pi-hole.conf
systemctl enable unbound
systemctl restart unbound

echo "🌍 Enabling IPv4 forwarding..."
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sysctl -p

echo "🧱 Setting up iptables for NAT..."
iptables -t nat -A POSTROUTING -o $UPSTREAM_INTERFACE -j MASQUERADE
iptables -A FORWARD -i $UPSTREAM_INTERFACE -o $HOTSPOT_INTERFACE -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i $HOTSPOT_INTERFACE -o $UPSTREAM_INTERFACE -j ACCEPT
iptables-save > /etc/iptables/rules.v4

echo "🧠 Installing Flask Wi-Fi control API..."
mkdir -p /opt/travelpi-api
cp -r "$SCRIPT_DIR/flask/"* /opt/travelpi-api/
cd /opt/travelpi-api
python3 -m venv venv
venv/bin/pip install -r requirements.txt

echo "🔧 Installing systemd service for API..."
cp "$SCRIPT_DIR/travelpi-api.service" /etc/systemd/system/
systemctl enable travelpi-api.service
systemctl start travelpi-api.service

echo "📦 Installing Pi-hole non-interactively..."
mkdir -p /etc/pihole
cp "$SCRIPT_DIR/setupVars.conf" /etc/pihole/setupVars.conf
curl -sSL https://install.pi-hole.net | bash /dev/stdin --unattended

echo "🔧 Configuring Pi-hole to use Unbound..."
pihole -a setdns 127.0.0.1#5335
systemctl restart pihole-FTL

echo "✅ Setup complete! System will reboot in 10 seconds..."
sleep 10
reboot
