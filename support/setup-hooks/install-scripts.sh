# shellcheck shell=bash

# $1: The output directory
# $2: The directory of scripts to install
# $3: The PATH prefix to use.
installScripts() {
  out=$1
  input_dir=$2
  path_prefix=$3

  mkdir -p "$out/bin" "$out/scripts"

  for script in "$input_dir"/*; do
    name=$(basename "$script")
    install -m0555 "$script" "$out/scripts/$name"

    makeWrapper "$out/scripts/$name" "$out/bin/$name" \
      --prefix PATH : "$path_prefix"
  done
}
