#!/bin/sh

set -e
set -u

top=$(realpath "$(dirname "$0")/..")

nix-build \
  --no-out-link \
  --no-build-output \
  --keep-going \
  --max-jobs auto \
  -A pjones \
  "$top/pkgs"
