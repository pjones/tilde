#!/usr/bin/env bash

################################################################################
set -eu
set -o pipefail

################################################################################
option_power_on_off=

################################################################################
usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

  -h      This message
  -o      Turn all outputs on
  -O      Turn all outputs off

EOF
}

################################################################################
power_on_off() {
  local state=$1
  niri msg action "power-$state-monitors"
}

################################################################################
parse_options() {
  # Option arguments are in $OPTARG
  while getopts "hoO" o; do
    case "${o}" in
    o)
      option_power_on_off=on
      ;;

    O)
      option_power_on_off=off
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
}

################################################################################
main() {
  parse_options "$@"

  if [ -n "$option_power_on_off" ]; then
    power_on_off "$option_power_on_off"
  fi
}

################################################################################
main "$@"
