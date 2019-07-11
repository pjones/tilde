#!/bin/sh

################################################################################
# Disable the built~in keyboard when using an external keyboard.
set -e
set -u

################################################################################
export PATH=@nixpath@:$PATH
export HOME=/home/pjones
export DISPLAY=${DISPLAY:=:0.0}
export XAUTHORITY=$HOME/.Xauthority

################################################################################
list_builtin_keyboard() {
  xinput --list --name-only | \
    grep -Ei '^AT .*keyboard' | \
      head -n 1
}

################################################################################
name=$(list_builtin_keyboard)

if [ -z "$name" ]; then
  >&2 echo "ERROR: can't find built-in keyboard!"
  exit 1
fi

if [ $# -eq 1 ] && [ "$1" = "add" ]; then
  # An external keyboard was added.
  xinput --disable "$name"
else
  # An external keyboard was removed.
  xinput --enable "$name"
fi
