#!/usr/bin/env bash

set -eu
set -o pipefail

################################################################################
enable="enable"

################################################################################
_gsettings() {
  local command=$1
  shift

  gsettings --schemadir @schema_dir@ \
    "$command" com.freerangebits.desktop.presenter-mode \
    "$@"
}

################################################################################
get_val() {
  _gsettings get "$@"
}

################################################################################
set_val() {
  _gsettings set "$@" >/dev/null 2>&1
}

################################################################################
toggle_dnd() {
  local action=$1
  local options=()

  if [ "$action" = "$enable" ]; then
    options+=("--dnd-on")
  else
    options+=("--dnd-off")
  fi

  swaync-client "${options[@]}" >/dev/null 2>&1
}

################################################################################
toggle_inhibit() {
  local action=$1

  if [ "$action" = "$enable" ]; then
    systemctl --user start wayland-inhibit.service
  else
    systemctl --user stop wayland-inhibit.service
  fi
}

################################################################################
toggle_tablet_tool() {
  local action=$1
  local options=()

  if [ "$action" = "$enable" ]; then
    options+=("-s") # Secondary monitor.
  else
    options+=("-p") # Primary monitor.
  fi

  superkey-tablet.sh "${options[@]}"
}

################################################################################
main() {
  local action=$enable

  if [ "$(get_val enabled)" != "false" ]; then
    action=disable
  fi

  if [ "$action" = "enable" ]; then
    set_val enabled true
    toggle_dnd "$action"
    toggle_inhibit "$action"
    toggle_tablet_tool "$action"
  else
    set_val enabled false
    toggle_dnd "$action"
    toggle_inhibit "$action"
    toggle_tablet_tool "$action"
  fi
}

################################################################################
main "$@"
