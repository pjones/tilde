#!/usr/bin/env bash

set -eux
set -o pipefail

################################################################################
function main() {
  test "$(count_msgs)" -eq 0

  send_mail
  test "$(count_msgs)" -eq 1

  if send_mail "other@example.test"; then
    echo >&2 "ERROR: should not accept mail for this user"
    exit 1
  fi
}

################################################################################
main "$@"
