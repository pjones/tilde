# Return Peter's Package Collection:
{ pkgs }:

with pkgs.lib;

let
  attrs = removeAttrs (importJSON ./pkgs.json) [ "date"];
  repo  = pkgs.fetchgit attrs;
  boot  = import "${repo}/default.nix" { inherit pkgs; };

in boot.pjones
