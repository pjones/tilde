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
Social)
  signal-desktop --enable-features=UseOzonePlatform --ozone-platform=x11 &
  browser-app "https://web.telegram.org" &
  browser-app "https://messages.google.com/web/conversations"
  ;;

RFA)
  e &
  browser "https://code.rfa.sc.gov/" &
  ;;

RFA_Apps)
  browser-app "https://chat.rfa.sc.gov" &
  browser-app "https://outlook.office.com" &
  ;;

*)
  e &
  ;;
esac
