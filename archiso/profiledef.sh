#!/bin/bash
# AetherOS archiso profile definition
# Boot mode names updated for current archiso (2024+)
# Old: bios.syslinux.mbr → bios.syslinux
# Old: uefi-x64.systemd-boot.esp → uefi.systemd-boot
# Invalid: bios.syslinux.partition, uefi-x64.systemd-boot.legacy

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

# Custom profile settings
file_permissions=(
  ['/etc/sudoers']='0440'
  ['/etc/shadow']='0600'
  ['/etc/aetheros/first-boot.sh']='0755'
  ['/usr/local/bin/aetheros-*']='0755'
)
