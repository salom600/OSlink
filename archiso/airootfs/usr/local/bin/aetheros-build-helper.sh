#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║       AetherOS Build Helper - Runs Inside Arch Container     ║
# ║  Handles: pacman init, Chaotic-AUR setup, archiso, ISO build  ║
# ╚══════════════════════════════════════════════════════════════╝
set -e

BUILD_DIR="/tmp/aetheros-build"
PROFILE_DIR="${BUILD_DIR}/profile"

echo "╔══════════════════════════════════════════════╗"
echo "║         AetherOS ISO Build (Arch Container)  ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# ── 1. Initialize pacman keyring ─────────────────────────────────
echo "[1/7] Initializing pacman keyring..."
pacman-key --init
pacman-key --populate archlinux

# ── 2. Setup mirrorlist ──────────────────────────────────────────
echo "[2/7] Setting up mirrorlist..."
mkdir -p /etc/pacman.d
cat > /etc/pacman.d/mirrorlist << 'MIRRORLIST'
Server = https://geo.mirror.pkgbuild.com/$repo/os/$arch
Server = https://mirror.rackspace.com/archlinux/$repo/os/$arch
Server = https://mirror.f4st.org/archlinux/$repo/os/$arch
Server = https://archlinux.thaller.ws/archlinux/$repo/os/$arch
MIRRORLIST

# ── 3. Add Chaotic-AUR repository ────────────────────────────────
echo "[3/7] Adding Chaotic-AUR repository..."

# Receive and sign the Chaotic-AUR key
pacman-key --recv-key FBA220DFC832C11735C747735D658004B10F7888 || {
    echo "Warning: Could not receive Chaotic-AUR key via pacman-key"
    echo "Will add Chaotic-AUR with relaxed SigLevel as fallback"
}

pacman-key --lsign-key FBA220DFC832C11735C747735D658004B10F7888 || {
    echo "Warning: Could not locally sign Chaotic-AUR key"
}

# Add Chaotic-AUR to system pacman.conf (for building archiso itself)
grep -q 'chaotic-aur' /etc/pacman.conf || {
    echo '' >> /etc/pacman.conf
    echo '[chaotic-aur]' >> /etc/pacman.conf
    echo 'SigLevel = Required DatabaseOptional' >> /etc/pacman.conf
    echo 'Server = https://cdn-mirror.chaotic.cx/$repo/$arch' >> /etc/pacman.conf
}

# ── 4. Update package databases ──────────────────────────────────
echo "[4/7] Updating package databases..."
pacman -Sy --noconfirm || {
    echo "Warning: Some repos failed to sync. Trying without Chaotic-AUR..."
    # Fallback: remove Chaotic-AUR and retry if it's the problem
    sed -i '/\[chaotic-aur\]/,/^$/d' /etc/pacman.conf
    sed -i '/chaotic-aur/d' /etc/pacman.conf
    pacman -Sy --noconfirm
}

# ── 5. Install archiso and build dependencies ────────────────────
echo "[5/7] Installing archiso and build tools..."
pacman -S --noconfirm --needed archiso arch-install-scripts git base-devel squashfs-tools dosfstools mtools xorriso grub syslinux

# Verify mkarchiso exists
which mkarchiso
echo "mkarchiso found! Proceeding with build..."

# ── 6. Prepare profile for mkarchiso ─────────────────────────────
echo "[6/7] Preparing AetherOS profile..."

# Ensure profiledef.sh uses correct shebang
sed -i 's|^#!/usr/bash|#!/bin/bash|' "${PROFILE_DIR}/profiledef.sh" || true

# Make all scripts executable
find "${PROFILE_DIR}" -name "*.sh" -exec chmod +x {} \; || true
find "${PROFILE_DIR}/airootfs/usr/local/bin" -type f -exec chmod +x {} \; 2>/dev/null || true
find "${PROFILE_DIR}/airootfs/etc/aetheros" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true

# Ensure /etc/sudoers has correct permissions (mkarchiso checks this)
chmod 0440 "${PROFILE_DIR}/airootfs/etc/sudoers" 2>/dev/null || true

# Copy Chaotic-AUR conf into profile's pacman.d
mkdir -p "${PROFILE_DIR}/airootfs/etc/pacman.d/"
if [ -f "${PROFILE_DIR}/airootfs/etc/pacman.d/chaotic-aur.conf" ]; then
    echo "Chaotic-AUR conf already in profile"
else
    echo "Adding Chaotic-AUR conf to profile"
    cat > "${PROFILE_DIR}/airootfs/etc/pacman.d/chaotic-aur.conf" << 'CHAOTIC'
[chaotic-aur]
SigLevel = Required DatabaseOptional
Server = https://cdn-mirror.chaotic.cx/$repo/$arch
CHAOTIC
fi

# Ensure the profile's pacman.conf includes Chaotic-AUR
grep -q 'chaotic-aur' "${PROFILE_DIR}/pacman.conf" || {
    echo "Adding Chaotic-AUR to profile pacman.conf"
    echo '' >> "${PROFILE_DIR}/pacman.conf"
    echo '[chaotic-aur]' >> "${PROFILE_DIR}/pacman.conf"
    echo 'SigLevel = Required DatabaseOptional' >> "${PROFILE_DIR}/pacman.conf"
    echo 'Server = https://cdn-mirror.chaotic.cx/$repo/$arch' >> "${PROFILE_DIR}/pacman.conf"
}

echo "Profile structure:"
ls "${PROFILE_DIR}/"
ls "${PROFILE_DIR}/airootfs/" || echo "No airootfs"

# ── 7. Build the ISO with mkarchiso ──────────────────────────────
echo "[7/7] Building ISO with mkarchiso..."
echo "This step takes 30-60 minutes..."
echo ""

mkarchiso -v -w "${BUILD_DIR}/work" -o "${BUILD_DIR}/out" "${PROFILE_DIR}"

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║        AetherOS ISO Build Complete!           ║"
echo "╚══════════════════════════════════════════════╝"
echo ""
ls -lh "${BUILD_DIR}/out/"
echo ""
echo "ISO file: $(ls ${BUILD_DIR}/out/*.iso)"
