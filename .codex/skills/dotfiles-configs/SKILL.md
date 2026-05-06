---
name: dotfiles-configs
description: Use when working in this repo on Sway, SwayFX, Waybar, portal, launcher, power-menu, or related desktop-config changes. This skill captures that the repo is the source of truth, live configs are populated via ./install-configs.sh, features should stay isolated and modular, and Waybar/Sway debugging should account for the repo-to-~/.config install step.
---

# Dotfiles Configs

This repo is the source of truth for the desktop config. Do not treat files under `~/.config` as canonical.

## Core workflow

1. Edit repo files first.
2. Push changes into the live config with `./install-configs.sh`.
3. Reload or restart the smallest relevant runtime component.
4. Only inspect `~/.config/...` when debugging what is actually installed or currently running.

If the user reports that the running system does not match the repo, assume the install step was skipped until proven otherwise.

## File mapping

The repo layout is intentionally flatter than the installed layout.

- `sway.conf` -> `~/.config/sway/config`
- `scripts/sway-session-init.sh` -> `~/.config/sway/scripts/session-init.sh`
- `config.jsonc` -> `~/.config/waybar/config.jsonc`
- `style.css` -> `~/.config/waybar/style.css`
- `scripts/audio-device.sh` -> `~/.config/waybar/scripts/audio-device.sh`
- `scripts/power-menu.sh` -> `~/.config/waybar/scripts/power-menu.sh`
- `xdg-desktop-portal/sway-portals.conf` -> `~/.config/xdg-desktop-portal/sway-portals.conf`

`./install-configs.sh` is the supported propagation path. It also removes `~/.local/share/applications/webstorm.desktop` if present.

## Modularity rules

Keep every feature as isolated as possible.

- New Waybar behavior should usually be split into:
  one `config.jsonc` module entry,
  one `style.css` block,
  and one dedicated helper script in `scripts/` if logic is non-trivial.
- New Sway runtime behavior should prefer a dedicated helper script plus one `exec` or `bindsym` entry, not a large inline shell fragment.
- Avoid bundling unrelated changes across `sway.conf`, `config.jsonc`, `style.css`, and multiple scripts in one feature unless the feature truly spans them.
- Prefer extending existing dedicated scripts such as `power-menu.sh` or `audio-device.sh` over adding one-off inline commands everywhere.

## Repo-specific learnings

- This setup is Sway-oriented but uses SwayFX-specific appearance directives in `sway.conf` such as blur, shadows, corner radius, and `layer_effects`. Do not assume plain upstream Sway compatibility for every directive.
- The app launcher is currently `rofi` via `set $menu rofi -show drun`.
- Waybar is restarted through Sway reloads by:
  `exec_always --no-startup-id sh -c 'pkill waybar 2>/dev/null; waybar'`
- Portal/session environment setup is handled by `scripts/sway-session-init.sh`, but that script runs through `exec`, not `exec_always`. It executes once per session, not on every `swaymsg reload`.
- Because of that, `swaymsg reload` is usually safe for normal config edits and should restart Waybar, but it should not be expected to rerun the portal bootstrap logic.
- The repo README is useful context but not the runtime truth. For live behavior, inspect the installed files under `~/.config` and run the relevant process in the foreground.

## Waybar-specific cautions

- Waybar uses GTK CSS semantics, not browser CSS semantics. Do not assume all normal web CSS works.
- A CSS parse failure can prevent Waybar from starting at all.
- In this repo, 8-digit hex colors inside `linear-gradient(...)` caused Waybar startup failure with `Unit is missing`. Prefer `rgba(...)` for translucent gradient stops.
- Validate JSON separately from CSS. A valid `config.jsonc` does not prove Waybar will launch.
- The bar config currently asks for `height: 32`, but Waybar may increase it if modules require more space. That warning is non-fatal.
- Tray warnings like missing icon names are usually non-fatal and are often caused by the tray client, not by Waybar config.

## Current notable behavior

- The power button is a custom Waybar module backed by `scripts/power-menu.sh`.
- The clock tooltip is configured to render a calendar, with right-click mode switching and scroll month navigation.
- The audio output selector is a custom Waybar module backed by `scripts/audio-device.sh`.
- Workspace visuals live in `style.css`; any “animation” there is limited by Waybar/GTK button rendering and is not equivalent to a compositor-level moving indicator.

## Validation and debugging

For config work, prefer this order:

1. `jq . config.jsonc`
2. `git diff --check`
3. `./install-configs.sh`
4. `swaymsg reload`

If Waybar does not appear, debug the installed copy directly:

1. Inspect `~/.config/waybar/config.jsonc` and `~/.config/waybar/style.css`
2. Run `waybar -c ~/.config/waybar/config.jsonc -s ~/.config/waybar/style.css -l trace`
3. Fix startup errors in the repo copy
4. Re-run `./install-configs.sh`
5. Reload Sway again

If the behavior mismatch is specifically about runtime state, check whether the user edited the repo, the installed copy, or both.

## Change discipline

- Keep README notes in sync when a user-visible feature or required package changes.
- Prefer small, reviewable patches with one feature or one bugfix per change.
- When adding a feature, document the minimal set of files that own it so future edits do not sprawl.
