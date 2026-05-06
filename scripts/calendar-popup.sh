#!/usr/bin/env bash

set -euo pipefail

TITLE="Waybar Calendar"
PID_FILE="${XDG_RUNTIME_DIR:-/tmp}/waybar-calendar-popup.pid"

ensure_zenity() {
  if ! command -v zenity >/dev/null 2>&1; then
    echo "zenity is required for the calendar popup" >&2
    exit 1
  fi
}

read_pid() {
  [[ -f "$PID_FILE" ]] || return 1
  local pid
  pid="$(<"$PID_FILE")"
  [[ -n "$pid" ]] || return 1
  printf '%s\n' "$pid"
}

clear_stale_pid() {
  local pid="${1:-}"
  if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
    return
  fi

  rm -f "$PID_FILE"
}

open_calendar() {
  ensure_zenity

  local pid
  pid="$(read_pid || true)"
  clear_stale_pid "$pid"

  if [[ -f "$PID_FILE" ]]; then
    return
  fi

  zenity \
    --calendar \
    --title="$TITLE" \
    --text="$(date '+%A, %d %B %Y')" \
    --day="$(date '+%d')" \
    --month="$(date '+%m')" \
    --year="$(date '+%Y')" \
    --width=320 \
    --height=260 \
    --ok-label="Close" \
    >/dev/null 2>&1 &

  printf '%s\n' "$!" > "$PID_FILE"
}

close_calendar() {
  local pid
  pid="$(read_pid || true)"

  if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
    kill "$pid" 2>/dev/null || true
  fi

  rm -f "$PID_FILE"
}

toggle_calendar() {
  local pid
  pid="$(read_pid || true)"

  if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
    close_calendar
    return
  fi

  rm -f "$PID_FILE"
  open_calendar
}

case "${1:-toggle}" in
  open)
    open_calendar
    ;;
  close)
    close_calendar
    ;;
  toggle)
    toggle_calendar
    ;;
  *)
    echo "Usage: $0 [open|close|toggle]" >&2
    exit 1
    ;;
esac
