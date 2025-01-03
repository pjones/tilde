#!/usr/bin/env bash

################################################################################
# Move bookmarks into a directory that syncs to all devices.

set -e
set -u

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
    mkdir -p "$(dirname "$shared")"
  fi

  if [ ! -e "$(dirname "$original")" ]; then
    # Ensure the directory where we're placing the link exists:
    mkdir -p "$(dirname "$original")"
  fi

  if [ -e "$original" ] && [ ! -e "$shared" ]; then
    # No shared file exists, move the original to the shared location:
    mv "$original" "$shared"
  elif [ -e "$original" ]; then
    # Shared file exists, move the original out of the way:
    mv "$original" "$original.$(date +%Y%m%m-%H%M%S)"
  fi

  if [ ! -e "$shared" ]; then
    # Make sure the shared file exists:
    touch "$shared"
  fi

  # Link the shared file on top of the original:
  (cd "$(dirname "$original")" &&
    ln -s "$shared" "$(basename "$original")")
}

################################################################################
bookmarks_emacs() {
  local bookmarks=$HOME/.cache/emacs/bookmarks
  local share=$destination/emacs
  safe_link_file "$bookmarks" "$share"
}

################################################################################
personal_dictionary() {
  local dict=$HOME/.config/enchant/en_US.dic
  local share=$destination/en_US.dic
  safe_link_file "$dict" "$share"
}

################################################################################
bookmarks_emacs
personal_dictionary
