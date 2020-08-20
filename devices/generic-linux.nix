# This is a home-manager module:
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    bind # For dig(1)
    binutils
    file
    inetutils
    inotify-tools
    psmisc
  ];
}
