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
  browser-app "https://home.jonesbunch.com/" &
  browser-app "https://ground.news/" &
  ;;

*Social)
  e &
  browser-app "https://messages.google.com/web/conversations" &
  browser-app "https://bsky.app/" &
  browser-app "https://hostux.social/" &
  browser-app "https://rss.jonesbunch.com/unread" &
  ;;

*RFA1)
  e &
  browser "https://code.rfa.sc.gov/" &
  ;;

*RFA2)
  browser-app "https://chat.rfa.sc.gov" &
  browser-app "https://outlook.office.com" &
  ;;

*)
  e &
  ;;
esac
