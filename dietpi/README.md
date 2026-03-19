# DietPi configuration for Pi Zero 2W

AdGuard Home + Unbound DNS server + DietPi-Dashboard setup.

## Setup

1. Flash DietPi image onto SD card using Raspberry Pi Imager
2. Run: `./prepare-sd.sh /path/to/boot/partition`
3. Boot the Pi — DietPi will auto-install AdGuard Home, Unbound, DietPi-Dashboard
4. SSH into the Pi and run: `./install.sh`

## Scripts

### `prepare-sd.sh <boot-partition>`

Run on PC after flashing SD card. Prompts for:
- root password
- WiFi SSID + key
- SSH public key
- static IP + gateway + netmask

Configures `dietpi.txt` and `dietpi-wifi.txt` for unattended first boot. Auto-installs:
- **AdGuard Home** — network-wide DNS ad blocker
- **Unbound** — recursive DNS resolver (upstream for AdGuard)
- **DietPi-Dashboard** — lightweight web UI for system monitoring (no extra configuration needed)

### `install.sh`

Run on the Pi after first boot (when AdGuard+Unbound are installed).
- Adds Unbound resilience settings (`serve-expired-client-timeout`, `val-bogus-ttl`, `serve-expired-ttl`)
- Enables optimistic caching in AdGuard Home
- Installs Unbound cache save/restore (see below)
- Fixes IPv6 `accept_ra` for RPi kernel forwarding default

## Config files

Files under `etc/` are copied to `/etc/` on the Pi by `install.sh`.

### `etc/sysctl.d/local.conf`

Sets `accept_ra=2` so the Pi accepts IPv6 default route from the router despite `ip_forward=1` (enabled by default in the RPi kernel).

### `etc/unbound/cache-save.sh`

Dumps Unbound DNS cache to disk when the service stops.

### `etc/unbound/cache-restore.sh`

Loads cached DNS data after Unbound starts, avoiding a cold cache after reboot.

### `etc/systemd/system/unbound.service.d/cache.conf`

Hooks `cache-save.sh` into Unbound's `ExecStop`.

### `etc/systemd/system/unbound-cache-restore.service`

Oneshot service that runs `cache-restore.sh` after Unbound starts.
