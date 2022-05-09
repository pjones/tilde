#!/usr/bin/env bash

set -eu
set -o pipefail

L2PING_BIN=${L2PING_BIN:-l2ping}
L2PING_COUNT=${L2PING_COUNT:-1}

declare -a online
online=()

check_device() {
  local device=$1

  echo "=> checking device $device"

  if "$L2PING_BIN" -c "$L2PING_COUNT" "$device" >/dev/null 2>&1; then
    online+=("$device")
    echo "$device is online"
  else
    echo "$device is offline"
  fi
}

main() {
  for device in "$@"; do
    check_device "$device"
  done

  if [ "${#online[@]}" -eq 0 ]; then
    exit 1
  fi
}

main "$@"
