#!/usr/bin/env bash

################################################################################
# Print the name of a random file.
#
# Useful for selecting a random image for a lock screen or wallpaper
# setting application.

################################################################################
set -e
set -u

################################################################################
option_dir=$(pwd)
option_glob="[!.]*"
option_default=
option_images=0

################################################################################
usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

  -d DIR  Pick a file from DIR [default: pwd]
  -D FILE Default file if no files are in DIR
  -g GLOB Name glob passed to find(1)
  -i      Find image files (disables -g)
  -h      This message

EOF
}

################################################################################
while getopts "D:d:g:hi" o; do
  case "${o}" in
  d)
    option_dir=$OPTARG
    ;;

  D)
    option_default=$OPTARG
    ;;

  g)
    option_glob=$OPTARG
    ;;

  h)
    usage
    exit
    ;;

  i)
    option_images=1
    ;;

  *)
    exit 1
    ;;
  esac
done

shift $((OPTIND - 1))

################################################################################
if [ ! -d "$option_dir" ]; then
  if [ -n "$option_default" ]; then
    realpath "$option_default"
    exit
  else
    exit 1
  fi
fi

glob=()

if [ "$option_images" -eq 1 ]; then
  glob+=('-iregex' '.*\(png\|jpg\)$')
else
  glob+=("-iname" "$option_glob")
fi

file=$(
  find -L \
    "$option_dir" \
    '(' -name '.*' -prune ')' -or '(' \
    '(' -type f -or -type l ')' -and \
    "${glob[@]}" -print ')' |
    shuf -n 1
)

if [ -n "$file" ]; then
  realpath "$file"
elif [ -n "$option_default" ]; then
  realpath "$option_default"
else
  exit 1
fi
