#!/usr/bin/env bash

################################################################################
set -eu
set -o pipefail

################################################################################
function usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

  -h      This message
  -d      Disable instead.
  -p      Print the current state and exit

Enable Do Not Distrub mode.

EOF
}

################################################################################
function main() {
  local option_enable=1
  local option_print_only=0

  while getopts "dhp" o; do
    case "${o}" in
    d)
      option_enable=0
      ;;

    h)
      usage
      exit
      ;;

    p)
      option_print_only=1
      ;;

    *)
      exit 1
      ;;
    esac
  done

  shift $((OPTIND - 1))

  local dnd_state
  dnd_state=$(wayle notify status | grep 'Disturb:' | cut -d: -f2)

  if [[ "$dnd_state" =~ disabled ]]; then
    dnd_state=0
  else
    dnd_state=1
  fi

  if [[ "$option_print_only" -eq 1 ]]; then
    echo "$dnd_state"
    exit
  fi

  if [[ "$option_enable" -eq 1 ]]; then
    if [[ "$dnd_state" -eq 0 ]]; then
      # Only toggle DND if it isn't already on.
      wayle notify dnd
    fi
  else
    if [[ "$dnd_state" -eq 1 ]]; then
      # Only toggle DND if it's on.
      wayle notify dnd
    fi
  fi
}

################################################################################
main "$@"
