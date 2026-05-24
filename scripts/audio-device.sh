#!/usr/bin/env bash

set -euo pipefail

SIGNAL="${WAYBAR_SIGNAL:-8}"
DEVICE_KIND="${2:-output}"
BACKEND=""

case "$DEVICE_KIND" in
  output)
    PACTL_TYPE="sink"
    PACTL_TYPES="sinks"
    WPCTL_SECTION="Sinks:"
    WPCTL_ENDPOINTS="Sink endpoints:"
    LABEL="OUT"
    MENU_PROMPT="Audio output"
    TOOLTIP_LABEL="Default output"
    ;;
  input)
    PACTL_TYPE="source"
    PACTL_TYPES="sources"
    WPCTL_SECTION="Sources:"
    WPCTL_ENDPOINTS="Source endpoints:"
    LABEL="IN"
    MENU_PROMPT="Audio input"
    TOOLTIP_LABEL="Default input"
    ;;
  *)
    echo "Unknown device kind: $DEVICE_KIND" >&2
    exit 1
    ;;
esac

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

get_default_device() {
  case "$BACKEND" in
    pactl)
      pactl "get-default-$PACTL_TYPE"
      ;;
    wpctl)
      wpctl status | awk -v section="$WPCTL_SECTION" -v endpoints="$WPCTL_ENDPOINTS" '
        index($0, section) { in_section = 1; next }
        in_section && index($0, endpoints) { exit }
        in_section && /\*/ {
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

list_devices() {
  case "$BACKEND" in
    pactl)
      pactl list short "$PACTL_TYPES" | awk -v kind="$DEVICE_KIND" '
        kind == "input" && $2 ~ /\.monitor$/ { next }
        { print $2 }
      '
      ;;
    wpctl)
      wpctl status | awk -v section="$WPCTL_SECTION" -v endpoints="$WPCTL_ENDPOINTS" -v kind="$DEVICE_KIND" '
        index($0, section) { in_section = 1; next }
        in_section && index($0, endpoints) { exit }
        in_section && kind == "input" && /Monitor of/ { next }
        in_section && match($0, /[0-9]+\./) {
          id = substr($0, RSTART, RLENGTH - 1)
          gsub(/^[[:space:]]+|[[:space:]]+$/, "", id)
          print id
        }
      '
      ;;
  esac
}

get_device_description() {
  local device="$1"
  case "$BACKEND" in
    pactl)
      pactl list "$PACTL_TYPES" | awk -v device="$device" '
        $1 == "Name:" {
          current = $2
          next
        }
        $1 == "Description:" && current == device {
          sub(/^Description: /, "")
          print
          exit
        }
      '
      ;;
    wpctl)
      wpctl status | awk -v device="$device" -v section="$WPCTL_SECTION" -v endpoints="$WPCTL_ENDPOINTS" '
        index($0, section) { in_section = 1; next }
        in_section && index($0, endpoints) { exit }
        in_section && index($0, device ".") {
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

get_device_short_id() {
  local device="$1"
  case "$BACKEND" in
    pactl)
      pactl list short "$PACTL_TYPES" | awk -v device="$device" '$2 == device { print $1; exit }'
      ;;
    wpctl)
      printf '%s\n' "$device"
      ;;
  esac
}

set_default_device() {
  local device="$1"
  case "$BACKEND" in
    pactl)
      pactl "set-default-$PACTL_TYPE" "$device"
      ;;
    wpctl)
      wpctl set-default "$device"
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

  local default_device
  default_device="$(get_default_device)"

  if [[ -z "$default_device" ]]; then
    printf '{"text":"%s ?","tooltip":"No default %s"}\n' "$LABEL" "$PACTL_TYPE"
    return
  fi

  local description short_id
  description="$(get_device_description "$default_device")"
  description="${description:-$default_device}"
  short_id="$(get_device_short_id "$default_device")"
  short_id="${short_id:-$default_device}"

  printf '{"text":"%s %s","tooltip":"%s: %s"}\n' \
    "$LABEL" \
    "$(json_escape "$short_id")" \
    "$(json_escape "$TOOLTIP_LABEL")" \
    "$(json_escape "$description ($default_device)")"
}

show_menu() {
  detect_backend

  local default_device
  default_device="$(get_default_device)"

  local entries=()
  local device description prefix
  while IFS=$'\t' read -r device description; do
    [[ -n "$device" ]] || continue
    description="${description:-$device}"
    prefix="  "
    if [[ "$device" == "$default_device" ]]; then
      prefix="* "
    fi
    entries+=("${prefix}${description} (${device})")
  done < <(while read -r device; do printf '%s\t%s\n' "$device" "$(get_device_description "$device")"; done < <(list_devices))

  [[ ${#entries[@]} -gt 0 ]] || exit 0

  local selection
  selection="$(printf '%s\n' "${entries[@]}" | rofi -dmenu -i -p "$MENU_PROMPT")" || exit 0
  [[ -n "$selection" ]] || exit 0

  device="$(sed -E 's/^..*\(([^()]*)\)$/\1/' <<<"$selection")"
  [[ -n "$device" ]] || exit 1

  set_default_device "$device"

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
    echo "Usage: $0 [status|menu] [output|input]" >&2
    exit 1
    ;;
esac
