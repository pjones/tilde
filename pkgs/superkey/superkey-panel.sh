#!/usr/bin/env bash

################################################################################
set -eu
set -o pipefail

################################################################################
all_outputs=()
option_output=
option_action="all"

################################################################################
function usage() {
  cat <<EOF
Usage: $(basename "$0") [options] [output]

  -h      This message
  -H      Hide the panel on the given output
  -o      Only display the panel on the given output
  -S      Show the panel on the given output

Hide or show the panel on the given output.  If no output is given use
the currently focused output.  By deafult the panel will be shown on
all outputs.

EOF
}

################################################################################
# Returns the output selected on the command line.
function get_output() {
  if [[ -n "$option_output" ]]; then
    echo "$option_output"
  else
    niri msg --json focused-output | jq --raw-output .name
  fi
}

################################################################################
# Resets `all_outputs` so it contains all connected outputs except the
# one given.
function get_all_outputs_except() {
  local to_remove=$1
  all_outputs=()

  while IFS= read -r -d "" output; do
    all_outputs+=("$output")
  done < <(niri msg --json outputs |
    jq --raw-output0 \
      --arg to_remove "$to_remove" \
      'keys | map(select(. != $to_remove)) .[]')
}

################################################################################
function main() {
  # Option arguments are in $OPTARG
  while getopts "hHoS" o; do
    case "${o}" in
    h)
      usage
      exit
      ;;

    H)
      option_action="hide"
      ;;

    o)
      option_action="only"
      ;;

    S)
      option_action="show"
      ;;

    *)
      exit 1
      ;;
    esac
  done

  shift $((OPTIND - 1))

  if [[ $# -gt 0 ]]; then
    option_output=$1
  fi

  option_output=$(get_output)

  case "$option_action" in
  all)
    get_all_outputs_except ""

    for output in "${all_outputs[@]}"; do
      wayle panel show "$output"
    done
    ;;

  hide)
    wayle panel hide "$option_output"
    ;;

  show)
    wayle panel show "$option_output"
    ;;

  only)
    get_all_outputs_except "$option_output"

    for output in "${all_outputs[@]}"; do
      wayle panel hide "$output"
    done

    wayle panel show "$option_output"
    ;;

  *)
    echo >&2 "ERROR: This is embarrassing but I don't know what to do."
    exit 1
    ;;

  esac
}

################################################################################
main "$@"
