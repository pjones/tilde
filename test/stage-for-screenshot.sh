#!/usr/bin/env bash

set -eux
set -o pipefail

feh --bg-fill --no-fehbg /tmp/wallpaper.jpg
xdotool mousemove 0 0

herbstclient lock
herbstclient attr theme.title_height 0

for i in $(herbstclient list_monitors | cut -d: -f1); do
  herbstclient chain \
    , attr monitors."$i".pad_up 100 \
    , attr monitors."$i".pad_down 100 \
    , attr monitors."$i".pad_left 100 \
    , attr monitors."$i".pad_right 100
done

herbstclient \
  chain \
  , set frame_border_width 0 \
  , set frame_border_inner_width 0 \
  , set frame_transparent_width 0

herbstclient unlock

konsole --hold -e neofetch
