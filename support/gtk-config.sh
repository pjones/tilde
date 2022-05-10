#!/usr/bin/env bash

################################################################################
#
# Configure GTK without disturbing settings from the desktop
# environment (Plasma).
set -eu
set -o pipefail

################################################################################
key=gtk-key-theme-name

################################################################################
function set_gtk2() {
  local gtk2=~/.gtkrc-2.0

  if ! [ -e "$gtk2" ]; then
    touch "$gtk2"
  fi

  if ! grep -q "$key"; then
    echo "$key=\"Emacs\"" >>"$gtk2"
  fi
}

################################################################################
function set_gtk3() {
  local gtk3=~/.config/gtk-3.0/settings.ini

  if ! [ -e "$gtk3" ]; then
    mkdir -p "$(dirname "$gtk3")"
    touch "$gtk3"
  fi

  crudini --set "$gtk3" Settings "$key" Emacs
}

################################################################################
function main() {
  set_gtk2
  set_gtk3
}

################################################################################
main
