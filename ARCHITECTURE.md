# AetherOS Architecture White Paper

> **Version:** 1.0.0  
> **Status:** Strategic Foundation  
> **Date:** 2026-07-26  

---

## 1. Executive Summary

AetherOS is a custom Linux distribution engineered to achieve what was previously considered impossible: a visually stunning, modern desktop experience that runs within **200MB of RAM at idle**, while maintaining **full gaming compatibility** (Steam, Proton, Wine) and providing a **seamless migration path for Windows users**. The entire build pipeline is automated via GitHub Actions, producing a bootable ISO that can be installed through a one-click graphical installer.

This document presents the strategic analysis, component selection, and implementation methodology that form the architectural foundation of AetherOS.

---

## 2. Base Distribution Analysis

### 2.1 Candidates Evaluated

| Criterion | Alpine Linux | Arch Linux | Void Linux (glibc) | Debian Minimal |
|---|---|---|---|---|
| **Idle RAM (base)** | ~50 MB | ~80-120 MB | ~60-80 MB | ~120-150 MB |
| **libc** | musl | glibc | glibc (optional) | glibc |
| **Steam/Proton** | Broken | Full support | Partial (community) | Full support |
| **Proprietary SW** | Frequent failures | Excellent | Moderate | Good |
| **ISO Tooling** | mkimage | archiso (mature) | mklive (basic) | live-build |
| **Package Cache (CI)** | apk cache | pacman cache | XBPS cache | apt cache |
| **Gaming Ecosystem** | Non-existent | AUR + official | Limited | Backports needed |
| **Hyprland Availability** | Community | Official repos | Community | Requires backports |
| **Community/Docs** | Moderate | Excellent | Small | Excellent |
| **CI/CD Friendliness** | Good | Excellent | Moderate | Good |

### 2.2 Verdict: Arch Linux

**Arch Linux is the chosen foundation** for the following reasons:

1. **Glibc Compatibility**: Full Steam, Proton, and proprietary software support without musl-induced breakage. This is non-negotiable for the gaming pillar.

2. **Aggressive Stripability**: While Alpine starts smaller, Arch can be stripped to within 80-120MB of idle RAM by removing unnecessary services, using a custom kernel, and carefully curating the package list. The 200MB target leaves significant headroom.

3. **archiso Maturity**: The official ISO building tool is production-grade, well-documented, and directly supports CI/CD workflows. It produces reliable, bootable ISOs with minimal configuration.

4. **Pacman Cache for CI**: pacman's package caching mechanism integrates naturally with GitHub Actions caching, dramatically reducing build times on subsequent runs.

5. **AUR for Gaming**: Proton-GE, wine-tkg, gamescope, and other gaming essentials are immediately available in the AUR without manual compilation.

6. **Hyprland in Official Repos**: Hyprland and its dependencies are available in official/community repositories, avoiding the risk of AUR compilation failures during CI builds.

7. **Documentation**: The Arch Wiki is the most comprehensive Linux documentation available, reducing support burden for AetherOS users.

### 2.3 The musl vs glibc Trade-off (Resolved)

The musl/glibc debate is the central tension in lightweight distro design. Our analysis is definitive:

- **musl (Alpine)**: 30-50MB RAM savings, but breaks Steam (requires glibc compatibility shims that are unreliable), Proton (requires glibc), many AppImages, and proprietary NVIDIA drivers. The savings do not justify the ecosystem fracture.
- **glibc (Arch)**: Slightly heavier base, but the entire Linux gaming and proprietary software ecosystem works without modification. This is the correct trade-off for a distribution that claims gaming compatibility.

**Conclusion**: The 30-50MB RAM savings from musl are not worth the catastrophic compatibility loss. We accept the glibc overhead and optimize elsewhere.

---

## 3. Software Component Selection

### 3.1 Core System Stack

