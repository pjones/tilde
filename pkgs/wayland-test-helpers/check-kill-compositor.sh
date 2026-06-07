#!/usr/bin/env bash

set -eux
set -o pipefail
set -o allexport

# Need this to run systemctl:
export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/1000/bus"

# Load environment variables from the systemd:
# shellcheck disable=1090
source <(systemctl --user show-environment | grep -E 'SOCK|XDG')

# Send all output to the systemd journal:
# exec > >(systemd-cat -t "$(basename "$0")" -p emerg) 2>&1

function wait_until_succeeds() {
  count=300

  while [ "$count" -gt 0 ]; do
    if eval "$*"; then
      break
    fi

    sleep 1
    count=$((count - 1))
  done
}

function wait_until_fails() {
  wait_until_succeeds "! ( $* )"
}

niri msg action quit --skip-confirmation || :
wait_until_fails pgrep -x niri

if [ "${COMPOSITOR_VERIFY_EXIT:-0}" -eq 1 ]; then
  wait_until_succeeds test -e /tmp/compositor-exit-ok
fi
