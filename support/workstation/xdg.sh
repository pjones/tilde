#!/bin/sh

################################################################################
PATH=/run/current-system/sw/bin:$PATH

################################################################################
# XDG variables.
export XDG_CONFIG_HOME=$HOME/.config
export XDG_DESKTOP_DIR=$HOME/desktop
export XDG_DOWNLOAD_DIR=$HOME/download
export XDG_DOCUMENTS_DIR=$HOME/documents
export XDG_MUSIC_DIR=$HOME/documents/music
export XDG_PICTURES_DIR=$HOME/documents/pictures
export XDG_PUBLICSHARE_DIR=$HOME/htdocs
export XDG_TEMPLATES_DIR=$HOME/documents/templates
export XDG_VIDEOS_DIR=$HOME/documents/videos

################################################################################
# Write them out to a file:
cat <<EOF > ~/.config/user-dirs.dirs
XDG_CONFIG_HOME="$XDG_CONFIG_HOME"
XDG_DESKTOP_DIR="$XDG_DESKTOP_DIR"
XDG_DOWNLOAD_DIR="$XDG_DOWNLOAD_DIR"
XDG_DOCUMENTS_DIR="$XDG_DOCUMENTS_DIR"
XDG_MUSIC_DIR="$XDG_MUSIC_DIR"
XDG_PICTURES_DIR="$XDG_PICTURES_DIR"
XDG_PUBLICSHARE_DIR="$XDG_PUBLICSHARE_DIR"
XDG_TEMPLATES_DIR="$XDG_TEMPLATES_DIR"
XDG_VIDEOS_DIR="$XDG_VIDEOS_DIR"
EOF
