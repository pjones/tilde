#!/bin/sh

# Wrapper around rofi:
exec @out@/bin/rofi-wrapper.sh \
  -show workspace \
  -kb-accept-custom "" \
  -kb-custom-1 "Control+Return" \
  "$@"
