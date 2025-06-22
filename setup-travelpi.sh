#!/bin/bash
set -e

HOTSPOT_SSID="travelPi"
HOTSPOT_PASSWORD="heslo123"
HOTSPOT_INTERFACE="wlan0"
UPSTREAM_INTERFACE="wlan1"
STATIC_IP="192.168.50.1"
API_TOKEN="changeme123"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🔄 Updating system..."
apt update && apt upgrade -y

echo "📦 Installing packages..."
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections
apt install -y hostapd dnsmasq iptables-persistent unbound curl git python3-flask python3-venv

echo "📶 Configuring hotspot on $HOTSPOT_INTERFACE using NetworkManager..."
nmcli device set $HOTSPOT_INTERFACE managed yes
nmcli connection add type wifi ifname $HOTSPOT_INTERFACE con-name travelpi-hotspot \
    autoconnect yes ssid "$HOTSPOT_SSID"
nmcli connection modify travelpi-hotspot ipv4.method manual ipv4.addresses "$STATIC_IP/24"
nmcli connection modify travelpi-hotspot ipv4.gateway "$STATIC_IP"
nmcli connection modify travelpi-hotspot ipv4.dns "$STATIC_IP"
nmcli connection modify travelpi-hotspot 802-11-wireless.mode ap 802-11-wireless.band bg \
    802-11-wireless.channel 7
nmcli connection modify travelpi-hotspot wifi-sec.key-mgmt wpa-psk
nmcli connection modify travelpi-hotspot wifi-sec.psk "$HOTSPOT_PASSWORD"
nmcli connection modify travelpi-hotspot connection.autoconnect yes

echo "📄 Configuring hostapd..."
cp "$SCRIPT_DIR/hostapd.conf" /etc/hostapd/hostapd.conf
sed -i "s|#DAEMON_CONF=.*|DAEMON_CONF=\"/etc/hostapd/hostapd.conf\"|" /etc/default/hostapd
systemctl unmask hostapd
systemctl enable hostapd

echo "📄 Configuring dnsmasq..."
[ -f /etc/dnsmasq.conf ] && mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig
cp "$SCRIPT_DIR/dnsmasq.conf" /etc/dnsmasq.conf
systemctl restart dnsmasq

echo "🔐 Installing and configuring Unbound..."
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
cp -r "$SCRIPT_DIR/flask/"* /opt/travelpi-api/
cd /opt/travelpi-api
python3 -m venv venv
venv/bin/pip install -r requirements.txt

echo "🔧 Installing systemd service for API..."
cp "$SCRIPT_DIR/travelpi-api.service" /etc/systemd/system/
systemctl enable travelpi-api.service

echo "📦 Installing Pi-hole non-interactively..."
curl -sSL https://install.pi-hole.net | bash /dev/stdin --unattended

echo "🔧 Configuring Pi-hole to use Unbound..."
sed -i 's/^PIHOLE_DNS_.*$/PIHOLE_DNS_1=127.0.0.1#5335/' /etc/pihole/setupVars.conf
pihole -a setdns 127.0.0.1#5335
systemctl restart pihole-FTL

echo "✅ Setup complete! System will reboot in 10 seconds..."
sleep 10
reboot
