#!/usr/bin/env bash

set -eu
set -o pipefail
set -o allexport

# Need this to run systemctl:
export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/1000/bus"

# Load environment variables from the systemd:
# shellcheck disable=1090
source <(systemctl --user show-environment | grep -E 'SOCK|XDG')

# Send all output to the systemd journal:
exec > >(systemd-cat -t test-lock-screen -p emerg) 2>&1

# Lock it!
niri msg action spawn -- loginctl lock-session
