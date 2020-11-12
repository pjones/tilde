#!/usr/bin/env bash

# Create a ~/.manpath configuration file and then invoke mandb(1) to
# create a database of manual pages.

set -eu
set -o pipefail

cache_dir=$1
manpath=$HOME/.manpath

_PATH=
_MANPATH=

rm -rf "$manpath" "$cache_dir"
cat /etc/man_db.conf >>"$manpath"
mkdir -p "$cache_dir"

for profile in $NIX_PROFILES; do
  name=$(
    echo "$profile" |
      sed -E -e 's|^/||' -e 's|[^a-zA-Z0-9]+|-|g'
  )

  _PATH=$profile/bin:$profile/sbin${_PATH:+:$_PATH}
  _MANPATH=$profile/share/man${_MANPATH:+:$_MANPATH}

  {
    echo
    echo "# From profile $profile:"
    echo "MANPATH_MAP $profile/bin $profile/share/man"
    echo "MANPATH_MAP $profile/sbin $profile/share/man"
    echo "MANDB_MAP $profile/share/man $cache_dir/$name"
  } >>"$manpath"
done

# Build the cache in the background.
nohup \
  env PATH="$_PATH" MANPATH="$_MANPATH" \
  mandb \
  --create \
  --user-db \
  --config-file="$manpath" &
