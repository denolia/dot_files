## About

Collection of configs and scripts for my setup

Currently, uses Sway with configs and shortcuts migrated from my previous Hyprland setup.

## Files

- `sway.conf`: main Sway config, installed as `~/.config/sway/config`
- `config.jsonc`: Waybar config
- `scripts/audio-device.sh`: Waybar helper for switching audio outputs
- `xdg-desktop-portal/sway-portals.conf`: portal backend preferences for Sway
- `SWAY-CHEATSHEET.md`: shortcut reference for the current Sway config

## Install

```bash
./install-configs.sh
```

Then either:

- log out and start a `sway` session again, or
- run `swaymsg reload`

## Required Packages

- `sway`
- `waybar`
- `rofi`
- `alacritty`
- `nautilus`
- `grim`
- `slurp`
- `wl-clipboard`
- `brightnessctl`
- `playerctl`
- `xdg-desktop-portal`
- `xdg-desktop-portal-gtk`
- `xdg-desktop-portal-wlr`

## Notes

- The config preserves the previous Hyprland shortcuts as closely as plain Sway allows.
- Plain Sway does not provide Hyprland animations, blur, rounded corners, or dwindle pseudotiling.
- The Sway startup config exports the correct Wayland environment into user systemd so Waybar, portals, and GTK apps start without portal timeouts.
- The portal setup is intentional:
  `xdg-desktop-portal` provides the main portal service,
  `xdg-desktop-portal-gtk` handles generic desktop portals used by GTK apps,
  and `xdg-desktop-portal-wlr` handles Wayland screenshot and screencast on Sway.
- Shortcut reference: see `SWAY-CHEATSHEET.md`.
- SwayFX can be installed side by side with distro Sway. In this setup:
  plain Sway remains available as the `Sway` session,
  and SwayFX is available as a separate `SwayFX` session.
- Rolling back from SwayFX is simple: choose the normal `Sway` session again at login.
