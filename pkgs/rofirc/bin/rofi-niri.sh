#!/usr/bin/env bash

set -eu
set -o pipefail

rofi_wrapper="@out@/bin/rofi-wrapper.sh"

action=$(
  niri msg --json action --help |
    grep -E '^  [a-z-]+$' |
    tr -d ' ' |
    grep -Ev '^quit$' |
    $rofi_wrapper -dmenu
)

# shellcheck disable=2086
niri msg action $action
