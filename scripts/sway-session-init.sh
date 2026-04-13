#!/usr/bin/env bash

set -euo pipefail

# Sync the active Sway session into systemd/D-Bus once per login so
# portal-activated helpers inherit the correct compositor environment.
systemctl --user import-environment \
  WAYLAND_DISPLAY \
  SWAYSOCK \
  XDG_CURRENT_DESKTOP \
  XDG_SESSION_TYPE

if [[ -n "${DISPLAY:-}" ]]; then
  systemctl --user import-environment DISPLAY
fi

systemctl --user set-environment GDK_BACKEND=wayland,x11

dbus_update_args=(
  WAYLAND_DISPLAY
  SWAYSOCK
  XDG_CURRENT_DESKTOP="${XDG_CURRENT_DESKTOP:-sway}"
  XDG_SESSION_TYPE="${XDG_SESSION_TYPE:-wayland}"
  GDK_BACKEND=wayland,x11
)

if [[ -n "${DISPLAY:-}" ]]; then
  dbus_update_args+=(DISPLAY="${DISPLAY}")
fi

dbus-update-activation-environment --systemd "${dbus_update_args[@]}"

systemctl --user reset-failed \
  xdg-desktop-portal.service \
  xdg-desktop-portal-gtk.service \
  xdg-desktop-portal-wlr.service \
  swaync.service >/dev/null 2>&1 || true

systemctl --user restart \
  xdg-desktop-portal-gtk.service \
  xdg-desktop-portal-wlr.service \
  xdg-desktop-portal.service

# Optional notification daemon. Keep startup best-effort so missing units do not
# break the Sway session.
systemctl --user start swaync.service >/dev/null 2>&1 || true
