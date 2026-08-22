#!/usr/bin/env bash

################################################################################
option_enable="toggle"

################################################################################
function usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

  -h      This message
  -o      Force presenter mode ON
  -O      Force presenter mode OFF

EOF
}

################################################################################
function parse_options() {
  # Option arguments are in $OPTARG
  while getopts "hoO" o; do
    case "${o}" in
    h)
      usage
      exit
      ;;

    o)
      option_enable=1
      ;;

    O)
      option_enable=0
      ;;

    *)
      exit 1
      ;;
    esac
  done

  shift $((OPTIND - 1))

}

################################################################################
function main() {
  parse_options "$@"

  local dnd_state
  dnd_state=$(superkey-dnd.sh -p)

  # Toggling uses the DND state:
  if [[ "$option_enable" = "toggle" ]]; then
    if [[ "$dnd_state" -eq 0 ]]; then
      option_enable=1
    else
      option_enable=0
    fi
  fi

  if [[ "$option_enable" -eq 1 ]]; then
    wayle idle on
    wayle idle duration 480
    wayle config set modules.idle-inhibit.label-show true
    wayle wallpaper stop
    wayle wallpaper set ~/documents/pictures/backgrounds/disneyland/haunted-house/wallpaper.jpg
    superkey-dnd.sh
  else
    wayle config set modules.idle-inhibit.label-show false
    wayle idle off
    superkey-dnd.sh -d

    wayle wallpaper cycle \
      --mode "$(wayle config get wallpaper.cycling-mode)" \
      "$(wayle config get wallpaper.cycling-directory)"
  fi
}

################################################################################
main "$@"
