#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║              AetherOS Gaming Stack Setup                      ║
# ║     Install and configure all gaming components               ║
# ╚══════════════════════════════════════════════════════════════╝

set -e

echo "=== AetherOS Gaming Stack Setup ==="

# ── 1. Install Steam ────────────────────────────────────────────
echo "1. Installing Steam..."
# Steam is already in the package list, but ensure it's present
pacman -Q steam &>/dev/null || sudo pacman -S --noconfirm steam

# ── 2. Install Proton-GE ────────────────────────────────────────
echo "2. Installing Proton-GE..."
# Use Chaotic-AUR pre-built binary (much faster than AUR compilation)
pacman -Q proton-ge-custom &>/dev/null || sudo pacman -S --noconfirm proton-ge-custom

# ── 3. Configure Steam Proton ────────────────────────────────────
echo "3. Configuring Steam Proton settings..."
STEAM_DIR="/home/*/.steam/steam"
if [ -d "$STEAM_DIR" ]; then
    # Set Proton-GE as default for all games
    for user_home in /home/*; do
        if [ -d "$user_home/.steam/steam" ]; then
            mkdir -p "$user_home/.steam/steam/config"
            cat > "$user_home/.steam/steam/config/config.vdf" << EOF
"Software"
{
    "Valve"
    {
        "Steam"
        {
            "Proton"
            {
                "DefaultProton" "Proton-GE"
            }
        }
    }
}
EOF
        fi
    done
fi

# ── 4. Install gamescope ────────────────────────────────────────
echo "4. Installing gamescope..."
pacman -Q gamescope &>/dev/null || sudo pacman -S --noconfirm gamescope

# ── 5. Install gamemode ────────────────────────────────────────
echo "5. Installing and enabling gamemode..."
pacman -Q gamemode &>/dev/null || sudo pacman -S --noconfirm gamemode lib32-gamemode
systemctl enable gamemoded

# ── 6. Install mangohud ────────────────────────────────────────
echo "6. Installing mangohud..."
pacman -Q mangohud &>/dev/null || sudo pacman -S --noconfirm mangohud lib32-mangohud

# ── 7. Install Wine ────────────────────────────────────────────
echo "7. Installing wine..."
pacman -Q wine &>/dev/null || sudo pacman -S --noconfirm wine

# ── 8. Configure gamemode ────────────────────────────────────────
echo "8. Configuring gamemode..."
cat > /etc/gamemode.ini << EOF
[general]
renice = 10
ioprio = 0

[gpu]
apply_gpu_optimisations = accept-responsibility
gpu_performance_mode = high

[cpu]
park_cores = no
pin_cores = yes

[custom]
start = notify-send "AetherOS" "GameMode ON - Maximum Performance"
end = notify-send "AetherOS" "GameMode OFF - Normal Mode"
EOF

# ── 9. Install 32-bit libraries ────────────────────────────────
echo "9. Installing 32-bit compatibility libraries..."
sudo pacman -S --noconfirm --needed lib32-mesa lib32-vulkan-radeon lib32-vulkan-icd-loader lib32-libgl lib32-glibc

# ── 10. Install GPU drivers ────────────────────────────────────
echo "10. Detecting and installing GPU drivers..."
GPU_VENDOR=$(lspci -nn | grep -i 'vga\|3d\|display' | head -1 | grep -oi 'nvidia\|amd\|intel' | head -1)

case "$GPU_VENDOR" in
    nvidia)
        echo "   Detected NVIDIA GPU"
        sudo pacman -S --noconfirm --needed nvidia-dkms nvidia-utils lib32-nvidia-utils nvidia-settings
        ;;
    amd)
        echo "   Detected AMD GPU"
        sudo pacman -S --noconfirm --needed mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon
        ;;
    intel)
        echo "   Detected Intel GPU"
        sudo pacman -S --noconfirm --needed mesa lib32-mesa intel-media-driver
        ;;
    *)
        echo "   Unknown GPU - installing mesa fallback"
        sudo pacman -S --noconfirm --needed mesa lib32-mesa
        ;;
esac

echo "=== Gaming Stack Setup Complete ==="
echo "Steam, Proton-GE, gamescope, gamemode, and mangohud are ready."
