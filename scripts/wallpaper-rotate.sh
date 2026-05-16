#!/usr/bin/env bash

set -euo pipefail

cache_dir="${WALLPAPER_CACHE_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/wallpapers/wallhaven}"
query="${WALLPAPER_QUERY:-purple blue light}"
interval_seconds="${WALLPAPER_INTERVAL_SECONDS:-1800}"
min_cache_count="${WALLPAPER_MIN_CACHE_COUNT:-6}"
max_cache_count="${WALLPAPER_MAX_CACHE_COUNT:-30}"
minimum_resolution="${WALLPAPER_MINIMUM_RESOLUTION:-2560x1440}"
fallback_color="${WALLPAPER_FALLBACK_COLOR:-#090412}"
lock_file="${XDG_RUNTIME_DIR:-/tmp}/wallpaper-rotate.lock"
log_file="${XDG_STATE_HOME:-$HOME/.local/state}/wallpaper-rotate.log"

mkdir -p "$cache_dir" "$(dirname "$log_file")"

log() {
  printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >>"$log_file"
}

require_commands() {
  local missing=()
  local command_name

  for command_name in curl jq flock find shuf file grep sort wc swww; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
      missing+=("$command_name")
    fi
  done

  if ((${#missing[@]} > 0)); then
    log "missing commands: ${missing[*]}"
    exit 1
  fi
}

start_swww() {
  local attempt

  if swww query >/dev/null 2>&1; then
    return
  fi

  if command -v swww-daemon >/dev/null 2>&1; then
    swww-daemon >>"$log_file" 2>&1 &
  else
    swww init >>"$log_file" 2>&1 &
  fi

  for attempt in {1..20}; do
    if swww query >/dev/null 2>&1; then
      return
    fi

    sleep 0.25
  done

  log "swww daemon did not become ready"
  exit 1
}

wallpaper_files() {
  find "$cache_dir" -maxdepth 1 -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \)
}

wallpaper_count() {
  wallpaper_files | wc -l
}

download_wallpapers() {
  local current_count needed page response id image_url target tmp

  current_count="$(wallpaper_count)"
  if ((current_count >= min_cache_count)); then
    return
  fi

  needed=$((min_cache_count - current_count))
  page=$((RANDOM % 10 + 1))

  response="$(curl --fail --silent --show-error --get 'https://wallhaven.cc/api/v1/search' \
    --data-urlencode "q=$query" \
    --data 'categories=100' \
    --data 'purity=100' \
    --data 'sorting=random' \
    --data 'order=desc' \
    --data "atleast=$minimum_resolution" \
    --data "page=$page" \
    --data 'per_page=24')" || {
    log "wallhaven fetch failed for query: $query"
    return
  }

  while IFS=$'\t' read -r id image_url; do
    [[ -n "$id" && -n "$image_url" ]] || continue

    target="$cache_dir/${id}.${image_url##*.}"
    target="${target%%\?*}"
    tmp="${target}.tmp"

    if [[ -f "$target" ]]; then
      continue
    fi

    if curl --fail --location --silent --show-error --output "$tmp" "$image_url"; then
      if file --mime-type "$tmp" | grep -Eq 'image/(jpeg|png|webp)'; then
        mv "$tmp" "$target"
        needed=$((needed - 1))
      else
        rm -f "$tmp"
      fi
    else
      rm -f "$tmp"
    fi

    if ((needed <= 0)); then
      break
    fi
  done < <(jq -r '.data[]? | [.id, .path] | @tsv' <<<"$response")
}

trim_cache() {
  local current_count remove_count index
  local sorted_files=()

  current_count="$(wallpaper_count)"
  if ((current_count <= max_cache_count)); then
    return
  fi

  remove_count=$((current_count - max_cache_count))
  mapfile -t sorted_files < <(wallpaper_files | sort)

  for ((index = 0; index < remove_count; index++)); do
    rm -f "${sorted_files[$index]}"
  done
}

set_random_wallpaper() {
  local selected

  selected="$(wallpaper_files | shuf -n 1)"
  if [[ -z "$selected" ]]; then
    log "no cached wallpapers available; using fallback color"
    swww clear "$fallback_color" >/dev/null 2>&1 || true
    return
  fi

  swww img "$selected" \
    --resize crop \
    --transition-type random \
    --transition-duration 1 \
    --transition-fps 60
}

main() {
  require_commands

  exec 9>"$lock_file"
  if ! flock -n 9; then
    exit 0
  fi

  start_swww

  while true; do
    download_wallpapers
    trim_cache
    set_random_wallpaper
    sleep "$interval_seconds"
  done
}

main "$@"
