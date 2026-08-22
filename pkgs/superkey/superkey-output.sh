#!/usr/bin/env bash

################################################################################
set -eu
set -o pipefail

################################################################################
option_power_on_off=
option_output=
option_mode=power
option_presenting=0
option_public=0

################################################################################
usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

  -d      Monitor visible, so use do not disturb
  -h      This message
  -o      Turn all outputs on
  -O      Turn all outputs off
  -p NAME Make NAME the primary output
  -P      Other monitors are presenting publicly

EOF
}

################################################################################
function power_on_off() {
  local state=$1
  niri msg action "power-$state-monitors"
}

################################################################################
function make_primary() {
  local output=$1

  # Remove the panel from other monitors:
  while IFS= read -r -d "" other; do
    if [ "$other" != "$output" ]; then
      wayle panel hide "$other"
    fi
  done < <(niri msg --json outputs |
    jq --raw-output0 'keys | .[]')

  wayle panel show "$output"

  if [ "$output" = "eDP-1" ]; then
    # This monitor is too small, so remove some details:
    wayle config set modules.niri-workspaces.label-strategy index
    wayle config set modules.niri-workspaces.monitor-specific true
  else
    # Ensure a normal bar:
    wayle config set modules.niri-workspaces.label-strategy index-and-name
    wayle config set modules.niri-workspaces.monitor-specific false
  fi

  # Ensure workspaces are moved to this monitor:
  superkey-bring-workspaces.sh "$output" || :

  # Are we connected to a presenter/beamer?
  if [[ "$option_presenting" -eq 1 ]]; then
    superkey-presenter.sh -o
  else
    superkey-presenter.sh -O
  fi

  # Is the primary monitor visible?
  if [[ "$option_public" -eq 1 ]] || [ "$option_presenting" -eq 1 ]; then
    superkey-dnd.sh # Enable "Do not disturb"
  else
    superkey-dnd.sh -d # Disable "Do not disturb"
  fi
}

################################################################################
function parse_options() {
  # Option arguments are in $OPTARG
  while getopts "dhoOp:P" o; do
    case "${o}" in
    d)
      option_public=1
      ;;

    o)
      option_power_on_off=on
      ;;

    O)
      option_power_on_off=off
      ;;

    p)
      option_mode=primary
      option_output=$OPTARG
      ;;

    P)
      option_presenting=1
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
function main() {
  parse_options "$@"

  case "$option_mode" in
  power)
    if [ -n "$option_power_on_off" ]; then
      power_on_off "$option_power_on_off"
    fi
    ;;

  primary)
    make_primary "$option_output"
    ;;
  esac
}

################################################################################
main "$@"
