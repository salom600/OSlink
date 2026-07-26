#!/bin/bash
# AetherOS archiso profile definition
# Boot mode names updated for current archiso (2024+)

iso_name="AetherOS"
iso_label="AETHER_$(date +%Y%m)"
iso_publisher="AetherOS Project"
iso_application="AetherOS Linux Distribution"
iso_version="$(date +%Y.%m.%d)"
install_dir="aetheros"
bootmodes=('bios.syslinux' 'uefi.systemd-boot')
arch="x86_64"
pacman_conf="pacman.conf"
packages=("packages.x86_64")

# Custom file permissions — archiso requires UID:GID:MODE format (3 colon-separated fields)
# Glob patterns are NOT supported; each file must be listed individually
file_permissions=(
  ["/etc/sudoers"]="0:0:0440"
  ["/etc/shadow"]="0:0:0600"
  ["/etc/aetheros/first-boot.sh"]="0:0:0755"
  ["/usr/local/bin/aetheros-first-boot"]="0:0:0755"
  ["/usr/local/bin/aetheros-gaming-mode"]="0:0:0755"
  ["/usr/local/bin/aetheros-ram-monitor"]="0:0:0755"
  ["/usr/local/bin/aetheros-build-helper.sh"]="0:0:0755"
  ["/root/customize_airootfs.sh"]="0:0:0755"
)
