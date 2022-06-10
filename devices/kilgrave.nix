# This is a NixOS module:
{ config, lib, pkgs, ... }:

{
  imports = [
    ./generic-nixos.nix
  ];

  config = {
    networking.hostName = "kilgrave";

    home-manager.users.pjones = { ... }: {
      services.syncthing.enable = true;
    };
  };
}
