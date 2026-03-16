#!/usr/bin/env bash

set -euo pipefail

SIGNAL="${WAYBAR_SIGNAL:-8}"
BACKEND=""

detect_backend() {
  if command -v pactl >/dev/null 2>&1; then
    BACKEND="pactl"
    return
  fi

  if command -v wpctl >/dev/null 2>&1; then
    BACKEND="wpctl"
    return
  fi

  echo "No supported audio control backend found" >&2
  exit 1
}

get_default_sink() {
  case "$BACKEND" in
    pactl)
      pactl get-default-sink
      ;;
    wpctl)
      wpctl status | awk '
        /Sinks:/ { in_sinks = 1; next }
        in_sinks && /Sink endpoints:/ { exit }
        in_sinks && /\*/ {
          if (match($0, /[0-9]+\./)) {
            id = substr($0, RSTART, RLENGTH - 1)
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", id)
            print id
            exit
          }
        }
      '
      ;;
  esac
}

list_sinks() {
  case "$BACKEND" in
    pactl)
      pactl list short sinks | awk '{ print $2 }'
      ;;
    wpctl)
      wpctl status | awk '
        /Sinks:/ { in_sinks = 1; next }
        in_sinks && /Sink endpoints:/ { exit }
        in_sinks && match($0, /[0-9]+\./) {
          id = substr($0, RSTART, RLENGTH - 1)
          gsub(/^[[:space:]]+|[[:space:]]+$/, "", id)
          print id
        }
      '
      ;;
  esac
}

get_sink_description() {
  local sink="$1"
  case "$BACKEND" in
    pactl)
      pactl list sinks | awk -v sink="$sink" '
        $1 == "Name:" {
          current = $2
          next
        }
        $1 == "Description:" && current == sink {
          sub(/^Description: /, "")
          print
          exit
        }
      '
      ;;
    wpctl)
      wpctl status | awk -v sink="$sink" '
        /Sinks:/ { in_sinks = 1; next }
        in_sinks && /Sink endpoints:/ { exit }
        in_sinks && index($0, sink ".") {
          line = $0
          sub(/^.*[0-9]+\.[[:space:]]*/, "", line)
          sub(/[[:space:]]*\[vol:.*$/, "", line)
          gsub(/^[*[:space:]]+|[[:space:]]+$/, "", line)
          print line
          exit
        }
      '
      ;;
  esac
}

set_default_sink() {
  local sink="$1"
  case "$BACKEND" in
    pactl)
      pactl set-default-sink "$sink"
      ;;
    wpctl)
      wpctl set-default "$sink"
      ;;
  esac
}

json_escape() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  printf '%s' "$value"
}

print_status() {
  detect_backend

  local default_sink
  default_sink="$(get_default_sink)"

  if [[ -z "$default_sink" ]]; then
    printf '{"text":"OUT ?","tooltip":"No default sink"}\n'
    return
  fi

  local description
  description="$(get_sink_description "$default_sink")"
  description="${description:-$default_sink}"

  printf '{"text":"OUT %s","tooltip":"Default sink: %s"}\n' \
    "$(json_escape "$description")" \
    "$(json_escape "$default_sink")"
}

show_menu() {
  detect_backend

  local default_sink
  default_sink="$(get_default_sink)"

  local entries=()
  local sink description prefix
  while IFS=$'\t' read -r sink description; do
    [[ -n "$sink" ]] || continue
    description="${description:-$sink}"
    prefix="  "
    if [[ "$sink" == "$default_sink" ]]; then
      prefix="* "
    fi
    entries+=("${prefix}${description} (${sink})")
  done < <(while read -r sink; do printf '%s\t%s\n' "$sink" "$(get_sink_description "$sink")"; done < <(list_sinks))

  [[ ${#entries[@]} -gt 0 ]] || exit 0

  local selection
  selection="$(printf '%s\n' "${entries[@]}" | rofi -dmenu -i -p "Audio output")" || exit 0
  [[ -n "$selection" ]] || exit 0

  sink="$(sed -E 's/^..*\(([^()]*)\)$/\1/' <<<"$selection")"
  [[ -n "$sink" ]] || exit 1

  set_default_sink "$sink"

  pkill -RTMIN+"$SIGNAL" waybar 2>/dev/null || true
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
