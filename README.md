# MacTahoe GDM Theme (Fedora MacTahoe Edition)

A stripped-down, standalone GDM theme engine containing only the files needed to apply a macOS-style login screen background — no GTK, no Firefox, no dock themes.

🌐 **[fedoratahoe.pages.dev](https://fedoratahoe.pages.dev/)**

## Requirements

This repository is designed to work with **[Fedora MacTahoe — Eprahemi Edition](https://github.com/eprahemi/Fedora-MacTahoe-Eprahemi)**, which provides the full desktop transformation suite:

- `install.sh` — One‑click Fedora macOS transformation (23 steps)
- `bootstrap.sh` — Dependency bootstrap for a clean Fedora install
- `gdm.fish` — Fish shell function for persistent GDM wallpaper switching with:
  - System‑wide image search (8 user directories, fully recursive)
  - Interactive multi‑match picker with Kitty preview
  - ImageMagick blur/tint with custom blur retry loop
  - `gdm current` — Detect and apply current desktop wallpaper to GDM
  - `gdm default` — ✧ summon the waifu Himeno-chan wallpaper appears! ✧ (ﾉ◕ヮ◕)
  - `gdm info` — 12‑field metadata display (format, dimensions, blur, source, etc.)
  - `gdm save` — Save the current GDM wallpaper to `~/Pictures/` with a 16‑char encrypted name
  - JPEG auto‑conversion, 21‑format image guard, empty‑file guard, and more

## How It Works

When you use `gdm.fish` from Fedora MacTahoe, it:

1. Clones or updates this repo to `~/.local/share/mactahoe-gdm/`
2. Calls `gdm-wallpaper.sh -g -nb -nd -b "<your-wallpaper>"` 
3. `gdm-wallpaper.sh` compiles the GDM theme with your image into a `.gresource` file
4. The new GDM theme takes effect on the next login/reboot

Everything is automatic — no manual intervention needed.

## Quick Start

```bash
# 1. Install Fedora MacTahoe (includes gdm.fish automatically)
git clone https://github.com/eprahemi/Fedora-MacTahoe-Eprahemi.git
cd Fedora-MacTahoe-Eprahemi
./install.sh

# 2. Clone this repo (or let gdm.fish do it on first run)
git clone https://github.com/eprahemi/FedoraTahoe-GDM.git ~/.local/share/mactahoe-gdm

# 3. Set your GDM wallpaper
gdm /path/to/your/wallpaper.jpg
```

## What's Included

| Path | Purpose |
|---|---|
| `gdm-wallpaper.sh` | GDM theme compiler (entry point) |
| `libs/` | Theme installation library (core, install) |
| `other/gdm/theme/` | Pre‑compiled MacTahoe GNOME Shell CSS and assets |
| `other/gdm/gnome-shell-theme.gresource.xml` | GResource manifest |
| `himeno-login.jpg` | Default wallpaper fallback |

**~1 MB total** — 95% smaller than the full MacTahoe theme.

Use the [full Fedora MacTahoe repo](https://github.com/eprahemi/Fedora-MacTahoe-Eprahemi) if you want the complete macOS desktop transformation.

## License

Licensed under the GPL v2.0.
