#!/usr/bin/env bash

set -euo pipefail

TITLE="Waybar Calendar"
PID_FILE="${XDG_RUNTIME_DIR:-/tmp}/waybar-calendar-popup.pid"
THEME="${XDG_CONFIG_HOME:-$HOME/.config}/rofi/calendar.rasi"

ensure_rofi() {
  if ! command -v rofi >/dev/null 2>&1; then
    echo "rofi is required for the calendar popup" >&2
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
  ensure_rofi

  local pid
  pid="$(read_pid || true)"
  clear_stale_pid "$pid"

  if [[ -f "$PID_FILE" ]]; then
    return
  fi

  run_calendar >/dev/null 2>&1 &
}

print_calendar() {
  local month_start="$1"
  local today_month today_day title first_weekday days day week weekday row cell empty_row

  today_month="$(date '+%Y-%m-01')"
  today_day="$(date '+%-d')"
  title="$(date -d "$month_start" '+%B %Y')"
  first_weekday="$(date -d "$month_start" '+%u')"
  days="$(date -d "$month_start +1 month -1 day" '+%-d')"

  printf '<span foreground="#ff7ad9"><b>%s</b></span>\n' "$(date '+%A, %d %B %Y')"
  printf '<span foreground="#74eaff"><b>%s</b></span>\n\n' "$title"
  printf '<span foreground="#9f7bff"><b>Mo&#160;Tu&#160;We&#160;Th&#160;Fr&#160;Sa&#160;Su</b></span>\n'

  day=1
  empty_row="&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;"

  for ((week = 0; week < 6; week++)); do
    row=""

    for ((weekday = 1; weekday <= 7; weekday++)); do
      if (( (week == 0 && weekday < first_weekday) || day > days )); then
        cell="&#160;&#160;"
      else
        cell="$(format_calendar_day "$day" "$month_start" "$today_month" "$today_day")"
        day=$((day + 1))
      fi

      if [[ -z "$row" ]]; then
        row="$cell"
      else
        row+="&#160;$cell"
      fi
    done

    [[ "$row" == "$empty_row" ]] && break
    printf '%s\n' "$row"
  done
}

format_calendar_day() {
  local day="$1"
  local month_start="$2"
  local today_month="$3"
  local today_day="$4"
  local cell

  if (( day < 10 )); then
    cell="&#160;$day"
  else
    cell="$day"
  fi

  if [[ "$month_start" == "$today_month" && "$day" == "$today_day" ]]; then
    cell="<span foreground=\"#140c22\" background=\"#74eaff\"><b>$cell</b></span>"
  fi

  printf '%s\n' "$cell"
}

print_actions() {
  printf 'Prev\n'
  printf 'Today\n'
  printf 'Next\n'
}

run_calendar() {
  local message month_start rofi_pid selection tmp
  month_start="$(date '+%Y-%m-01')"

  trap 'rm -f "$PID_FILE" "${tmp:-}"' EXIT

  while true; do
    tmp="$(mktemp)"
    message="$(print_calendar "$month_start")"

    print_actions |
      rofi -dmenu -no-custom -p "$TITLE" -mesg "$message" -theme "$THEME" \
        -me-select-entry "" -me-accept-entry MousePrimary >"$tmp" &

    rofi_pid="$!"
    printf '%s\n' "$rofi_pid" >"$PID_FILE"

    wait "$rofi_pid" || break
    selection="$(<"$tmp")"
    rm -f "$tmp"

    case "$selection" in
      "Prev")
        month_start="$(date -d "$month_start -1 month" '+%Y-%m-01')"
        ;;
      "Today")
        month_start="$(date '+%Y-%m-01')"
        ;;
      "Next")
        month_start="$(date -d "$month_start +1 month" '+%Y-%m-01')"
        ;;
      *)
        break
        ;;
    esac
  done
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
