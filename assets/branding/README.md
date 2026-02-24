# Cortex Branding Assets

This folder contains official Cortex branding assets for use across all Cortex projects.

## Directory Structure

```
branding/
├── icons/              # App icons (all sizes)
├── favicons/           # Web favicons
└── pwa/                # Progressive Web App icons
```

## Icons (`icons/`)

| File | Size | Purpose |
|------|------|---------|
| `cortex-icon-1024.png` | 1024x1024 | Master source (use for generating new sizes) |
| `cortex-icon-512.png` | 512x512 | Large app icon, app stores |
| `cortex-icon-256.png` | 256x256 | Large app icon |
| `cortex-icon-128.png` | 128x128 | Medium app icon |
| `cortex-icon-64.png` | 64x64 | Standard app icon |
| `cortex-icon-48.png` | 48x48 | Medium-small icon |
| `cortex-icon-44.png` | 44x44 | Small UI icon (2x retina) |
| `cortex-icon-32.png` | 32x32 | Small app icon |
| `cortex-icon-22.png` | 22x22 | Small UI icon (1x) |
| `cortex-icon-16.png` | 16x16 | Tiny icon |
| `Cortex.icns` | Multi-size | macOS app icon bundle (16-1024px) |
| `cortex-windows.ico` | Multi-size | Windows app icon (16-256px) |
| `MenuBarIcon.png` | 18x18 | macOS menu bar template (1x) |
| `MenuBarIcon@2x.png` | 36x36 | macOS menu bar template (2x) |

## Favicons (`favicons/`)

| File | Size | Purpose |
|------|------|---------|
| `favicon.ico` | 16,32,48 | Multi-resolution favicon for browsers |
| `favicon-32.png` | 32x32 | Modern browser favicon |
| `apple-touch-icon.png` | 180x180 | iOS "Add to Home Screen" |

## PWA Icons (`pwa/`)

| File | Size | Purpose |
|------|------|---------|
| `pwa-192.png` | 192x192 | PWA manifest icon |
| `pwa-512.png` | 512x512 | PWA splash screen |

## Menu Bar Icons

The `MenuBarIcon*.png` files are **template images** (black + alpha). macOS automatically tints them for light/dark mode. Use these for system tray / menu bar icons.

## Full Color Icons

The `cortex-icon-*.png` files are full color (blue/purple gradient). Use these for:
- App icons
- In-app UI headers
- Documentation
- Marketing materials

## Color Palette

Primary colors from the icon:
- Blue: RGB(2, 137, 255)
- Purple highlights in gradient

## Generating New Sizes

From the 1024px master:

```python
from PIL import Image

img = Image.open("icons/cortex-icon-1024.png")
new_size = img.resize((SIZE, SIZE), Image.Resampling.LANCZOS)
new_size.save(f"cortex-icon-{SIZE}.png")
```

## HTML Favicon Setup

```html
<link rel="icon" href="/favicons/favicon.ico" sizes="any">
<link rel="icon" href="/favicons/favicon-32.png" type="image/png">
<link rel="apple-touch-icon" href="/favicons/apple-touch-icon.png">
```

## PWA Manifest

```json
{
  "icons": [
    { "src": "/pwa/pwa-192.png", "sizes": "192x192", "type": "image/png" },
    { "src": "/pwa/pwa-512.png", "sizes": "512x512", "type": "image/png" }
  ]
}
```
