#!/usr/bin/env bash

################################################################################
set -eu
set -o pipefail

################################################################################
function usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

  -h      This message

Delete all old Home Manager generations.

EOF
}

################################################################################
function main() {
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

  nix-env \
    --delete-generations \
    --profile ~/.local/state/nix/profiles/home-manager \
    old
}

################################################################################
main "$@"
