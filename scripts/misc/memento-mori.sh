#!/usr/bin/env bash

set -eu
set -o pipefail

dir=~/documents/pictures/backgrounds/Memento-Mori

if [ ! -d "$dir" ]; then
  notify-send "Missing directory $dir"
  echo >&2 "ERROR: missing directory $dir"
  exit 1
fi

cd "$dir" || exit 1

feh \
  --scale-down \
  --image-bg black \
  --randomize \
  --recursive \
  --slideshow-delay 300 \
  --title "Memento Mori: %n" \
  .
