#!/usr/bin/env bash

################################################################################
set -eu
set -o pipefail

################################################################################
function usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

  -h      This message

Mirror the other monitor on this monitor.

EOF
}

################################################################################
function niri_next_output() {
  local current_output

  current_output=$(
    niri msg --json workspaces |
      jq --raw-output 'map(select(.is_focused)) | .[] | .output' |
      head -1
  )

  niri msg --json outputs |
    jq --raw-output \
      --arg current "$current_output" \
      'map(select(.name != $current)) | .[] | .name'
}

################################################################################
function main() {
  local output

  case "$XDG_CURRENT_DESKTOP" in
  niri)
    output=$(niri_next_output)
    ;;

  *)
    echo >&2 "ERROR: this script doesn't work on $XDG_CURRENT_DESKTOP"
    exit 1
    ;;
  esac

  wl-mirror "$output"
}

################################################################################
main "$@"
