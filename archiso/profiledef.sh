#!/bin/bash
# AetherOS archiso profile definition

iso_name="AetherOS"
iso_label="AETHER_$(date +%Y%m)"
iso_publisher="AetherOS Project"
iso_application="AetherOS Linux Distribution"
iso_version="$(date +%Y.%m.%d)"
install_dir="aetheros"
bootmodes=('bios.syslinux.mbr' 'bios.syslinux.partition' 'uefi-x64.systemd-boot.esp' 'uefi-x64.systemd-boot.legacy')
arch="x86_64"
pacman_conf="pacman.conf"
grub_prefix="grub"
packages=("packages.x86_64")
# AUR/Chaotic-AUR packages handled separately via post-install script

# Custom profile settings
file_permissions=(
  ['/etc/sudoers']='0440'
  ['/etc/shadow']='0600'
  ['/etc/aetheros/first-boot.sh']='0755'
  ['/usr/local/bin/aetheros-*']='0755'
)
