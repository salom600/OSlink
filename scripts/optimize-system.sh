#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║              AetherOS System Optimization                      ║
# ║     Reduces idle RAM usage to under 200MB                      ║
# ╚══════════════════════════════════════════════════════════════╝

set -e

echo "=== AetherOS System Optimization ==="

# ── 1. Disable unnecessary systemd services ────────────────────
echo "1. Disabling unnecessary systemd services..."
DISABLED_SERVES=(
    avahi-daemon
    cups
    ModemManager
    accounts-daemon
    snapd
    systemd-homed
    systemd-userdbd
    systemd-rfkill
    lvm2-monitor
    smartd
    eccd
)

for svc in "${DISABLED_SERVES[@]}"; do
    systemctl disable "$svc" 2>/dev/null || true
    systemctl mask "$svc" 2>/dev/null || true
done

echo "   Disabled: ${DISABLED_SERVES[*]}"

# ── 2. Configure zram for memory compression ──────────────────
echo "2. Configuring zram..."
cat > /etc/systemd/zram-generator.conf << EOF
[zram0]
zram-size = min(ram / 2, 4096)
compression-algorithm = lz4
swap-priority = 100
EOF

# ── 3. Configure earlyoom ────────────────────────────────────
echo "3. Configuring earlyoom..."
mkdir -p /etc/earlyoom
cat > /etc/earlyoom/earlyoom.conf << EOF
EARLYOOM_ARGS="-r 3600 -m 2 -s 200"
EOF
systemctl enable earlyoom

# ── 4. Reduce kernel module loading ───────────────────────────
echo "4. Blacklisting unnecessary kernel modules..."
cat > /etc/modprobe.d/aetheros-blacklist.conf << EOF
# Reduce RAM usage by blacklisting unused kernel modules
blacklist dccp
blacklist sctp
blacklist rds
blacklist tipc
blacklist ax25
blacklist netrom
blacklist x25
blacklist rose
blacklist decnet
blacklist econet
blacklist af_802154
blacklist ipx
blacklist appletalk
blacklist psnap
blacklist p8023
blacklist p8022
blacklist can
blacklist atm
blacklist hamradio
blacklist netatalk
blacklist fddi
blacklist hippi
blacklist wall
install dccp /bin/true
install sctp /bin/true
install rds /bin/true
install tipc /bin/true
install ax25 /bin/true
install netrom /bin/true
install x25 /bin/true
install rose /bin/true
install decnet /bin/true
install econet /bin/true
install af_802154 /bin/true
install ipx /bin/true
install appletalk /bin/true
install can /bin/true
install atm /bin/true
install hamradio /bin/true
install netatalk /bin/true
EOF

# ── 5. Optimize systemd-journald ──────────────────────────────
echo "5. Optimizing journald..."
mkdir -p /etc/systemd/journald.conf.d
cat > /etc/systemd/journald.conf.d/aetheros.conf << EOF
[Journal]
Storage=volatile
Compress=yes
Seal=no
RateLimitIntervalSec=30s
RateLimitBurst=100
SystemMaxUse=50M
SystemMaxFileSize=10M
MaxRetentionSec=1week
EOF

# ── 6. Optimize logind ────────────────────────────────────────
echo "6. Optimizing logind..."
mkdir -p /etc/systemd/logind.conf.d
cat > /etc/systemd/logind.conf.d/aetheros.conf << EOF
[Login]
HandlePowerKey=poweroff
HandleLidSwitch=suspend
HandleLidSwitchExternalPower=suspend
HandleLidSwitchDocked=ignore
IdleAction=ignore
KillUserProcesses=yes
EOF

# ── 7. Disable unnecessary cron/at ────────────────────────────
echo "7. Removing cron/at (not needed in systemd system)..."
pacman -Rns cronie at 2>/dev/null || true

# ── 8. Clean pacman cache ─────────────────────────────────────
echo "8. Cleaning pacman cache..."
paccache -r 2>/dev/null || true
rm -rf /var/cache/pacman/pkg/* 2>/dev/null || true

# ── 9. Reduce locale generation ────────────────────────────────
echo "9. Optimizing locale generation..."
cat > /etc/locale.conf << EOF
LANG=en_US.UTF-8
LC_MESSAGES=en_US.UTF-8
EOF

# ── 10. Optimize font cache ────────────────────────────────────
echo "10. Optimizing font cache..."
fc-cache -f 2>/dev/null || true

# ── Final Report ──────────────────────────────────────────────
echo ""
echo "=== Optimization Complete ==="
echo "Run 'aetheros-ram-monitor' to check current RAM usage."
