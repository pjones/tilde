# This is a home-manager module:
{ pkgs, ... }:
let
  packages = import ../home/programs/base.nix { inherit pkgs; };
in
{
  home.packages = packages.linux;
}
