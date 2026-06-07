#!/usr/bin/env bash

################################################################################
set -eu
set -o pipefail

################################################################################
color_scheme=
gtk_theme=

################################################################################
case "${1:-dark}" in
dark)
  color_scheme=prefer-dark
  gtk_theme=Adwaita-dark
  ;;

light)
  color_scheme=prefer-light
  gtk_theme=Adwaita
  ;;

*)
  echo >&2 "ERROR: theme name should be dark or light"
  exit 1
  ;;
esac

################################################################################
if [ "${XDG_CURRENT_DESKTOP:-}" = "niri" ]; then
  # Ask Niri to animate the theme transition:
  niri msg action do-screen-transition
fi

gsettings set org.gnome.desktop.interface color-scheme "$color_scheme"
gsettings set org.gnome.desktop.interface gtk-theme "$gtk_theme"
