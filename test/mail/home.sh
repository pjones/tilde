#!/usr/bin/env bash

set -eux
set -o pipefail

################################################################################
function mail_config_test() {
  local mailjson=~/.config/tilde/mail.json
  local imapyml=~/.config/goimapnotify/goimapnotify.yaml

  test -e "$mailjson"
  test -e "$imapyml"
  test -d ~/.cache/mu

  domain=$(
    jq --raw-output \
      '."example.com" | .imapServer | .domain' \
      <"$mailjson"
  )

  test "$domain" = "localhost"

  host=$(
    jq --raw-output \
      '.configurations[] | .host' \
      <"$imapyml"
  )

  test "$host" = "localhost"
}

################################################################################
function msmtp_send_msg() {
  local from=$1
  test_message | msmtp --pretend --from "$from"
}

################################################################################
function msmtp_test() {
  test -e ~/.config/msmtp/config
  msmtp_send_msg "buddy@example.com" | grep "account chosen by envelope"
  msmtp_send_msg "busted@localhost" | grep "falling back to default account"
}

################################################################################
function mail_workflow_test() {
  send_mail
  wait_for_file ~/mail/example.com/Inbox/new
  wait_until_fails pgrep -u "$USER" mbsync
  wait_until_fails pgrep -u "$USER" mu

  # Find the new email:
  file_orig=$(mu find "from:other@example.com" --fields="l")
  test -e "$file_orig"

  # Move the email to the trash:
  file_trash=$(
    mu move \
      --change-name \
      --flags=-N \
      "$file_orig" \
      /example.com/Trash
  )
  test ! -e "$file_orig"
  test -e "$file_trash"

  systemctl --user start --wait mbsync-example.com.service
  test "$(count_msgs Trash)" -eq 1
  test "$(count_msgs INBOX)" -eq 0
}

################################################################################
function main() {
  mail_config_test
  msmtp_test
  mail_workflow_test
  touch "$HOME/mail-test-success"
}

################################################################################
main "$@"
