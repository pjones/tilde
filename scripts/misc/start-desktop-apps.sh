#!/usr/bin/env bash

################################################################################
# Launch a set of applications that go with the current tag.
set -eu
set -o pipefail

################################################################################
case $(wmctrl -d | awk '$2 == "*" { print $10 }') in
GTD)
  e
  browser --new-window "https://calendar.google.com/calendar/"
  ;;

Social)
  signal-desktop --enable-features=UseOzonePlatform --ozone-platform=x11 &
  browser-app "https://web.telegram.org" &
  browser-app "https://messages.google.com/web/conversations"
  ;;

RFA)
  browser-app "https://chat.rfa.sc.gov" &
  browser-app "https://code.rfa.sc.gov/" &
  browser-app "https://outlook.office.com" &
  e
  ;;

Monitoring)
  browser-app "https://stats.devalot.com/d/fkNz2pRMz/system-health?orgId=1&from=now-1h&to=now&refresh=30s&kiosk&var-node=kilgrave&var-node=medusa"
  browser-app "https://stats.devalot.com/d/fkNz2pRMz/system-health?orgId=1&from=now-1h&to=now&refresh=30s&kiosk&var-node=moriarty&var-node=ursula"
  browser-app "https://stats.devalot.com/d/UJ0W9oRGk/headquarters?openVizPicker&orgId=1&from=now-3h&to=now&refresh=30s&kiosk"
  ;;

*)
  konsole &
  ;;
esac
