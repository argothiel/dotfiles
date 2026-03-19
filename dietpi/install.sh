#!/bin/bash
# DietPi Pi Zero 2W configuration installer
# Run as root on the Pi after fresh DietPi install + AdGuard Home + Unbound

set -e

echo "=== DietPi custom config installer ==="
echo ""

# Sysctl - IPv6 accept_ra fix (needed because RPi kernel enables forwarding by default)
echo "Installing sysctl config..."
cp etc/sysctl.d/local.conf /etc/sysctl.d/local.conf
sysctl -p /etc/sysctl.d/local.conf

# Unbound - add resilience settings after "serve-expired: yes"
echo "Configuring Unbound..."
UNBOUND_CONF=/etc/unbound/unbound.conf.d/dietpi.conf
if ! grep -q 'serve-expired-client-timeout' "$UNBOUND_CONF"; then
    sed -i '/serve-expired: yes/a\\tserve-expired-client-timeout: 1800\n\tval-bogus-ttl: 30\n\tserve-expired-ttl: 86400' "$UNBOUND_CONF"
fi

# Unbound cache save/restore
cp etc/unbound/cache-save.sh /etc/unbound/cache-save.sh
cp etc/unbound/cache-restore.sh /etc/unbound/cache-restore.sh
chmod +x /etc/unbound/cache-save.sh /etc/unbound/cache-restore.sh

mkdir -p /etc/systemd/system/unbound.service.d
cp etc/systemd/system/unbound.service.d/cache.conf /etc/systemd/system/unbound.service.d/cache.conf
cp etc/systemd/system/unbound-cache-restore.service /etc/systemd/system/unbound-cache-restore.service

systemctl daemon-reload
systemctl enable unbound-cache-restore.service
systemctl restart unbound

# AdGuard Home - enable optimistic caching
echo "Configuring AdGuard Home..."
sed -i 's/cache_optimistic: false/cache_optimistic: true/' /mnt/dietpi_userdata/adguardhome/AdGuardHome.yaml
systemctl restart adguardhome

echo ""
echo "Done!"
