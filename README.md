# AetherOS

> **"Where Performance Meets Elegance"**

AetherOS is a custom Linux distribution engineered around three uncompromising pillars:

1. **Ultra-Light Architecture** — Under 200MB RAM at idle, near-zero CPU usage
2. **Modern, Elegant Aesthetics** — Glass-morphism design with transparency, blur, and rounded corners
3. **Ultimate Ease of Use** — One-click installation, built-in app store, Windows-migration friendly

## Quick Links

| Resource | Link |
|---|---|
| Architecture White Paper | [ARCHITECTURE.md](ARCHITECTURE.md) |
| Download ISO | [Releases](https://github.com/salom600/AetherOS/releases) |
| Documentation | [Wiki](https://github.com/salom600/AetherOS/wiki) |
| Report Issues | [Issues](https://github.com/salom600/AetherOS/issues) |

## System Requirements

| Requirement | Minimum | Recommended |
|---|---|---|
| RAM | 512 MB | 2 GB |
| CPU | 1 core | 2+ cores |
| Disk | 8 GB | 20 GB |
| GPU | Any (Mesa supported) | NVIDIA/AMD with Vulkan |
| Boot | BIOS or UEFI | UEFI |

## Three Pillars

### 1. Ultra-Light Architecture (Under 200MB RAM)

AetherOS achieves sub-200MB idle RAM through:
- **Aggressive service stripping**: Only essential systemd services are enabled
- **Custom kernel configuration**: linux-lts with stripped unused modules
- **zram swap**: Compressed swap in RAM for memory efficiency
- **earlyoom**: Graceful OOM handling before system freeze
- **Minimal package selection**: Every package must justify its RAM footprint

**RAM Budget (Idle)**:
| Component | Estimated RAM |
|---|---|
| Linux kernel (lts, stripped) | ~15-20 MB |
| systemd (minimal services) | ~20-25 MB |
| Hyprland | ~30-50 MB |
| Waybar | ~10-15 MB |
| pipewire + wireplumber | ~10-15 MB |
| Other services | ~20-30 MB |
| **Total Estimated** | **~117-172 MB** |

### 2. Modern Aesthetics

AetherOS uses the "Aether" design language:
- **Glass-morphism**: Translucent panels with kawase blur
- **Rounded Corners**: 12px border radius on all windows
- **Smooth Animations**: Custom bezier curves for window transitions
- **WhiteSur Theme**: macOS-inspired GTK + Qt (Kvantum) theme
- **Waybar**: Modern, macOS-inspired status bar with system tray

### 3. Ultimate Ease of Use

Designed for Windows migrants:
- **Calamares Installer**: One-click graphical install with auto-partitioning
- **bauh App Store**: Universal app manager (Flatpak, AppImage, native packages)
- **Steam + Proton-GE**: Pre-installed for immediate gaming
- **Auto GPU Detection**: NVIDIA/AMD/Intel drivers auto-configured on first boot
- **Familiar Shortcuts**: Windows-key (Super) based keybindings

## Component Stack

| Layer | Component |
|---|---|
| Base Distribution | Arch Linux (glibc) |
| Init System | systemd (stripped) |
| Kernel | linux-lts |
| Display Server | Wayland |
| Window Manager | Hyprland |
| Compositor | Hyprland (built-in kawase blur) |
| Status Bar | Waybar |
| Dock | nwg-dock-hyprland |
| Terminal | foot |
| File Manager | Thunar |
| Installer | Calamares |
| App Store | bauh |
| Theme | WhiteSur GTK + Kvantum Qt |
| Shell | fish |

## Building the ISO

### Local Build (for testing)

```bash
# Install archiso
sudo pacman -S archiso

# Clone the repository
git clone https://github.com/salom600/AetherOS.git
cd AetherOS

# Build locally
sudo mkarchiso -v -w /tmp/aetheros-work -o /tmp/aetheros-out archiso/
```

### GitHub Actions Build (automated)

The ISO is automatically built via GitHub Actions on every push to `main` or tag release. See:
- [Build Workflow](.github/workflows/build-iso.yml)
- [Architecture Strategy](ARCHITECTURE.md) for the full CI/CD methodology

## Repository Structure

```
aetheros/
├── .github/workflows/    # CI/CD pipeline
├── archiso/               # archiso build profile
│   ├── profiledef.sh      # Profile definition
│   ├── packages.x86_64    # Package list
│   ├── pacman.conf        # Custom pacman config
│   ├── airootfs/           # Root filesystem overlay
│   │   ├── etc/            # System configs
│   │   │   ├── hyprland/   # Hyprland WM config
│   │   │   ├── waybar/     # Waybar bar config
│   │   │   ├── calamares/  # Installer configs
│   │   │   ├── systemd/    # Service configs
│   │   │   └── aetheros/   # AetherOS configs
│   │   └── usr/            # Applications and scripts
│   ├── syslinux/           # BIOS bootloader
│   └── grub/               # UEFI bootloader
├── scripts/                # Build and utility scripts
├── overlays/               # Theme and branding overlays
├── ARCHITECTURE.md         # Architecture white paper
└── README.md               # This file
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT License — see [LICENSE](LICENSE) for details.

---

*"The void between stars is not empty — it is filled with aether, the substance of possibility."*
