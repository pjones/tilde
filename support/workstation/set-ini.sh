#!/usr/bin/env bash

# Ensure some INI settings are correct.

set -eu
set -o pipefail

ksnip="$HOME/.config/ksnip/ksnip.conf"
mkdir -p "$(dirname "$ksnip")"
crudini --set "$ksnip" Application SaveDirectory "$HOME/documents/pictures/screenshots/\$Y"
crudini --set "$ksnip" Application SaveFilename "Screenshot_\$Y\$M\$D_\$T"
crudini --set "$ksnip" ImageGrabber CaptureCursor false
crudini --set "$ksnip" ImageGrabber CaptureDelay 2000
