#!/usr/bin/env bash

################################################################################
# Launch a set of applications that go with the current tag.
set -eu
set -o pipefail

################################################################################
desktop=$(
  wmctrl -d |
    awk '$2 == "*" {
        for (i=($8 == "N/A" ? 9 : 10); i<=NF; i++) {
          printf("%s%s", $i, i<NF ? OFS : "\n")
        }
      }'
)

case "$desktop" in
GTD)
  e &
  "$(dirname "$0")/memento-mori.sh" &
  browser-app "https://app.fastmail.com/calendar/month" &
  browser-app "https://home.jonesbunch.com/" &
  browser-app "https://ground.news/" &
  ;;

Social)
  e &
  browser-app "https://messages.google.com/web/conversations" &
  browser-app "https://bsky.app/" &
  browser-app "https://hostux.social/" &
  browser-app "http://10.11.12.1:8081/unread" &
  ;;

RFA1)
  e &
  browser "https://code.rfa.sc.gov/" &
  ;;

RFA2)
  browser-app "https://chat.rfa.sc.gov" &
  browser-app "https://outlook.office.com" &
  ;;

*)
  e &
  ;;
esac
