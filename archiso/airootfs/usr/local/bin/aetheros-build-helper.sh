#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║       AetherOS Build Helper - Runs Inside Arch Container     ║
# ║  Handles: pacman init, ALL repos, Chaotic-AUR, archiso build  ║
# ╚══════════════════════════════════════════════════════════════╝
set -e

BUILD_DIR="/tmp/aetheros-build"
PROFILE_DIR="${BUILD_DIR}/profile"

echo "╔══════════════════════════════════════════════╗"
echo "║         AetherOS ISO Build (Arch Container)  ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# ── 1. Write a COMPLETE pacman.conf with ALL repos ────────────────
# CRITICAL: The archlinux:latest Docker container only has [core]!
# Most packages are in [extra] and [multilib]. We must enable them.
echo "[1/7] Writing complete pacman.conf with all repos..."

cat > /etc/pacman.conf << 'PACMANCONF'
[options]
HoldPkg           = pacman glibc
Architecture      = auto
CheckSpace
Color
VerbosePkgLists
ParallelDownloads = 10

SigLevel    = Required DatabaseOptional
LocalSigLevel = Optional
RemoteSigLevel = Required

[core]
Include = /etc/pacman.d/mirrorlist

[extra]
Include = /etc/pacman.d/mirrorlist

[multilib]
Include = /etc/pacman.d/mirrorlist

[chaotic-aur]
SigLevel = Required DatabaseOptional
Server = https://cdn-mirror.chaotic.cx/$repo/$arch
PACMANCONF

echo "Written pacman.conf with: core, extra, multilib, chaotic-aur"

# ── 2. Initialize pacman keyring ──────────────────────────────────
echo "[2/7] Initializing pacman keyring..."
pacman-key --init
pacman-key --populate archlinux

# ── 3. Setup mirrorlist ──────────────────────────────────────────
echo "[3/7] Setting up mirrorlist..."
mkdir -p /etc/pacman.d
cat > /etc/pacman.d/mirrorlist << 'MIRRORLIST'
Server = https://geo.mirror.pkgbuild.com/$repo/os/$arch
Server = https://mirror.rackspace.com/archlinux/$repo/os/$arch
Server = https://mirror.f4st.org/archlinux/$repo/os/$arch
Server = https://archlinux.thaller.ws/archlinux/$repo/os/$arch
Server = https://arch.mirrors.bunnys.org/archlinux/$repo/os/$arch
MIRRORLIST

# ── 4. Add Chaotic-AUR key ────────────────────────────────────────
echo "[4/7] Adding Chaotic-AUR keyring..."
pacman-key --recv-key FBA220DFC832C11735C747735D658004B10F7888 || {
    echo "Warning: Could not receive Chaotic-AUR key"
    echo "Retrying with keyserver..."
    pacman-key --recv-key FBA220DFC832C11735C747735D658004B10F7888 --keyserver keyserver.ubuntu.com || {
        echo "Failed to receive Chaotic-AUR key. Trying TrustAll approach..."
        # Fallback: change SigLevel to TrustAll for Chaotic-AUR only
        sed -i 's/SigLevel = Required DatabaseOptional/SigLevel = TrustAll/' /etc/pacman.conf
    }
}
pacman-key --lsign-key FBA220DFC832C11735C747735D658004B10F7888 || true

# ── 5. Sync all repo databases ────────────────────────────────────
echo "[5/7] Syncing package databases..."
pacman -Sy --noconfirm || {
    echo "Some repos failed. Removing Chaotic-AUR and retrying..."
    sed -i '/\[chaotic-aur\]/,/^Server/d' /etc/pacman.conf
    sed -i '/chaotic-aur/d' /etc/pacman.conf
    pacman -Sy --noconfirm
}

# Install archiso and build tools (these are in [extra])
echo "Installing archiso..."
pacman -S --noconfirm --needed archiso arch-install-scripts git

command -v mkarchiso && echo "mkarchiso found at $(command -v mkarchiso)" || {
    echo "ERROR: mkarchiso not found after install!"
    echo "Checking if archiso package was installed..."
    pacman -Q archiso || echo "archiso package not installed"
    exit 1
}

# ── 6. Prepare profile ────────────────────────────────────────────
echo "[6/7] Preparing AetherOS profile..."

# Make scripts executable
find "${PROFILE_DIR}" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
find "${PROFILE_DIR}/airootfs/usr/local/bin" -type f -exec chmod +x {} \; 2>/dev/null || true
find "${PROFILE_DIR}/airootfs/etc/aetheros" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true

# Ensure /etc/sudoers exists with correct permissions
if [ -f "${PROFILE_DIR}/airootfs/etc/sudoers" ]; then
    chmod 0440 "${PROFILE_DIR}/airootfs/etc/sudoers"
fi

# Verify profile structure
echo "Profile contents:"
ls "${PROFILE_DIR}/"
echo "airootfs contents:"
ls "${PROFILE_DIR}/airootfs/" || echo "No airootfs"

# ── 7. Build the ISO ──────────────────────────────────────────────
echo "[7/7] Building ISO with mkarchiso..."
echo "This takes 30-60 minutes. Starting..."
echo ""

mkarchiso -v -w "${BUILD_DIR}/work" -o "${BUILD_DIR}/out" "${PROFILE_DIR}"

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║        AetherOS ISO Build Complete!           ║"
echo "╚══════════════════════════════════════════════╝"
ls -lh "${BUILD_DIR}/out/"
