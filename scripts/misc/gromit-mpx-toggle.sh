#!/usr/bin/env bash

################################################################################
#
# If gromit-mpx is already displayed hide it.  Otherwise show it.
#
set -eu
set -o pipefail

################################################################################
function is_active() {
  for id in $(xdotool search --all --onlyvisible --classname Gromit-mpx); do
    if xdotool getwindowgeometry "$id" | grep -q "Position: 0,0"; then
      return 0
    fi
  done

  return 1
}

################################################################################
function main() {
  if is_active; then
    # Hide the window, release the pointer grab:
    gromit-mpx --visibility
  else
    # Activate the window and pointer grab:
    gromit-mpx --toggle
  fi
}

################################################################################
main
