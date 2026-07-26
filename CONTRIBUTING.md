# Contributing to AetherOS

Thank you for your interest in contributing to AetherOS! This document provides guidelines for contributing to the project.

## How to Contribute

### Reporting Bugs
1. Check existing issues to avoid duplicates
2. Open a new issue with:
   - Clear title and description
   - Steps to reproduce
   - Expected vs actual behavior
   - System information (RAM usage, GPU, etc.)

### Suggesting Features
1. Open an issue with the "feature" label
2. Describe the feature and how it aligns with AetherOS pillars
3. Consider RAM impact (must stay under 200MB idle target)

### Submitting Code
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Make your changes
4. Test locally if possible
5. Submit a pull request with:
   - Clear description of changes
   - RAM usage impact assessment
   - Testing notes

## Development Guidelines

### RAM Budget Rule
Every change must be evaluated against the 200MB idle RAM target. If a change increases RAM usage:
- Document the increase
- Provide justification
- Suggest mitigations

### Package Selection Criteria
Before adding a package to `packages.x86_64`, verify:
1. It doesn't exceed RAM budget
2. It's available in official Arch repos or Chaotic-AUR
3. It serves a clear purpose for one of the three pillars

### Configuration Standards
- Hyprland configs follow the official Hyprland wiki conventions
- Waybar configs use CSS styling consistent with the Aether design language
- Systemd services must be explicitly enabled or disabled with rationale

## Testing

### Local Build Testing
```bash
sudo mkarchiso -v -w /tmp/aetheros-work -o /tmp/aetheros-out archiso/
```

### RAM Usage Testing
After booting the ISO (in VM or live):
```bash
aetheros-ram-monitor
```
Verify idle RAM is under 200MB.

## Code Review Process
1. All PRs require review
2. RAM impact assessment is mandatory
3. Changes to `packages.x86_64` require explicit approval
4. Theme changes must maintain design language consistency

Thank you for helping make AetherOS better!
