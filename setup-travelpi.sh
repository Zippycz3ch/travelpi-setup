#!/bin/bash
set -e

HOTSPOT_SSID="travelPi"
HOTSPOT_PASSWORD="heslo123"
HOTSPOT_INTERFACE="wlan1"
UPSTREAM_INTERFACE="wlan0"
STATIC_IP="192.168.50.1"
API_TOKEN="changeme123"

echo "🔄 Updating system..."
apt update && apt upgrade -y

echo "📦 Installing packages..."
apt install -y hostapd dnsmasq iptables-persistent unbound curl git python3-flask python3-venv

echo "📡 Configuring wlan1 static IP..."
grep -q "$HOTSPOT_INTERFACE" /etc/dhcpcd.conf || cat >> /etc/dhcpcd.conf <<EOF

interface $HOTSPOT_INTERFACE
    static ip_address=${STATIC_IP}/24
    nohook wpa_supplicant
EOF
systemctl restart dhcpcd

echo "📶 Configuring hostapd..."
cp hostapd.conf /etc/hostapd/hostapd.conf
sed -i "s|#DAEMON_CONF=.*|DAEMON_CONF="/etc/hostapd/hostapd.conf"|" /etc/default/hostapd
systemctl unmask hostapd
systemctl enable hostapd

echo "🌐 Configuring dnsmasq..."
[ -f /etc/dnsmasq.conf ] && mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig
cp dnsmasq.conf /etc/dnsmasq.conf
systemctl restart dnsmasq

echo "🧠 Installing and configuring Unbound..."
ROOT_HINTS="/var/lib/unbound/root.hints"
curl -o $ROOT_HINTS https://www.internic.net/domain/named.cache

mkdir -p /etc/unbound/unbound.conf.d
cat > /etc/unbound/unbound.conf.d/pi-hole.conf <<EOF
server:
    verbosity: 0
    interface: 127.0.0.1
    port: 5335
    do-ip4: yes
    do-udp: yes
    do-tcp: yes
    root-hints: "$ROOT_HINTS"
    harden-glue: yes
    harden-dnssec-stripped: yes
    use-caps-for-id: yes
    edns-buffer-size: 1232
    prefetch: yes
    num-threads: 1
    so-rcvbuf: 1m
    so-sndbuf: 1m
    cache-min-ttl: 3600
    cache-max-ttl: 86400
    hide-identity: yes
    hide-version: yes
    qname-minimisation: yes
    rrset-roundrobin: yes
EOF

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
cp -r flask/* /opt/travelpi-api/
cd /opt/travelpi-api
python3 -m venv venv
venv/bin/pip install -r requirements.txt

echo "🔧 Installing systemd service..."
cp ../travelpi-api.service /etc/systemd/system/
systemctl enable travelpi-api.service

echo "✅ Setup complete! Reboot to start hotspot and API."
