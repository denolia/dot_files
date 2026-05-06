#!/usr/bin/env bash

set -euo pipefail

print_status() {
  printf '{"text":"PWR","tooltip":"Power menu"}\n'
}

show_menu() {
  local selection

  selection="$(
    printf '%s\n' "Sleep" "Power off" "Log out" |
      rofi -dmenu -i -p "Power"
  )" || exit 0

  case "$selection" in
    "Sleep")
      systemctl suspend
      ;;
    "Power off")
      systemctl poweroff
      ;;
    "Log out")
      swaymsg exit
      ;;
    *)
      exit 0
      ;;
  esac
}

case "${1:-status}" in
  status)
    print_status
    ;;
  menu)
    show_menu
    ;;
  *)
    echo "Usage: $0 [status|menu]" >&2
    exit 1
    ;;
esac
