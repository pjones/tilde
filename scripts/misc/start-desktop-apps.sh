#!/usr/bin/env bash

################################################################################
# Launch a set of applications that go with the current tag.
set -eu
set -o pipefail

################################################################################
desktop=$(superkey-workspace.sh -n)

case "$desktop" in
*GTD)
  e &
  e &
  "$(dirname "$0")/memento-mori.sh" &
  browser-app "https://app.fastmail.com/calendar/month" &
  ;;

*Social)
  browser-app "https://discord.com/channels/688750797378682946/689772813481279547" &
  browser-app "https://fosstodon.org/" &
  ;;

*)
  e &
  ;;
esac
