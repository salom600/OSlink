#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  AetherOS Post-Install Customization Script                  ║
# ║  Runs INSIDE airootfs after all packages are installed       ║
# ║  by mkarchiso. This script:                                  ║
# ║  1. Fixes Chaotic-AUR SigLevel (TrustAll → Required)        ║
# ║  2. Adds Chaotic-AUR key to the airootfs keyring             ║
# ║  3. Enables systemd services for the live session            ║
# ║  4. Sets up user environment defaults                        ║
# ╚══════════════════════════════════════════════════════════════╝
set -e

echo "╔══════════════════════════════════════════════╗"
echo "║   AetherOS AIrootfs Customization             ║"
echo "╚══════════════════════════════════════════════╝"

# ── 1. Fix Chaotic-AUR SigLevel ────────────────────────────────
# During the archiso build, Chaotic-AUR used SigLevel=TrustAll
# because mkarchiso creates a fresh keyring without Chaotic-AUR key.
# Now we have the airootfs fully built, so we can add the key
# properly and switch to secure SigLevel.
echo "[1/5] Fixing Chaotic-AUR security..."

# Add Chaotic-AUR key to the airootfs keyring
pacman-key --recv-key FBA220DFC832C11735C747735D658004B10F7888 --keyserver keyserver.ubuntu.com || {
    echo "Warning: Could not receive Chaotic-AUR key from ubuntu keyserver"
    echo "Trying with keys.openpgp.org..."
    pacman-key --recv-key FBA220DFC832C11735C747735D658004B10F7888 --keyserver keys.openpgp.org || {
        echo "Warning: Could not receive Chaotic-AUR key"
        echo "Keeping TrustAll for Chaotic-AUR (less secure but functional)"
        echo "User should run: pacman-key --recv-key FBA220DFC832C11735C747735D658004B10F7888"
        echo "  && pacman-key --lsign-key FBA220DFC832C11735C747735D658004B10F7888"
        # Keep TrustAll since we can't add the key
        SKIP_SIGLEVEL_FIX=1
    }
}

if [ -z "$SKIP_SIGLEVEL_FIX" ]; then
    pacman-key --lsign-key FBA220DFC832C11735C747735D658004B10F7888 || true

    # Change Chaotic-AUR SigLevel from TrustAll to Required DatabaseOptional
    sed -i 's/^SigLevel = TrustAll/SigLevel = Required DatabaseOptional/' /etc/pacman.conf
    echo "Chaotic-AUR SigLevel changed to Required DatabaseOptional (secure)"
fi

# ── 2. Sync Chaotic-AUR database with proper key ──────────────
echo "[2/5] Syncing package databases..."
pacman -Sy --noconfirm || echo "Warning: Some databases failed to sync"

# ── 3. Enable systemd services ─────────────────────────────────
echo "[3/5] Enabling systemd services..."

# Network
systemctl enable NetworkManager.service

# Audio (PipeWire - user services need different handling)
# Note: systemd user services can't be 'enabled' from root in chroot
# They will be enabled by first-boot.sh on the live system

# Bluetooth
systemctl enable bluetooth.service

# Power management
systemctl enable upower.service
systemctl enable tlp.service || echo "tlp may not be available"

# Early OOM killer
systemctl enable earlyoom.service

# ZRAM generator (creates swap on boot)
systemctl enable systemd-zram-setup@zram0.service || echo "zram-setup may not be available"

# SSD optimization
systemctl enable fstrim.timer || echo "fstrim may not be available"

# AppArmor (optional, may not fully work in live session)
systemctl enable apparmor.service || echo "apparmor may not be available"

# AetherOS first-boot service
systemctl enable aetheros-first-boot.service || echo "aetheros-first-boot may not be available"

# ── 4. Set up default user environment ──────────────────────────
echo "[4/5] Setting up default user environment..."

# Create default user directories skeleton
mkdir -p /etc/skel/Desktop
mkdir -p /etc/skel/Documents
mkdir -p /etc/skel/Downloads
mkdir -p /etc/skel/Music
mkdir -p /etc/skel/Pictures
mkdir -p /etc/skel/Videos
mkdir -p /etc/skel/.config
mkdir -p /etc/skel/.local/share

# Copy Hyprland config to user skeleton
mkdir -p /etc/skel/.config/hypr
cp -r /etc/hyprland/hyprland.conf /etc/skel/.config/hypr/hyprland.conf || true
cp -r /etc/hypr/hyprpaper.conf /etc/skel/.config/hypr/hyprpaper.conf || true

# Copy Waybar config to user skeleton
mkdir -p /etc/skel/.config/waybar
cp -r /etc/waybar/config /etc/skel/.config/waybar/config || true
cp -r /etc/waybar/style.css /etc/skel/.config/waybar/style.css || true

# Copy wofi config skeleton
mkdir -p /etc/skel/.config/wofi

# Copy foot terminal config skeleton
mkdir -p /etc/skel/.config/foot

# Set default shell to fish for live session user
# (Actual user creation is handled by first-boot.sh or Calamares)
echo "Default user environment skeleton created"

# ── 5. Final cleanup ────────────────────────────────────────────
echo "[5/5] Final cleanup..."

# Remove build-only packages that shouldn't be in the live system
# archiso is needed for the build but not the live system
# Actually, keep archiso - some users may want to remaster

# Clean pacman cache to reduce ISO size
yes | pacman -Sc || echo "Cache cleanup done"

# Remove any temporary files
rm -rf /tmp/* 2>/dev/null || true
rm -rf /var/cache/pacman/pkg/* 2>/dev/null || true

# Fix permissions on critical files
chmod 0440 /etc/sudoers || true
chmod 0755 /etc/aetheros/first-boot.sh || true
chmod 0755 /usr/local/bin/aetheros-first-boot || true
chmod 0755 /usr/local/bin/aetheros-gaming-mode || true
chmod 0755 /usr/local/bin/aetheros-ram-monitor || true

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║   AetherOS AIrootfs Customization Complete!   ║"
echo "╚══════════════════════════════════════════════╝"
