#!/usr/bin/env python3
"""
Generate AetherOS branding assets - wallpaper and logo.
Creates SVG-based wallpaper with the Aether design language.
"""

import os
import struct
import math
import zlib

OUTPUT_DIR = "/home/z/my-project/aetheros-build/overlays/branding"
WALLPAPER_OUTPUT = "/home/z/my-project/aetheros-build/archiso/airootfs/usr/share/pixmaps"

os.makedirs(OUTPUT_DIR, exist_ok=True)
os.makedirs(os.path.join(OUTPUT_DIR, "logos"), exist_ok=True)
os.makedirs(os.path.join(OUTPUT_DIR, "wallpapers"), exist_ok=True)
os.makedirs(WALLPAPER_OUTPUT, exist_ok=True)

# ── Generate AetherOS Logo SVG ──────────────────────────────────
logo_svg = '''<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
  <!-- Background -->
  <rect width="512" height="512" rx="80" fill="#0a0a1a"/>
  
  <!-- Aether Symbol - A diamond/gem shape representing the "aether" concept -->
  <!-- Outer glow -->
  <filter id="glow">
    <feGaussianBlur stdDeviation="8" result="coloredBlur"/>
    <feMerge>
      <feMergeNode in="coloredBlur"/>
      <feMergeNode in="SourceGraphic"/>
    </feMerge>
  </filter>
  
  <!-- Main diamond -->
  <polygon points="256,80 420,256 256,432 92,256" 
           fill="none" stroke="#4fc3f7" stroke-width="4" filter="url(#glow)"/>
  
  <!-- Inner diamond -->
  <polygon points="256,140 370,256 256,372 142,256" 
           fill="rgba(79,195,247,0.15)" stroke="#4fc3f7" stroke-width="2"/>
  
  <!-- Center star -->
  <circle cx="256" cy="256" r="20" fill="#4fc3f7" filter="url(#glow)"/>
  
  <!-- Radiating lines -->
  <line x1="256" y1="256" x2="256" y2="80" stroke="#4fc3f7" stroke-width="1" opacity="0.5"/>
  <line x1="256" y1="256" x2="420" y2="256" stroke="#4fc3f7" stroke-width="1" opacity="0.5"/>
  <line x1="256" y1="256" x2="256" y2="432" stroke="#4fc3f7" stroke-width="1" opacity="0.5"/>
  <line x1="256" y1="256" x2="92" y2="256" stroke="#4fc3f7" stroke-width="1" opacity="0.5"/>
  
  <!-- Text -->
  <text x="256" y="490" text-anchor="middle" font-family="Inter, sans-serif" 
        font-size="24" font-weight="600" fill="#4fc3f7">AetherOS</text>
</svg>'''

with open(os.path.join(OUTPUT_DIR, "logos", "aetheros-logo.svg"), "w") as f:
    f.write(logo_svg)

with open(os.path.join(WALLPAPER_OUTPUT, "aetheros-logo.svg"), "w") as f:
    f.write(logo_svg)

# ── Generate AetherOS Icon SVG ──────────────────────────────────
icon_svg = '''<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="64" height="64">
  <rect width="64" height="64" rx="12" fill="#0a0a1a"/>
  <polygon points="32,12 52,32 32,52 12,32" 
           fill="none" stroke="#4fc3f7" stroke-width="2"/>
  <circle cx="32" cy="32" r="4" fill="#4fc3f7"/>
</svg>'''

with open(os.path.join(OUTPUT_DIR, "logos", "aetheros-icon.svg"), "w") as f:
    f.write(icon_svg)

with open(os.path.join(WALLPAPER_OUTPUT, "aetheros-icon.svg"), "w") as f:
    f.write(icon_svg)

# ── Generate AetherOS Wallpaper PNG ─────────────────────────────
def crc32(data):
    return zlib.crc32(data) & 0xFFFFFFFF

def make_chunk(chunk_type, data):
    chunk = chunk_type + data
    crc = struct.pack('>I', crc32(chunk))
    return struct.pack('>I', len(data)) + chunk + crc

def create_png(width, height, filename):
    """Create a gradient PNG wallpaper for AetherOS."""
    signature = b'\x89PNG\r\n\x1a\n'
    
    # IHDR chunk
    ihdr_data = struct.pack('>IIBBBBB', width, height, 8, 2, 0, 0, 0)
    ihdr = make_chunk(b'IHDR', ihdr_data)
    
    # IDAT chunk - create gradient image data
    raw_data = b''
    for y in range(height):
        raw_data += b'\x00'  # Filter: None
        for x in range(width):
            t = y / height
            xt = x / width
            
            # Background gradient (vertical) - deep navy to subtle accent
            r = int(10 + (79 - 10) * t * 0.3 * math.sin(xt * 3.14))
            g = int(10 + (195 - 10) * t * 0.15 * math.sin(xt * 2))
            b_val = int(26 + (247 - 26) * t * 0.2)
            
            r = max(0, min(255, r))
            g = max(0, min(255, g))
            b_val = max(0, min(255, b_val))
            
            raw_data += struct.pack('BBB', r, g, b_val)
    
    compressed = zlib.compress(raw_data)
    idat = make_chunk(b'IDAT', compressed)
    
    iend = make_chunk(b'IEND', b'')
    
    with open(filename, 'wb') as f:
        f.write(signature + ihdr + idat + iend)

print("Generating AetherOS wallpaper...")
create_png(960, 540, os.path.join(WALLPAPER_OUTPUT, "aetheros-wallpaper.png"))
create_png(960, 540, os.path.join(OUTPUT_DIR, "wallpapers", "aetheros-wallpaper.png"))

print(f"Assets generated in: {OUTPUT_DIR}")
print(f"Wallpaper generated in: {WALLPAPER_OUTPUT}")
print("Done!")