| Layer | Component | Rationale |
|---|---|---|
| **Init System** | systemd (stripped) | Required for Steam, Proton, and most modern Linux gaming infrastructure. We strip all non-essential services. |
| **Kernel** | linux-lts + custom config | LTS kernel for stability, custom config removes unused modules (amateur radio, legacy SCSI, etc.) to reduce size and attack surface. |
| **Display Server** | Wayland | Native to Hyprland, lower overhead than X11, modern protocol. XWayland for legacy app compatibility. |
| **Window Manager** | Hyprland | Wayland-native, built-in compositor with kawase blur, transparency, animations, rounded corners. No separate Picom needed. |
| **Compositor** | Hyprland (built-in) | Hyprland's compositor handles all visual effects natively, eliminating the need for a separate Picom process. |
| **Status Bar** | Waybar | Lightweight, CSS-styled, Wayland-native. Highly customizable for the AetherOS aesthetic. |
| **Dock** | nwg-dock-hyprland | Native Hyprland dock, lightweight, Wayland-compatible. Alternative to Plank (X11-only). |
| **Application Launcher** | wofi | Lightweight Wayland launcher, themable, GTK-based. |
| **Notification Daemon** | mako | Minimal Wayland notification daemon, under 5MB RAM. |
| **Clipboard Manager** | cliphist + wl-clipboard | Wayland-native clipboard management. |
| **Screenshot** | grim + slurp | Wayland-native screenshot tools. |
| **Wallpaper** | hyprpaper | Hyprland's native wallpaper setter, minimal overhead. |
| **Screen Lock** | swaylock-effects | Wayland lock screen with blur effects. |
| **Polkit Agent** | polkit-gnome | Lightweight authentication agent. |
| **Session** | Hyprland session | No display manager; auto-login via autologin + Hyprland launch. |

### 3.2 Desktop Applications

| Category | Application | RAM Impact | Rationale |
|---|---|---|---|
| **Terminal** | foot | ~5 MB | Fastest Wayland terminal emulator. |
| **File Manager** | Thunar | ~15 MB | Lightweight, feature-complete, XFCE's file manager. |
| **Text Editor** | mousepad | ~3 MB | Lightweight GTK text editor. |
| **Browser** | Firefox | ~200+ MB (when open) | Essential for web browsing. Not running at idle. |
| **Image Viewer** | imv | ~2 MB | Minimal Wayland image viewer. |
| **Media Player** | mpv | ~10 MB | Lightweight, codec-complete media player. |
| **Archive Manager** | file-roller | ~5 MB | GNOME archive manager, GTK-native. |
| **PDF Viewer** | zathura | ~3 MB | Minimal, keyboard-driven PDF viewer. |

### 3.3 System Services

| Service | Status | Rationale |
|---|---|---|
| **NetworkManager** | Enabled | Required for Wi-Fi; users expect seamless networking. |
| **bluetooth** | Enabled | Expected for modern hardware. |
| **dbus** | Enabled | Required by Hyprland, Waybar, and most desktop apps. |
| **elogind** | Enabled | Session management for Wayland. |
| **pipewire** | Enabled | Modern audio/video stack, required for gaming. |
| **pipewire-pulse** | Enabled | PulseAudio compatibility for games. |
| **wireplumber** | Enabled | PipeWire session manager. |
| **avahi-daemon** | Disabled | Unnecessary for most users. |
| **cups** | Disabled | Enable on-demand; not needed at idle. |
| **ModemManager** | Disabled | Not needed for desktop/laptop. |
| **accounts-daemon** | Disabled | Not needed with single-user setup. |
| **swap-on-zram** | Enabled | Compressed swap in RAM; improves memory efficiency. |

### 3.4 Gaming Stack

| Component | Purpose |
|---|---|
| **Steam** | Primary gaming platform. |
| **Proton-GE** | Custom Proton build with additional fixes and media playback. |
| **wine** | Windows compatibility layer. |
| **gamescope** | Valve's micro-compositor for gaming. |
| **gamemode** | Feral Interactive's game optimization daemon. |
| **mangohud** | Performance overlay for games. |
| **vulkan-radeon / nvidia** | GPU drivers (auto-detected). |
| **mesa** | Open-source graphics stack. |
| **lib32-*** | 32-bit compatibility libraries for Steam/Proton. |

