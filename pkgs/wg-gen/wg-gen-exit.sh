#!/usr/bin/env bash

################################################################################
set -eu
set -o pipefail

################################################################################
function usage() {
  cat <<EOF
Usage: $(basename "$0") [options] host exit-node-name json-file

  -h      This message

  Generate a WireGuard configuration file that redirects all traffic
  through an exit node.

  The exit-node-name is the name of the peer that is the exit node for
  this configuration.

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

  if [[ $# -ne 3 ]]; then
    echo >&2 "ERROR: missing arguments"
    usage
    exit 1
  fi

  bin=$(realpath "$(dirname "$0")")

  "$bin/wg-gen.py" \
    --load-key \
    --host "$1" \
    --name "$2" \
    --exit "$2" \
    "$3"
}

################################################################################
main "$@"
