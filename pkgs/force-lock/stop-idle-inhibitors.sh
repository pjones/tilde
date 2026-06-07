#!/usr/bin/env bash

# Stop all idle inhibitors so the screen can go blank.

set -eu
set -o pipefail

# Playing audio can prevent idle:
systemctl --user stop wayland-pipewire-idle-inhibit.service
