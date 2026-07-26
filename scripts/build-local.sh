#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║              AetherOS Local Build Script                      ║
# ║     Build the ISO locally for testing before CI/CD            ║
# ╚══════════════════════════════════════════════════════════════╝

set -e

# Configuration
WORK_DIR="/tmp/aetheros-work"
OUT_DIR="/tmp/aetheros-out"
PROFILE_DIR="$(pwd)/archiso"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║          AetherOS Local Build Script          ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════╝${NC}"

# ── Check Dependencies ──────────────────────────────────────────
echo -e "${BLUE}[1/7] Checking dependencies...${NC}"

REQUIRED_PKGS=(archiso squashfs-tools dosfstools mtools xorriso grub)
MISSING_PKGS=()

for pkg in "${REQUIRED_PKGS[@]}"; do
    if ! pacman -Qi "$pkg" > /dev/null 2>&1; then
        MISSING_PKGS+=("$pkg")
    fi
done

if [ ${#MISSING_PKGS[@]} -gt 0 ]; then
    echo -e "${RED}Missing packages: ${MISSING_PKGS[*]}${NC}"
    echo -e "${BLUE}Installing missing packages...${NC}"
    sudo pacman -Sy --noconfirm --needed "${MISSING_PKGS[@]}"
fi

echo -e "${GREEN}All dependencies satisfied.${NC}"

# ── Clean Previous Builds ──────────────────────────────────────
echo -e "${BLUE}[2/7] Cleaning previous builds...${NC}"

if [ -d "$WORK_DIR" ]; then
    sudo rm -rf "$WORK_DIR"
fi
if [ -d "$OUT_DIR" ]; then
    sudo rm -rf "$OUT_DIR"
fi

sudo mkdir -p "$WORK_DIR" "$OUT_DIR"

# ── Apply Overlays ──────────────────────────────────────────────
echo -e "${BLUE}[3/7] Applying overlays...${NC}"

# Copy theme overlays
if [ -d "overlays/theme" ]; then
    sudo cp -r overlays/theme/* "$PROFILE_DIR/airootfs/"
fi

# Copy branding overlays
if [ -d "overlays/branding" ]; then
    sudo cp -r overlays/branding/logos/* "$PROFILE_DIR/airootfs/usr/share/pixmaps/" 2>/dev/null || true
    sudo cp -r overlays/branding/wallpapers/* "$PROFILE_DIR/airootfs/usr/share/pixmaps/" 2>/dev/null || true
fi

# ── Make Scripts Executable ─────────────────────────────────────
echo -e "${BLUE}[4/7] Making scripts executable...${NC}"

sudo find "$PROFILE_DIR" -name "*.sh" -exec chmod +x {} \;
sudo find "$PROFILE_DIR" -path "*/usr/local/bin/*" -exec chmod +x {} \;

# ── Run Optimization ────────────────────────────────────────────
echo -e "${BLUE}[5/7] Running system optimization...${NC}"

sudo bash scripts/optimize-system.sh || true

# ── Build ISO ────────────────────────────────────────────────────
echo -e "${BLUE}[6/7] Building ISO (this takes 30-60 minutes)...${NC}"

sudo mkarchiso -v -w "$WORK_DIR" -o "$OUT_DIR" "$PROFILE_DIR"

# ── Verify and Report ────────────────────────────────────────────
echo -e "${BLUE}[7/7] Verifying build...${NC}"

ISO_FILE=$(ls "$OUT_DIR"/*.iso 2>/dev/null | head -1)

if [ -z "$ISO_FILE" ]; then
    echo -e "${RED}ERROR: No ISO file found!${NC}"
    exit 1
fi

ISO_SIZE=$(du -h "$ISO_FILE" | cut -f1)
SHA256=$(sha256sum "$ISO_FILE" | cut -d' ' -f1)

echo -e "${GREEN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║          AetherOS Build Complete!             ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════╝${NC}"
echo -e "  ISO File:  ${CYAN}${ISO_FILE}${NC}"
echo -e "  ISO Size:  ${CYAN}${ISO_SIZE}${NC}"
echo -e "  SHA256:    ${CYAN}${SHA256}${NC}"
echo ""
echo -e "To test the ISO in QEMU:"
echo -e "  ${CYAN}qemu-system-x86_64 -m 2048 -cdrom ${ISO_FILE} -boot d${NC}"
