#!/bin/sh

################################################################################
# Disable the built~in keyboard when using an external keyboard.
set -e
set -u

################################################################################
export DISPLAY=${DISPLAY:=:0.0}
export XAUTHORITY=$HOME/.Xauthority

################################################################################
list_builtin_keyboard() {
  xinput --list --name-only | \
    grep -Ei '^AT .*keyboard' | \
      head -n 1
}

################################################################################
external_keyboard_found() {
  xinput --list --name-only | \
    grep -Eq 'Crkbd'
}

################################################################################
name=$(list_builtin_keyboard)

if [ -z "$name" ]; then
  >&2 echo "ERROR: can't find built-in keyboard!"
  exit 1
fi

if external_keyboard_found; then
  xinput --disable "$name"
else
  xinput --enable "$name"
fi
