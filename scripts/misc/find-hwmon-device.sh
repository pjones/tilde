#!/usr/bin/env bash

################################################################################
set -eu
set -o pipefail

################################################################################
option_sensor_link_dir=/sys/class/hwmon
option_sensor_name=coretemp.0

################################################################################
usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

  -h      This message
  -s NAME The name of the sensor to find

EOF
}

################################################################################
main() {
  for link in "$option_sensor_link_dir"/*; do
    real=$(realpath "$link")

    if grep --quiet --fixed-strings "/$option_sensor_name/" <<<"$real"; then
      echo "$real"
      exit
    fi
  done

  # No match found:
  exit 1
}

################################################################################
while getopts "hs:" o; do
  case "${o}" in
  h)
    usage
    exit
    ;;

  s)
    option_sensor_name=$OPTARG
    ;;

  *)
    exit 1
    ;;
  esac
done

shift $((OPTIND - 1))
main
