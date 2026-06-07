#!/usr/bin/env bash

################################################################################
# A much simpler version of rofi-pass, a tool to select passwords via
# rofi.  My version only uses the clipboard which works better in my
# experience than auto typing.
#
# Usage:
#
#  * Select a password and press Return to copy it to the clipboard
#
#  * Select a password and press Control+Return to copy a field from
#    the password file instead.

################################################################################
export PASSWORD_STORE_DIR=${PASSWORD_STORE_DIR:-$HOME/.password-store}

################################################################################
notify() {
  notify-send \
    --expire-time=1000 \
    --app-name=rofi \
    --icon=dialog-password \
    "Password" "$@"
}

################################################################################
show_passwords() {
  while IFS= read -r -d '' file; do
    echo -en "$file\0icon\x1fapplication-certificate\n"
  done < <(
    find "$PASSWORD_STORE_DIR" \
      -type f \
      -name '*.gpg' \
      -printf "%P\0" |
      sed --null-data 's/\.gpg$//'
  )
}

################################################################################
clip_password() {
  local password=$1

  pass show --clip "$password" &&
    notify "Copied $(basename "$password")"
}

################################################################################
clip_field() {
  local password=$1
  local field=$2

  pass show "$password" |
    tail --lines=+3 |
    awk --assign field="$field" \
      --field-separator ': ' \
      '$1 == field {print $2}' |
    tr -d "\n" | wl-copy

  notify "Copied $field from $(basename "$password")"
}

################################################################################
# The mapfile weirdness in here is to ensure that *if* a PIN entry
# dialog needs to appear, that will happen *before* rofi has a chance
# to grab the keyboard.
#
# Without this, rofi will grab the keyboard and then when the PIN
# entry dialog appears you won't be able to interact with it.  And
# since rofi still holds the keyboard grab, the entire window manager
# is frozen.
field_prompter() {
  local password=$1

  declare -a fields
  mapfile -t fields < <(
    pass show "$password" |
      tail --lines=+3 |
      sed --silent \
        --expression '/^ *$/q' \
        --expression 's/:.*//p'
  )

  result=$({
    for field in "${fields[@]}"; do
      echo -en "$field\0icon\;x1fapplication-certificate-symbolic\n"
    done
  } | @out@/bin/rofi-wrapper.sh -dmenu \
    -i -only-match -no-custom \
    -select user)

  if [ -n "$result" ]; then
    clip_field "$password" "$result"
  fi
}

################################################################################
# Here's where things start:
if [ $# -eq 0 ]; then
  echo -en "\0use-hot-keys\x1ftrue\n"
  show_passwords
else
  if [ "$ROFI_RETV" -eq 10 ]; then
    coproc field_prompter "$1" >/dev/null 2>&1
  else
    coproc clip_password "$1" >/dev/null 2>&1
  fi
fi
