#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║              AetherOS First Boot Setup Script                 ║
# ║       Runs on first boot after Calamares installation         ║
# ╚══════════════════════════════════════════════════════════════╝

set -e

LOG_FILE="/var/log/aetheros-first-boot.log"
FLAG_FILE="/etc/aetheros/first-boot-done"

# Check if already done
if [ -f "$FLAG_FILE" ]; then
    echo "First boot setup already completed. Skipping."
    exit 0
fi

echo "=== AetherOS First Boot Setup ===" | tee "$LOG_FILE"
echo "Starting at: $(date)" | tee -a "$LOG_FILE"

# ── 1. Detect and Configure GPU Drivers ──────────────────────
echo "1. Detecting GPU hardware..." | tee -a "$LOG_FILE"

GPU_VENDOR=$(lspci -nn | grep -i 'vga\|3d\|display' | head -1 | grep -oi 'nvidia\|amd\|intel' | head -1)

case "$GPU_VENDOR" in
    nvidia)
        echo "   Detected NVIDIA GPU. Enabling nvidia-dkms driver..." | tee -a "$LOG_FILE"
        systemctl enable nvidia-powerd.service 2>/dev/null || true
        cat > /etc/modprobe.d/nvidia.conf << EOF
options nvidia NVreg_PreserveVideoMemoryAllocations=1
options nvidia NVreg_TemporaryFilePath=/var/tmp
options nvidia-drm modeset=1
EOF
        ;;
    amd)
        echo "   Detected AMD GPU. Using mesa drivers (pre-installed)." | tee -a "$LOG_FILE"
        ;;
    intel)
        echo "   Detected Intel GPU. Using mesa drivers (pre-installed)." | tee -a "$LOG_FILE"
        ;;
    *)
        echo "   Unknown GPU vendor. Using default mesa drivers." | tee -a "$LOG_FILE"
        ;;
esac

# ── 2. Install AUR-only packages via Chaotic-AUR ──────────────
echo "2. Installing AUR-only packages from Chaotic-AUR..." | tee -a "$LOG_FILE"
# These packages are NOT in official Arch repos and were excluded
# from the archiso package list to avoid build failures.
# Chaotic-AUR is configured in /etc/pacman.conf (added by
# customize_airootfs.sh during the build).
pacman -Sy --noconfirm eza 2>/dev/null || echo "   eza not available (install manually: pacman -S eza)" | tee -a "$LOG_FILE"
pacman -Sy --noconfirm calamares 2>/dev/null || echo "   calamares not available (install manually)" | tee -a "$LOG_FILE"
pacman -Sy --noconfirm nwg-dock-hyprland 2>/dev/null || echo "   nwg-dock-hyprland not available" | tee -a "$LOG_FILE"
# Install bauh via pip (not in any pacman repo)
pip install bauh 2>/dev/null || echo "   bauh not available (install manually: pip install bauh)" | tee -a "$LOG_FILE"

# ── 3. Setup Flatpak Repository ──────────────────────────────
echo "3. Setting up Flatpak repository..." | tee -a "$LOG_FILE"
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true

# ── 4. Configure bauh App Store ──────────────────────────────
echo "4. Configuring bauh app store..." | tee -a "$LOG_FILE"
mkdir -p /home/*/.config/bauh 2>/dev/null || true

# ── 5. Set Display Scaling ────────────────────────────────────
echo "5. Setting display scaling..." | tee -a "$LOG_FILE"
RESOLUTION=$(xdpyinfo 2>/dev/null | grep dimensions | awk '{print $2}' | cut -d'x' -f1 || echo "1920")

if [ "$RESOLUTION" -gt 2000 ]; then
    echo "   High-resolution display detected. Setting 1.5x scale." | tee -a "$LOG_FILE"
    sed -i 's/monitor = , preferred, auto, 1/monitor = , preferred, auto, 1.5/' /etc/hypr/hyprland.conf
fi

# ── 6. Enable GameMode ───────────────────────────────────────
echo "6. Enabling GameMode..." | tee -a "$LOG_FILE"
systemctl enable gamemoded 2>/dev/null || true

# ── 7. Setup User XDG Directories ────────────────────────────
echo "7. Setting up XDG user directories..." | tee -a "$LOG_FILE"
for user_home in /home/*; do
    if [ -d "$user_home" ]; then
        username=$(basename "$user_home")
        xdg-user-dirs-update --force 2>/dev/null || true
        mkdir -p "$user_home/Screenshots" 2>/dev/null || true
    fi
done

# ── 8. Optimize System for Low RAM ────────────────────────────
echo "8. Optimizing system for low RAM usage..." | tee -a "$LOG_FILE"

# Configure zram
cat > /etc/systemd/zram-generator.conf << EOF
[zram0]
zram-size = min(ram / 2, 4096)
compression-algorithm = lz4
swap-priority = 100
EOF

# Configure earlyoom
cat > /etc/earlyoom/earlyoom.conf << EOF
EARLYOOM_ARGS="-r 3600 -m 2 -s 200"
EOF

# ── 9. Set Default Applications ───────────────────────────────
echo "9. Setting default applications..." | tee -a "$LOG_FILE"
mkdir -p /etc/xdg/default-apps

# ── 10. Final Cleanup ──────────────────────────────────────────
echo "10. Final cleanup..." | tee -a "$LOG_FILE"
rm -rf /var/cache/pacman/pkg/* 2>/dev/null || true
systemctl disable aetheros-first-boot.service 2>/dev/null || true

# ── 11. Mark as Done ──────────────────────────────────────────
echo "11. Marking first boot as complete." | tee -a "$LOG_FILE"
date > "$FLAG_FILE"

echo "=== AetherOS First Boot Setup Complete ===" | tee -a "$LOG_FILE"
echo "Completed at: $(date)" | tee -a "$LOG_FILE"

exit 0
