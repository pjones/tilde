#!/usr/bin/env bash

################################################################################
# Launch a set of applications that go with the current tag.
set -eu
set -o pipefail

################################################################################
case "$(superkey-workspace.sh -n)" in
*Tasks)
  superkey-dopen.sh calendar &
  ;;

*Social)
  superkey-dopen.sh discord &
  superkey-dopen.sh google-voice &
  superkey-dopen.sh mastodon &
  superkey-dopen.sh whatsapp &
  ;;

*)
  e &
  ;;
esac
