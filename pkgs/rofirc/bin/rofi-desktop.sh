#!/usr/bin/env bash

set -e
set -u

################################################################################
function new_workspace() {
  local name

  name=$(
    @out@/bin/rofi-wrapper.sh \
      -dmenu \
      -p "New workspace name" \
      -mesg "Enter new workspace name."
  )

  if [ -n "$name" ]; then
    superkey-workspace.sh -N "$name"
  fi
}

################################################################################
function rename_workspace() {
  local new_name

  new_name=$(
    @out@/bin/rofi-wrapper.sh \
      -dmenu \
      -p "Workspace name" \
      -mesg "Choose a new name for this workspace."
  )

  if [ -n "$new_name" ]; then
    superkey-workspace.sh -r "$new_name"
  fi
}

################################################################################
if [ $# -eq 0 ]; then
  # Rofi wants a list of desktops:
  echo -en "\0use-hot-keys\x1ftrue\n"

  declare -a desktops
  mapfile -t desktops < <(superkey-workspace.sh)

  for d in "${desktops[@]}"; do
    echo -en "$d\0icon\x1fnetwork-workgroup\n"
  done

  echo -en "Rename Workspace\0icon\x1fnetwork-workgroup\x1finfo\x1frename\n"
  echo -en "Unname Workspace\0icon\x1fnetwork-workgroup\x1finfo\x1funname\n"
else
  case "${ROFI_INFO:-}" in
  rename)
    coproc rename_workspace >/dev/null 2>&1
    ;;

  unname)
    superkey-workspace.sh -r ""
    ;;

  *)
    if [ "$ROFI_RETV" -eq 10 ]; then
      superkey-workspace.sh -m "$1"
    else
      superkey-workspace.sh -S "$1"
    fi
    ;;
  esac
fi
