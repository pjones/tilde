#!/usr/bin/env bash

set -eu
set -o pipefail

################################################################################
# shellcheck disable=2120
function count_msgs() {
  local box=${1:-INBOX}

  curl \
    --insecure \
    --user 'example@example.com:password' \
    --request "STATUS $box (MESSAGES)" \
    "imaps://localhost" |
    sed -E 's/^.*MESSAGES +([0-9]+).*$/\1/'
}

################################################################################
# shellcheck disable=2120
function send_mail() {
  local to=${1:-"example@example.com"}

  su lmtp --shell "$SHELL" --command "dovecot-lda -d $to -e" <<MAIL
To: example+foo@example.com
From: other@example.com
Subject: Hi there!
Date: Fri Dec 27 11:47:19 AM CET 2024


How are things?
MAIL
}
