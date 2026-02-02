# Cortex Branding Assets

This folder contains official Cortex branding assets for use across all Cortex projects.

## Icons

| File | Size | Purpose |
|------|------|---------|
| `cortex-icon-original.png` | 1024x1024 | Original source icon (may have extra padding) |
| `cortex-icon-1024.png` | 1024x1024 | Processed icon (trimmed, centered, contrast-enhanced) |
| `Cortex.icns` | Multi-size | macOS app icon bundle (16-1024px) |
| `cortex-icon-22.png` | 22x22 | Small UI icon (1x) |
| `cortex-icon-44.png` | 44x44 | Small UI icon (2x retina) |
| `MenuBarIcon.png` | 18x18 | macOS menu bar template (1x) |
| `MenuBarIcon@2x.png` | 36x36 | macOS menu bar template (2x) |

## Menu Bar Icons

The `MenuBarIcon*.png` files are **template images** (black + alpha). macOS automatically tints them for light/dark mode. Use these for system tray / menu bar icons.

## Full Color Icons

The `cortex-icon-*.png` files are full color (blue/purple). Use these for:
- App icons
- In-app UI headers
- Documentation
- Marketing materials

## Generating New Sizes

From the 1024px source:

```python
from PIL import Image

img = Image.open("cortex-icon-1024.png")
new_size = img.resize((SIZE, SIZE), Image.Resampling.LANCZOS)
new_size.save(f"cortex-icon-{SIZE}.png")
```

## Color Palette

Primary colors from the icon:
- Blue: RGB(2, 137, 255)
- Purple highlights in gradient
