#!/usr/bin/env bash

# Start all idle inhibitors after waking the screen.

set -eu
set -o pipefail

# Playing audio should prevent idle:
systemctl --user start wayland-pipewire-idle-inhibit.service
