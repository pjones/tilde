#!/usr/bin/env bash

exec rofi \
  -config "@out@/etc/config.rasi" \
  "$@"
