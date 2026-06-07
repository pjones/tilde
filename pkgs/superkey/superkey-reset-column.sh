#!/usr/bin/env bash

################################################################################
set -eu
set -o pipefail

################################################################################
option_all=0

################################################################################
function usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

  -a      Reset all columns on this workspace
  -h      This message

EOF
}

################################################################################
function reset_column() {
  local output=$1
  local width="33%"

  if [ "$output" = "eDP-1" ]; then
    width="50%"
  fi

  niri msg action set-column-width "$width"
  niri msg action reset-window-height
}

################################################################################
function reset_all() {
  local output=$1

  local current_window
  current_window=$(niri msg --json focused-window | jq .id)

  local current_workspace
  current_workspace=$(niri msg --json focused-window | jq .workspace_id)

  local windows=()

  while IFS= read -r -d "" window; do
    windows+=("$window")
  done < <(niri msg --json windows |
    jq --raw-output0 --argjson ws "$current_workspace" \
      'map(select(.workspace_id == $ws and .is_floating == false))
        | map({"id":.id, "pos": .layout.pos_in_scrolling_layout[0]})
        | group_by(.pos) | map(.[0].id) | .[]')

  niri msg action do-screen-transition --delay-ms 600

  for window in "${windows[@]}"; do
    niri msg action focus-window --id "$window"
    reset_column "$output"
  done

  niri msg action focus-window --id "$current_window"
  niri msg action center-column
}

################################################################################
function main() {
  while getopts "ah" o; do
    case "${o}" in
    a)
      option_all=1
      ;;

    h)
      usage
      exit
      ;;

    *)
      exit 1
      ;;
    esac
  done

  shift $((OPTIND - 1))

  local output
  output=$(niri msg --json focused-output | jq --raw-output .name)

  if [ "$option_all" -eq 1 ]; then
    reset_all "$output"
  else
    reset_column "$output"
  fi
}

################################################################################
main "$@"
