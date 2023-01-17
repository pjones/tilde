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
  browser "https://app.fastmail.com/mail/Inbox" &
  browser "https://app.fastmail.com/calendar/month" &
  ;;

Social)
  signal-desktop --enable-features=UseOzonePlatform --ozone-platform=x11 &
  browser-app "https://web.telegram.org" &
  browser-app "https://messages.google.com/web/conversations" &
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
