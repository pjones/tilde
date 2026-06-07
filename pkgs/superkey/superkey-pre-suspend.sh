#!/usr/bin/env bash

################################################################################
# Secure a machine before it is suspended.
set -eu
set -o pipefail

################################################################################
# Remove SSH keys from the agent:
if [ -e "${SSH_AUTH_SOCK:=${XDG_RUNTIME_DIR:=/run/user/$(id -u)}/ssh-agent}" ]; then
  export SSH_AUTH_SOCK
  ssh-add -D || :
fi

# Kill gpg-agent so all passphrases are cleared:
pkill gpg-agent || :

# Lock the password vault:
if type -P rbw >/dev/null; then
  rbw lock || :
fi
