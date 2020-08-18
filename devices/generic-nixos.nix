{ config, lib, pkgs, ... }:
let
  sources = import ../nix/sources.nix;

in
{
  imports = [
    "${sources.home-manager}/nixos"
  ];

  tilde = {
    enable = true;
    putInWheel = true;
  };

  home-manager = {
    backupFileExtension = "backup";
    useUserPackages = true;
  };
}
