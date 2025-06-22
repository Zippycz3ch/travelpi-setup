git clone https://github.com/Zippycz3ch/travelpi-setup
cd travelpi-setup
chmod +x setup-travelpi.sh

# Run everything
sudo ./setup-travelpi.sh --all

# OR: run selected modules only
sudo ./setup-travelpi.sh --hotspot --dnsmasq --unbound