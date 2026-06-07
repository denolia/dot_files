#!/usr/bin/env bash

set -euo pipefail

if [[ -z "${XDG_DATA_DIRS:-}" ]]; then
  XDG_DATA_DIRS="/usr/local/share:/usr/share"
fi

append_data_dir() {
  local dir="$1"

  if [[ -d "$dir" && ":${XDG_DATA_DIRS:-}:" != *":$dir:"* ]]; then
    XDG_DATA_DIRS="${XDG_DATA_DIRS:+$XDG_DATA_DIRS:}$dir"
  fi
}

append_data_dir "${XDG_DATA_HOME:-$HOME/.local/share}/flatpak/exports/share"
append_data_dir /var/lib/flatpak/exports/share

export XDG_DATA_DIRS
exec rofi -show drun -i "$@"
