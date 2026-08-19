#!/usr/bin/env bash

set -eu
set -o pipefail

################################################################################
function wait_for_file() {
  local file=$1
  local count=0

  while [ "$count" -lt 30 ] && [ ! -e "$file" ]; do
    sleep 0.5
    count=$((count + 1))
  done

  if [ ! -e "$file" ]; then
    echo >&2 "ERROR: file never appeared: $file"
    exit 1
  fi
}

################################################################################
function wait_until_fails() {
  while "$@"; do
    sleep 0.5
  done
}

################################################################################
# shellcheck disable=2120
function count_msgs() {
  local box=${1:-INBOX}

  curl \
    --insecure \
    --user 'example@example.test:password' \
    --request "STATUS $box (MESSAGES)" \
    "imaps://localhost" |
    sed -E 's/^.*MESSAGES +([0-9]+).*$/\1/'
}

################################################################################
function test_message() {
  cat <<MAIL
To: example+foo@example.test
From: other@example.test
Subject: Hi there!
Date: Fri Dec 27 11:47:19 AM CET 2024


How are things?
MAIL
}

################################################################################
# shellcheck disable=2120
function send_mail() {
  local to=${1:-"example@example.test"}
  test_message |
    sudo --login \
      su lmtp --shell "$SHELL" --command "dovecot-lda -d $to -e"
}
