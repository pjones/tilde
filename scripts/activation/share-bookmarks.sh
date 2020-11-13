#!/usr/bin/env bash

################################################################################
# Move bookmarks into a directory that syncs to all devices.

set -e
set -u

################################################################################
# home-manager variables:
DRY_RUN_CMD=${DRY_RUN_CMD:-}
VERBOSE_ARG=${VERBOSE_ARG:-}

################################################################################
destination=$HOME/notes/bookmarks

if [ ! -d "$destination" ]; then
  exit
fi

################################################################################
safe_link_file() {
  local original=$1
  local shared=$2

  if [ -e "$original" ] && [ -L "$original" ]; then
    # File is already linked.
    return
  fi

  if [ ! -e "$(dirname "$shared")" ]; then
    # Make sure there's a directory to move files into.
    $DRY_RUN_CMD mkdir -p $VERBOSE_ARG "$(dirname "$shared")"
  fi

  if [ ! -e "$(dirname "$original")" ]; then
    # Ensure the directory where we're placing the link exists:
    $DRY_RUN_CMD mkdir -p $VERBOSE_ARG "$(dirname "$original")"
  fi

  if [ -e "$original" ] && [ ! -e "$shared" ]; then
    # No shared file exists, move the original to the shared location:
    $DRY_RUN_CMD mv $VERBOSE_ARG "$original" "$shared"
  elif [ -e "$original" ]; then
    # Shared file exists, move the original out of the way:
    $DRY_RUN_CMD mv $VERBOSE_ARG "$original" "$original.$(date +%Y%m%m-%H%M%S)"
  fi

  if [ ! -e "$shared" ]; then
    # Make sure the shared file exists:
    $DRY_RUN_CMD touch "$shared"
  fi

  # Link the shared file on top of the original:
  ($DRY_RUN_CMD cd "$(dirname "$original")" &&
    $DRY_RUN_CMD ln -s $VERBOSE_ARG "$shared" "$(basename "$original")")
}

################################################################################
bookmarks_emacs() {
  local bookmarks=$HOME/.cache/emacs/bookmarks
  local share=$destination/emacs
  safe_link_file "$bookmarks" "$share"
}

################################################################################
bookmarks_emacs
