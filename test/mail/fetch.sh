#!/usr/bin/env bash

################################################################################
set -eux
set -o pipefail

################################################################################
function main() {
  test "$(count_msgs Trash)" -eq 0
  send_mail
  wait_for_file "/var/lib/lmtp/last-msg.txt"
  test "$(count_msgs Trash)" -eq 1

  test -e "/var/lib/lmtp/last-msg.txt"
  grep "From: other@example.test" "/var/lib/lmtp/last-msg.txt"
  grep "How are things" "/var/lib/lmtp/last-msg.txt"
}

################################################################################
main "$@"
