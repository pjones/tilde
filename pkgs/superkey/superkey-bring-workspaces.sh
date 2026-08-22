#!/usr/bin/env bash

################################################################################
set -eu
set -o pipefail

################################################################################
option_dryrun=0
option_skip=("social")

################################################################################
function usage() {
  cat <<EOF
Usage: $(basename "$0") [options] [output]

  -d      Dry run
  -h      This message

Bring workspaces on other monitors to the named output.  If the name
of the output is not given it is taken from the foucsed output.

EOF
}

################################################################################
function bring_others() {
  local current=$1
  local workspace
  local skip=""

  for name in "${option_skip[@]}"; do
    if [ -n "$skip" ]; then
      skip="${skip},"
    fi
    skip="${skip}\"${name}\""
  done

  while IFS= read -r -d "" workspace; do
    echo "moving $workspace to $current"

    if [ "$option_dryrun" -eq 0 ]; then
      printf \
        '{"Action":{"MoveWorkspaceToMonitor":{"output":"%s","reference":{"Id":%d}}}}' \
        "$current" "$workspace" |
        nc -UN "$NIRI_SOCKET"
    fi
  done < <(niri msg --json workspaces |
    jq --raw-output0 \
      --arg current "$current" \
      --argjson skip "[$skip]" \
      'map(select(.output != $current and
                  .active_window_id != null and
                  (.name | IN($skip[]) | not)))
        | map(.id)
        | .[]')
}

################################################################################
function main() {
  while getopts "dh" o; do
    case "${o}" in
    d)
      option_dryrun=1
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

  local current

  if [ $# -eq 1 ]; then
    current=$1
  else
    current=$(niri msg --json focused-output | jq --raw-output .name)
  fi

  bring_others "$current"
}

################################################################################
main "$@"
