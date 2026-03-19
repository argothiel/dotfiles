#!/bin/bash
# Prepare SD card boot partition after flashing DietPi image
# Run from PC with the boot partition mounted
# Usage: ./prepare-sd.sh /path/to/boot/partition

set -e

BOOT="${1:?Usage: $0 /path/to/boot/partition}"

if [ ! -f "$BOOT/dietpi.txt" ]; then
    echo "Error: $BOOT/dietpi.txt not found. Is this a DietPi boot partition?"
    exit 1
fi

echo "=== DietPi SD card preparation ==="
echo ""

# Password
read -rsp "DietPi root password: " dietpi_pass
echo ""

# WiFi
read -rp "WiFi SSID: " wifi_ssid
read -rsp "WiFi key: " wifi_key
echo ""

# SSH pubkey
read -rp "SSH public key (paste full line): " ssh_pubkey

# Static IP
read -rp "Static IP address (e.g. 192.168.0.123): " static_ip
read -rp "Gateway (e.g. 192.168.0.1) [192.168.0.1]: " gateway
gateway="${gateway:-192.168.0.1}"
read -rp "Netmask [255.255.255.0]: " netmask
netmask="${netmask:-255.255.255.0}"

echo ""
echo "Applying configuration..."

# dietpi.txt
sed -i "s|#AUTO_SETUP_GLOBAL_PASSWORD=.*|AUTO_SETUP_GLOBAL_PASSWORD=$dietpi_pass|" "$BOOT/dietpi.txt"
sed -i "s|AUTO_SETUP_NET_WIFI_ENABLED=0|AUTO_SETUP_NET_WIFI_ENABLED=1|" "$BOOT/dietpi.txt"
sed -i "s|AUTO_SETUP_AUTOMATED=0|AUTO_SETUP_AUTOMATED=1|" "$BOOT/dietpi.txt"
sed -i "s|AUTO_SETUP_NET_USESTATIC=0|AUTO_SETUP_NET_USESTATIC=1|" "$BOOT/dietpi.txt"
sed -i "s|AUTO_SETUP_NET_STATIC_IP=.*|AUTO_SETUP_NET_STATIC_IP=$static_ip|" "$BOOT/dietpi.txt"
sed -i "s|AUTO_SETUP_NET_STATIC_MASK=.*|AUTO_SETUP_NET_STATIC_MASK=$netmask|" "$BOOT/dietpi.txt"
sed -i "s|AUTO_SETUP_NET_STATIC_GATEWAY=.*|AUTO_SETUP_NET_STATIC_GATEWAY=$gateway|" "$BOOT/dietpi.txt"

# Add SSH pubkey after the example line
sed -i "/#AUTO_SETUP_SSH_PUBKEY=ssh-ed25519/a AUTO_SETUP_SSH_PUBKEY=$ssh_pubkey" "$BOOT/dietpi.txt"

# Auto-install software: AdGuard Home (126), Unbound (182), DietPi-Dashboard (200)
# DietPi-RAMlog (103) and Dropbear (104) are installed by default
sed -i "s|#AUTO_SETUP_INSTALL_SOFTWARE_ID=.*|AUTO_SETUP_INSTALL_SOFTWARE_ID=126 182 200|" "$BOOT/dietpi.txt"

# dietpi-wifi.txt
sed -i "s|aWIFI_SSID\[0\]=''|aWIFI_SSID[0]='$wifi_ssid'|" "$BOOT/dietpi-wifi.txt"
sed -i "s|aWIFI_KEY\[0\]=''|aWIFI_KEY[0]='$wifi_key'|" "$BOOT/dietpi-wifi.txt"

echo "Done! Safe to eject SD card."
