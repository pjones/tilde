#!/usr/bin/env bash

################################################################################
set -eu
set -o pipefail

################################################################################
option_app_id=
option_current_workspace=0
option_focus=0

################################################################################
function usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

  -a ID   Find the window with app_id ID
  -c      Restrict to windows on the current workspace
  -f      Focus the first matching window
  -h      This message

Search for matching windows and print the first matching window's ID.
If the -f option is given, focus the window instead.

If no matching window can be found, this script will exit with status
code 2.

EOF
}

################################################################################
function niri_find_window() {
  local workspace=null
  local app_id=null
  local win_id

  if [ "$option_current_workspace" = 1 ]; then
    workspace=$(
      niri msg --json workspaces |
        jq 'map(select(.is_focused)) | .[] | .id'
    )
  fi

  if [ -n "$option_app_id" ]; then
    app_id="\"$option_app_id\""
  fi

  win_id=$(
    niri msg --json windows |
      jq \
        --argjson wspace "$workspace" \
        --argjson appid "$app_id" \
        'map(
           select(
             (if ($wspace != null)
              then (.workspace_id == $wspace)
              else true
              end)
             and
              (if ($appid != null)
               then (.app_id == $appid)
               else true
               end)
           )
       ) | .[] | .id' |
      head -1
  )

  if [ -z "$win_id" ]; then
    exit 2
  elif [ "$option_focus" = 1 ]; then
    niri msg action focus-window --id "$win_id"
  else
    echo "$win_id"
  fi
}

################################################################################
function main() {
  while getopts "a:cfh" o; do
    case "${o}" in
    a)
      option_app_id=$OPTARG
      ;;

    c)
      option_current_workspace=1
      ;;

    f)
      option_focus=1
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

  case "$XDG_CURRENT_DESKTOP" in
  niri)
    niri_find_window
    ;;

  *)
    echo >&2 "ERROR: unknown desktop environment: $XDG_CURRENT_DESKTOP"
    exit 1
    ;;
  esac
}

################################################################################
main "$@"