### 3.5 Installer & App Store

| Component | Purpose |
|---|---|
| **Calamares** | Graphical installer with automated partition profile. One-click install for Windows migrants. |
| **Bauh** | Universal app store managing Flatpak, AppImage, AUR, and native packages from a single GUI. |
| **Flatpak** | Sandboxed application distribution. |
| **Codecs** | Pre-installed media codecs (gstreamer, ffmpeg). |
| **Wi-Fi Drivers** | Pre-installed linux-firmware for broad hardware support. |

### 3.6 Theming Stack

| Component | Purpose |
|---|---|
| **WhiteSur GTK Theme** | macOS-inspired GTK theme for consistent, modern aesthetics. |
| **WhiteSur Icon Theme** | Matching icon set. |
| **WhiteSur Cursor Theme** | Matching cursor set. |
| **Kvantum + WhiteSur Kvantum** | Qt theme engine + matching Qt theme for consistent Qt/GTK look. |
| **WhiteSur Firefox Theme** | Browser integration. |
| **Inter Font** | Modern, clean sans-serif font for UI. |
| **Noto Sans/Serif** | CJK and fallback font coverage. |
| **Custom Hyprland Config** | Kawase blur, transparency, rounded corners, animations. |
| **Custom Waybar Config** | Modern, macOS-inspired bar with system tray. |

---

## 4. RAM Budget Analysis

### 4.1 Idle RAM Allocation (Target: < 200 MB)

| Component | Estimated RAM |
|---|---|
| Linux kernel (lts, stripped) | ~15-20 MB |
| systemd (minimal services) | ~20-25 MB |
| dbus | ~3-5 MB |
| NetworkManager | ~8-12 MB |
| pipewire + wireplumber | ~10-15 MB |
| Hyprland | ~30-50 MB |
| Waybar | ~10-15 MB |
| mako | ~2-3 MB |
| polkit-gnome | ~3-5 MB |
| hyprpaper | ~5-10 MB |
| cliphist | ~1-2 MB |
| dbus services overhead | ~10-15 MB |
| **Total Estimated** | **~117-172 MB** |

### 4.2 Headroom Analysis

With an estimated idle RAM of 117-172 MB, we have **28-83 MB of headroom** below the 200MB target. This headroom is sufficient for:
- Additional user services (bluetooth, etc.)
- Driver variations (NVIDIA proprietary drivers add ~20-30MB)
- Kernel module variations

### 4.3 Optimization Strategies

1. **zram swap**: Compressed swap in RAM effectively doubles available memory for cold pages.
2. **zramctl configuration**: 50% of RAM allocated to zram with lz4 compression.
3. **Early OOM**: `earlyoom` daemon to gracefully handle memory pressure.
4. **Prelink disabled**: Unnecessary for modern systems.
5. **Package audit**: Every installed package must justify its RAM footprint.
6. **systemd service audit**: All enabled services must be essential.

---

## 5. GitHub Actions Strategy

### 5.1 Constraints

| Constraint | Limit | Impact |
|---|---|---|
| **Execution Time** | 6 hours | Build must complete within this window. |
| **CPU** | 2 cores | Compilation is slow; minimize AUR builds. |
| **Disk Space** | ~14 GB usable | ISO builds consume ~10-12 GB; space is critical. |
| **Cache** | 10 GB per repo | Sufficient for pacman package cache. |

### 5.2 Step-by-Step Methodology

#### Step 1: Maximize Build Space
```yaml
- uses: easimon/maximize-build-space@master
  with:
    root-reserve-mb: 512
    swap-size-mb: 1024
    remove-dotnet: 'true'
    remove-android: 'true'
    remove-haskell: 'true'
    remove-codeql: 'true'
    remove-docker-images: 'true'
```
This frees ~30 GB by removing pre-installed GitHub Actions toolchains.

#### Step 2: Pacman Cache Strategy
```yaml
- name: Cache pacman packages
  uses: actions/cache@v4
  with:
    path: /var/cache/pacman/pkg
    key: pacman-${{ hashFiles('archiso/packages.x86_64') }}
    restore-keys: pacman-
```
On subsequent builds, cached packages skip download (~5-10 min savings).

