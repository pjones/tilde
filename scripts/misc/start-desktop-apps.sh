#!/usr/bin/env bash

################################################################################
# Launch a set of applications that go with the current tag.
set -eu
set -o pipefail

################################################################################
function open_desktop_items() {
  for name in "$@"; do
    superkey-dopen.sh "$name" &
    sleep 1
  done
}

################################################################################
case "$(superkey-workspace.sh -n)" in
*[Tt]asks)
  open_desktop_items calendar
  ;;

*[Ss]ocial)
  open_desktop_items \
    discord \
    google-voice \
    slack \
    whatsapp
  ;;

*)
  e &
  ;;
esac
