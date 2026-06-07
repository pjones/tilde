#!/usr/bin/env bash

################################################################################
set -eu
set -o pipefail

################################################################################
function usage() {
  cat <<EOF
Usage: $(basename "$0") [options] <name>[.desktop]

  -h      This message

Find a desktop file and run its Exec command.

EOF
}

################################################################################
function find_and_run() {
  local name=$1

  if [ "$(basename "$name" .desktop)" = "$(basename "$name")" ]; then
    name="$name.desktop"
  fi

  while IFS= read -r -d "" dir; do
    if [ -e "$dir/applications/$name" ]; then
      exec gio launch "$dir/applications/$name"
    fi
  done < <(tr ':' '\0' <<<"$XDG_DATA_DIRS")
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

  if [ "$#" -ne 1 ]; then
    echo >&2 "ERROR: missing item name"
    exit 1
  fi

  find_and_run "$@"
}

################################################################################
main "$@"
