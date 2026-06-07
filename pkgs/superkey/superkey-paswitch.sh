#!/usr/bin/env bash

################################################################################
# Switch the default audio output device to the next device.
set -eu
set -o pipefail

################################################################################
# What audio server is running (PulseAudio or PipeWire).  Detected in
# the `main` function.
server=PulseAudio

################################################################################
get_sinks() {
  if [ "$server" = PipeWire ]; then
    pw-dump |
      jq '.[] | select(.info.props."media.class" == "Audio/Sink") | .id'
  else
    pacmd list-sinks |
      sed 's|*||' |
      awk '$1 == "index:" {print $2}'
  fi
}

################################################################################
get_current_default_sink_id() {
  if [ "$server" = PipeWire ]; then
    local name
    name=$(pw-dump |
      jq -r \
        '.[] |
         select(.type == "PipeWire:Interface:Metadata") |
         .metadata[] |
         select(.key == "default.configured.audio.sink") |
         .value |
         .name')
    pw-dump |
      jq --arg name "$name" \
        '.[] | select(.info.props."node.name" == $name) | .id'
  else
    pacmd list-sinks |
      awk '$1 == "*" && $2 == "index:" {print $3}'
  fi
}

################################################################################
get_sink_name() {
  local sink_id=$1

  if [ "$server" = PipeWire ]; then
    pw-dump |
      jq -r --argjson id "$sink_id" \
        '.[] | select(.id == $id) | .info.props."node.description"'
  else
    pacmd list-sinks |
      awk '$1 == "device.description" {print substr($0,5+length($1 $2))}' |
      sed 's|"||g' | awk -F"," 'NR==v1{print$0}' v1="$((sink_id + 1)))"
  fi
}

################################################################################
# NOTE: This returns an icon name that doesn't exist in my icon theme :(
get_sink_icon() {
  local sink_id=$1

  if [ "$server" = PipeWire ]; then
    local device
    device=$(pw-dump |
      jq -r --argjson id "$sink_id" \
        '.[] | select(.id == $id) | .info.props."device.id"')
    pw-dump |
      jq -r --argjson id "$device" \
        '.[] | select(.id == $id) | .info.props."device.icon-name"'
  else
    echo "speaker"
  fi
}

################################################################################
set_default_sink() {
  local sink_id=$1
  local sink_name
  local sink_icon

  sink_name=$(get_sink_name "$sink_id")
  sink_icon=audio-speakers

  if [ "$server" = PipeWire ]; then
    wpctl set-default "$sink_id"
  else
    pacmd "set-default-sink $sink_id"
  fi

  send_notification \
    -i "${sink_icon:-speaker}" \
    "Default sink changed to $sink_name"
}

################################################################################
send_notification() {
  local args=("$@")
  local body=${args[${#args[@]} - 1]}

  unset "args[-1]"

  notify-send \
    -a "$server" \
    "${args[@]}" \
    "$server" \
    "$body"
}

################################################################################
main() {
  declare -a sinks=()
  local current_default=""
  local next_default=""
  local sink_id=""
  local pick_next_sink=0

  if type pw-dump >/dev/null 2>&1; then
    server=PipeWire
  fi

  mapfile -t sinks < <(get_sinks)
  current_default=$(get_current_default_sink_id)

  for sink_id in "${sinks[@]}"; do
    if [ "$sink_id" = "$current_default" ]; then
      pick_next_sink=1
    elif [ "$pick_next_sink" -eq 1 ]; then
      next_default=$sink_id
      break
    fi
  done

  if [ -n "$next_default" ]; then
    set_default_sink "$next_default"
  elif [ "${#sinks[@]}" -gt 1 ]; then
    set_default_sink "${sinks[0]}"
  else
    send_notification \
      -i settings \
      -u critical \
      -t 5000 \
      "Nothing to switch, system only has one sound card."
  fi
}

################################################################################
main "$@"
