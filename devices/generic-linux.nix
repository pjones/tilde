# This is a home-manager module:
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    inotify-tools
  ];
}