#### Step 3: Staged Build Process
1. **Stage 1 - Bootstrap**: Install archiso, create profile directory structure.
2. **Stage 2 - Package Install**: Install packages from official repos (cached). 
3. **Stage 3 - AUR Helpers**: Build AUR packages in a chroot (only if no pre-built alternatives exist).
4. **Stage 4 - Overlay**: Copy custom configuration files, themes, and branding.
5. **Stage 5 - ISO Generation**: Run `mkarchiso` to produce the final ISO.
6. **Stage 6 - Upload**: Upload ISO as a GitHub Release artifact.

#### Step 4: Disk Space Management
- Clean pacman cache of old versions after install.
- Remove build dependencies after AUR package compilation.
- Strip debug symbols from compiled binaries.
- Use `--nocolor` and `--noconfirm` for non-interactive builds.

#### Step 5: Time Management
- Minimize AUR packages to absolute essentials (Proton-GE is large; consider post-install download).
- Use pre-built binaries where possible (e.g., Chaotic-AUR repo for gaming packages).
- Parallelize where possible (AUR builds can't be parallelized, but overlay copy can).

### 5.3 Chaotic-AUR Integration

To avoid building AUR packages during CI (which is slow and failure-prone), we add the **Chaotic-AUR** repository as a pre-built binary source:

```
[chaotic-aur]
SigLevel = Never
Server = https://cdn-mirror.chaotic.cx/$repo/$arch
```

This provides pre-built binaries for:
- `proton-ge-custom`
- `gamescope`
- `mangohud`
- `wine-tkg`
- And many other gaming packages

This eliminates the need for AUR compilation during CI, saving **2-4 hours** of build time.

### 5.4 Build Time Estimate

| Stage | Duration (first run) | Duration (cached) |
|---|---|---|
| Maximize build space | 2 min | 2 min |
| Install archiso | 3 min | 1 min |
| Package download + install | 20-30 min | 5-10 min |
| AUR/Chaotic-AUR packages | 15-20 min | 5-10 min |
| Overlay copy | 2 min | 2 min |
| ISO generation (squashfs) | 30-45 min | 30-45 min |
| Upload | 5 min | 5 min |
| **Total** | **~80-110 min** | **~50-75 min** |

This is well within the 6-hour limit.

---

## 6. Repository Architecture

### 6.1 Directory Structure

```
aetheros/
├── .github/
│   └── workflows/
│       └── build-iso.yml              # Main CI/CD pipeline
├── archiso/
│   ├── profiledef.sh                  # archiso profile metadata
│   ├── packages.x86_64                # Package list (official repos)
│   ├── packages.aur                   # AUR/Chaotic-AUR package list
│   ├── pacman.conf                    # Custom pacman configuration
│   ├── airootfs/
│   │   ├── etc/
│   │   │   ├── hypr/
│   │   │   │   └── hyprland.conf      # Hyprland window manager config
│   │   │   ├── waybar/
│   │   │   │   ├── config             # Waybar layout config
│   │   │   │   └── style.css          # Waybar CSS styling
│   │   │   ├── calamares/
│   │   │   │   ├── settings.conf      # Calamares main settings
│   │   │   │   ├── modules/           # Calamares module configs
│   │   │   │   │   ├── partition.conf
│   │   │   │   │   ├── users.conf
│   │   │   │   │   ├── welcome.conf
│   │   │   │   │   └── finished.conf
│   │   │   │   └── branding/
│   │   │   │       └── aetheros/      # AetherOS branding for Calamares
│   │   │   ├── systemd/
│   │   │   │   └── system/            # Service enable/disable symlinks
│   │   │   ├── pacman.d/
│   │   │   │   └── chaotic-aur.conf   # Chaotic-AUR repo config
│   │   │   ├── aetheros/
│   │   │   │   ├── aetheros.conf      # AetherOS system configuration
│   │   │   │   └── first-boot.sh      # First-boot setup script
│   │   │   ├── xdg/
│   │   │   │   ├── autostart/         # Autostart entries
│   │   │   │   └── profiles/          # XDG default apps
│   │   │   ├── mkinitcpio.conf        # Custom initramfs config
│   │   │   ├── fstab                  # Filesystem table
│   │   │   └── hostname               # Default hostname
│   │   ├── root/
│   │   │   └── .config/               # Default user configs
│   │   │       ├── hypr/              # User Hyprland config
│   │   │       ├── waybar/            # User Waybar config
│   │   │       ├── Kvantum/           # Kvantum theme config
│   │   │       ├── gtk-3.0/           # GTK3 settings
│   │   │       ├── gtk-4.0/           # GTK4 settings
│   │   │       └── fish/              # Fish shell config
│   │   └── usr/
│   │       ├── share/
│   │       │   ├── themes/            # WhiteSur GTK theme
│   │       │   ├── icons/             # WhiteSur icon theme
│   │       │   ├── applications/      # Custom .desktop files
│   │       │   └── pixmaps/           # AetherOS branding images
│   │       └── local/
│   │           └── bin/               # Custom utility scripts
│   ├── syslinux/
│   │   └── syslinux.cfg               # SYSLINUX bootloader config
│   └── grub/
│       └── grub.cfg                    # GRUB bootloader config
├── scripts/
│   ├── build-local.sh                  # Local build script for testing
│   ├── optimize-system.sh              # System optimization script
│   ├── setup-gaming.sh                 # Gaming stack setup
│   └── first-boot.sh                   # First-boot orchestration
├── overlays/
│   ├── theme/                          # Theme overlay files
│   │   ├── WhitesSur-gtk-theme/       # WhiteSur GTK theme source
│   │   ├── WhiteSur-icon-theme/       # WhiteSur icon theme source
│   │   └── WhiteSur-cursors/          # WhiteSur cursor theme source
│   └── branding/                       # AetherOS branding assets
│       ├── logos/                      # SVG/PNG logos
│       ├── wallpapers/                 # Default wallpapers
│       └── sounds/                     # System sounds (optional)
├── ARCHITECTURE.md                     # This document
├── README.md                           # Project README
├── CONTRIBUTING.md                     # Contribution guidelines
└── LICENSE                             # MIT License
```

### 6.2 Build Pipeline Flow

```
┌─────────────────────────────────────────────────────────────┐
│                   GitHub Actions Runner                      │
│                   (2 vCPU, 7 GB RAM, 14 GB disk)            │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  1. Maximize Build Space (remove pre-installed bloat)        │
│     └── Frees ~30 GB                                         │
│                                                              │
│  2. Install Dependencies (archiso, arch-install-scripts)     │
│     └── Pacman cache restores previous downloads             │
│                                                              │
│  3. Setup Chaotic-AUR Repository                             │
│     └── Add pre-built binary repo for gaming packages        │
│                                                              │
│  4. Build AetherOS Profile                                   │
│     ├── Copy profile files from repo                         │
│     ├── Install packages (pacman + Chaotic-AUR)              │
│     ├── Apply overlays (themes, configs, branding)           │
│     └── Run post-install scripts                             │
│                                                              │
│  5. Generate ISO (mkarchiso)                                 │
│     ├── Create squashfs (compressed root filesystem)         │
│     ├── Generate bootable ISO with GRUB + SYSLINUX           │
│     └── Embed AetherOS branding in bootloader                │
│                                                              │
│  6. Upload to GitHub Releases                                │
│     └── Tagged release with ISO checksums                    │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 7. Installer Strategy (Calamares)

### 7.1 Design Philosophy

Windows migrants expect:
1. A graphical installer that "just works"
2. Automatic partitioning (no manual disk management)
3. User account creation with a familiar interface
4. A system that boots into a ready-to-use desktop

### 7.2 Calamares Configuration

- **Partition Module**: Pre-configured with "Erase Disk" as the default option. Includes "Alongside Windows" for dual-boot scenarios.
- **Users Module**: Simplified user creation (username, password, hostname). No complex options.
- **Welcome Module**: AetherOS branding, language selection.
- **Package Selection**: Optional "Gaming" and "Productivity" meta-packages.
- **Finished Module**: Reboot prompt with AetherOS branding.

### 7.3 Post-Install

On first boot, `aetheros-first-boot.service` runs:
1. Detect and install GPU drivers (NVIDIA proprietary or Mesa).
2. Set up Flatpak repository.
3. Configure bauh for the app store.
4. Apply display scaling based on screen resolution.
5. Enable gamemode for gaming optimization.

---

## 8. Aesthetic Design Specification

### 8.1 Visual Design Language

AetherOS follows a **"Aether"** design language inspired by the ethereal quality of light:
- **Glass-morphism**: Translucent panels with kawase blur (Hyprland native).
- **Rounded Corners**: 12px border radius on all windows and popups.
- **Subtle Animations**: Fade-in (300ms), slide-in (250ms), workspace switch (smooth).
- **Color Palette**: Deep navy (#0a0a1a) base, accent blue (#4fc3f7), soft white (#e0e0e0) text.
- **Transparency**: Active windows 95% opacity, inactive 85%, terminal 80%.

### 8.2 Hyprland Configuration Highlights

```hyprlang
# Decoration
decoration {
    rounding = 12
    blur {
        enabled = yes
        size = 3
        passes = 2
        new_optimizations = on
        xray = on
    }
    drop_shadow = yes
    shadow_range = 15
    shadow_render_power = 2
    col.shadow = 0x4d000000
}

# Animations
animations {
    enabled = yes
    bezier = myBezier, 0.05, 0.9, 0.1, 1.05
    animation = windows, 1, 7, myBezier
    animation = windowsOut, 1, 7, default, popin 87%
    animation = border, 1, 10, default
    animation = fade, 1, 7, default
    animation = workspaces, 1, 6, default
}
```

### 8.3 Waybar Design

A macOS-inspired bar with:
- **Left**: AetherOS logo + workspace indicator
- **Center**: Active window title
- **Right**: System tray, volume, network, battery, clock
- **Styling**: Translucent background with blur, rounded corners, Inter font

---

## 9. Risk Assessment

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| 200MB RAM target exceeded | Medium | High | Aggressive service stripping, zram swap, RAM budget monitoring |
| GitHub Actions disk exhaustion | Medium | High | maximize-build-space action, cache cleanup, squashfs compression |
| Hyprland Wayland compatibility issues | Low-Medium | Medium | XWayland fallback, tested app compatibility list |
| Chaotic-AUR repo unavailability | Low | High | Fallback to official repos, documented AUR build path |
| NVIDIA driver compatibility | Medium | Medium | Auto-detect script, hybrid driver support |
| Calamares partition failures | Low | High | Pre-tested partition profiles, fallback to manual partitioning |

---

## 10. Success Metrics

| Metric | Target | Measurement |
|---|---|---|
| Idle RAM | < 200 MB | `free -m` on fresh boot |
| Idle CPU | < 2% | `top` on fresh boot |
| ISO Size | < 2.5 GB | File size of built ISO |
| Build Time (cached) | < 75 min | GitHub Actions duration |
| First Boot to Desktop | < 30 sec | Timed from GRUB to Hyprland |
| Calamares Install Time | < 10 min | Timed from launch to reboot |
| Steam Launch | Functional | Steam runs, Proton games launch |
| App Store (bauh) | Functional | Flatpak, AppImage, native packages manageable |

---

## 11. Future Roadmap

1. **v0.1 (MVP)**: Bootable ISO with Hyprland, Calamares, bauh, basic theming.
2. **v0.2**: Gaming stack (Steam, Proton-GE, gamescope), full WhiteSur theme.
3. **v0.3**: NVIDIA hybrid graphics support, auto-detect drivers.
4. **v1.0**: Stable release with full documentation, Windows migration guide.

---

*This architecture document serves as the strategic foundation for AetherOS development. All implementation decisions must align with the three pillars: Ultra-Light Architecture, Modern Aesthetics, and Ultimate Ease of Use.*
