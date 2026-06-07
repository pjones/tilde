#!/usr/bin/env bash

################################################################################
set -eu
set -o pipefail

################################################################################
option_to_output=

################################################################################
usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

  -h      This message
  -p      Map any tablets to the primary output
  -s      Map any tablets to the secondary output

EOF
}

################################################################################
parse_options() {
  # Option arguments are in $OPTARG
  while getopts "psh" o; do
    case "${o}" in
    h)
      usage
      exit
      ;;

    p)
      option_to_output=primary
      ;;

    s)
      option_to_output=secondary
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

  if [ -n "$option_to_output" ]; then
    echo >&2 "ERROR: not implemented on Niri"
    exit 1
  fi
}

################################################################################
main "$@"
