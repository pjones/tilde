#!/usr/bin/env bash

set -eux
set -o pipefail

# Send all output to the systemd journal:
exec > >(systemd-cat -t stage-screen -p emerg) 2>&1

# Verify that the `e' script can connect to the daemon:
count=10

while [ "$count" -gt 0 ]; do
  if [ "$(e -d -- --eval nil || :)" = "nil" ]; then
    break
  fi

  count=$((count - 1))
  sleep 2
done

# If this script was already run then we need to delete the existing
# buffers so everything works as expected:
e -- --eval '
  (let ((buffers (list "issue" "fastfetch")))
    (dolist (name buffers)
      (when-let ((buffer (get-buffer name)))
        (kill-buffer buffer))))
'

# Disable the echo area to make things prettier:
e -- --eval '(setq inhibit-message t)'

# Work around a long standing bug in my Emacs configuration where
# my `eterm' script can't open a window if the terminal window would
# be the first one loaded by the daemon.
e -c '/etc/issue' && sleep 1
eterm -ke fastfetch && sleep 1

# Move some windows around:
niri msg action focus-column-left-or-last
niri msg action close-window
niri msg action set-column-width 66%
niri msg action center-window

# Move point back to the first character so the entire output from
# fastfetch is visible:
e -- --eval '
(with-current-buffer "fastfetch"
  (goto-char 0))
'

# Done.
touch /tmp/stage-for-screenshot
