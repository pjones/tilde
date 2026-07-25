#!/usr/bin/env bash

################################################################################
set -eu
set -o pipefail

################################################################################
function usage() {
  cat <<EOF
Usage: $(basename "$0") [options] host json-file

  -h      This message

  Generate a WireGuard configuration for wg0 for the given host.

  The json-file is the Nix configuration as JSON.  See the
  wg-gen-all.sh script for more details.

  The generated file is written to standard output.
EOF
}

################################################################################
function main() {
  # Option arguments are in $OPTARG
  while getopts "h" o; do
    case "${o}" in
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

  if [[ $# -ne 2 ]]; then
    echo >&2 "ERROR: missing arguments"
    usage
    exit 1
  fi

  bin=$(realpath "$(dirname "$0")")

  "$bin/wg-gen.py" \
    --load-key \
    --remove-empty-peers \
    --host "$1" \
    "$2"
}

################################################################################
main "$@"
