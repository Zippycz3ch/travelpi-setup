#!/bin/bash

# Modular TravelPi Setup Script
# This script accepts flags to selectively run different setup modules.

set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/var/log/travelpi_setup.log"
exec > >(tee -a "$LOG_FILE") 2>&1

# Helper logging functions
log() { echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] $*"; }
error_exit() { echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] $*" >&2; exit 1; }
trap 'trap - ERR; error_exit "Unexpected error at line $LINENO: $BASH_COMMAND (code $?)"' ERR

# Available setup modules
RUN_UPDATE=false
RUN_PACKAGES=false
RUN_HOTSPOT=false
RUN_UPSTREAM=false
RUN_HOSTAPD=false
RUN_DNSMASQ=false
RUN_UNBOUND=false
RUN_FORWARDING=false
RUN_IPTABLES=false
RUN_API=false
RUN_PIHOLE=false
RUN_PIHOLE_DNS=false

usage() {
  echo "Usage: $0 [--all] [--update] [--packages] [--hotspot] [--upstream] [--hostapd] [--dnsmasq] [--unbound] [--forwarding] [--iptables] [--api] [--pihole] [--pihole-dns]"
  exit 1
}

# Parse arguments
if [[ $# -eq 0 ]]; then usage; fi
for arg in "$@"; do
  case $arg in
    --all) RUN_UPDATE=true; RUN_PACKAGES=true; RUN_HOTSPOT=true; RUN_UPSTREAM=true;
           RUN_HOSTAPD=true; RUN_DNSMASQ=true; RUN_UNBOUND=true; RUN_FORWARDING=true;
           RUN_IPTABLES=true; RUN_API=true; RUN_PIHOLE=true; RUN_PIHOLE_DNS=true;;
    --update) RUN_UPDATE=true;;
    --packages) RUN_PACKAGES=true;;
    --hotspot) RUN_HOTSPOT=true;;
    --upstream) RUN_UPSTREAM=true;;
    --hostapd) RUN_HOSTAPD=true;;
    --dnsmasq) RUN_DNSMASQ=true;;
    --unbound) RUN_UNBOUND=true;;
    --forwarding) RUN_FORWARDING=true;;
    --iptables) RUN_IPTABLES=true;;
    --api) RUN_API=true;;
    --pihole) RUN_PIHOLE=true;;
    --pihole-dns) RUN_PIHOLE_DNS=true;;
    *) usage;;
  esac
done

# Run selected modules
$RUN_UPDATE     && bash "$SCRIPT_DIR/modules/update.sh"
$RUN_PACKAGES   && bash "$SCRIPT_DIR/modules/install_packages.sh"
$RUN_HOTSPOT    && bash "$SCRIPT_DIR/modules/configure_hotspot.sh"
$RUN_UPSTREAM   && bash "$SCRIPT_DIR/modules/connect_upstream.sh"
$RUN_HOSTAPD    && bash "$SCRIPT_DIR/modules/configure_hostapd.sh"
$RUN_DNSMASQ    && bash "$SCRIPT_DIR/modules/configure_dnsmasq.sh"
$RUN_UNBOUND    && bash "$SCRIPT_DIR/modules/configure_unbound.sh"
$RUN_FORWARDING && bash "$SCRIPT_DIR/modules/enable_ip_forwarding.sh"
$RUN_IPTABLES   && bash "$SCRIPT_DIR/modules/setup_iptables.sh"
$RUN_API        && bash "$SCRIPT_DIR/modules/install_api_service.sh"
$RUN_PIHOLE     && bash "$SCRIPT_DIR/modules/install_pi_hole.sh"
$RUN_PIHOLE_DNS && bash "$SCRIPT_DIR/modules/configure_pi_hole.sh"

log "✅ All selected modules executed."
