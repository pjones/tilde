#!/usr/bin/env bash

################################################################################
# Launch a set of applications that go with the current tag.
set -eu
set -o pipefail

################################################################################
desktop=$(desktop-workspace -n)

case "$desktop" in
*GTD)
  e &
  "$(dirname "$0")/memento-mori.sh" &
  browser-app "https://app.fastmail.com/calendar/month" &
  ;;

*Social)
  e &
  browser-app "https://messages.google.com/web/conversations" &
  browser-app "https://fosstodon.org/" &
  browser-app "https://rss.jonesbunch.com/unread" &
  ;;

*)
  e &
  ;;
esac
