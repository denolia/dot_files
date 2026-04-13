#!/usr/bin/env bash

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
APPLICATIONS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"

install_file() {
  local source="$1"
  local target="$2"
  local mode="$3"

  install -Dm"$mode" "$source" "$target"
  printf 'Installed %s -> %s\n' "$source" "$target"
}

install_file "$REPO_DIR/sway.conf" "$CONFIG_DIR/sway/config" 644
install_file "$REPO_DIR/scripts/sway-session-init.sh" "$CONFIG_DIR/sway/scripts/session-init.sh" 755
install_file "$REPO_DIR/config.jsonc" "$CONFIG_DIR/waybar/config.jsonc" 644
install_file "$REPO_DIR/style.css" "$CONFIG_DIR/waybar/style.css" 644
install_file "$REPO_DIR/scripts/audio-device.sh" "$CONFIG_DIR/waybar/scripts/audio-device.sh" 755
install_file "$REPO_DIR/xdg-desktop-portal/sway-portals.conf" "$CONFIG_DIR/xdg-desktop-portal/sway-portals.conf" 644

if [[ -f "$APPLICATIONS_DIR/webstorm.desktop" ]]; then
  rm -f "$APPLICATIONS_DIR/webstorm.desktop"
  printf 'Removed %s\n' "$APPLICATIONS_DIR/webstorm.desktop"
fi
