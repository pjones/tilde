#!/usr/bin/env bash

set -eu
set -o pipefail

declare -a online
declare -a offline

check_device() {
  local device=$1

  echo "=> checking device $device"

  if l2ping -c 1 "$device" >/dev/null 2>&1; then
    online+=("$device")
    echo "==> $device is online"
  else
    offline+=("$device")
    echo "==> $device is offline"
  fi
}

update_file() {
  local file=$1
  shift
  local entries=("${@}")

  if [ "${#entries[@]}" -eq 0 ]; then
    rm -f "$file"
  else
    for entry in "${entries[@]}"; do
      echo "$entry"
    done >"$file"
  fi
}

record_status() {
  local directory=$1

  mkdir -p "$directory"
  update_file "$directory/offline" "${offline[@]}"
  update_file "$directory/online" "${online[@]}"
}

main() {
  local config=$1
  local devices
  local directory

  if [ ! -e "$config" ]; then
    echo >&2 "ERROR: no such configuration file: $config"
    exit 1
  fi

  directory=$(jq -r .directory <"$config")
  readarray -t devices < <(jq -r '.devices|join("\n")' <"$config")

  for device in "${devices[@]}"; do
    check_device "$device"
  done

  record_status "$directory"
}

main "$@"
