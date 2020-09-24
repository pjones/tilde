# This is a NixOS module:
{ config, lib, pkgs, ... }:
let
  sources = import ../nix/sources.nix;

in
{
  imports = [
    "${sources.home-manager}/nixos"
    ../nixos
  ];

  tilde = {
    enable = true;
    putInWheel = true;
  };

  home-manager = {
    backupFileExtension = "backup";
    useUserPackages = true;

    users.${config.tilde.username} = { ... }: {
      imports = [ ./generic-linux.nix ];
    };
  };
}
