#!/usr/bin/env bash

################################################################################
set -eux
set -o pipefail

################################################################################
function wait_for_file() {
  local file=$1
  local count=0

  while [ "$count" -lt 5 ] && [ ! -e "$file" ]; do
    sleep 0.5
  done

  if [ ! -e "$file" ]; then
    echo >&2 "ERROR: file never appeared: $file"
    exit 1
  fi
}

################################################################################
function main() {
  test "$(count_msgs Trash)" -eq 0
  send_mail
  wait_for_file "/var/lib/lmtp/last-msg.txt"
  test "$(count_msgs Trash)" -eq 1

  test -e "/var/lib/lmtp/last-msg.txt"
  grep "From: other@example.com" "/var/lib/lmtp/last-msg.txt"
  grep "How are things" "/var/lib/lmtp/last-msg.txt"
}

################################################################################
main "$@"
