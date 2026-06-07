#!/usr/bin/env bash

################################################################################
set -eu
set -o pipefail

################################################################################
main() {
  niri msg action do-screen-transition --delay-ms 150
  niri msg action move-workspace-to-monitor-next
  niri msg action focus-workspace-previous
  niri msg action move-workspace-to-monitor-previous
}

################################################################################
main "$@"
