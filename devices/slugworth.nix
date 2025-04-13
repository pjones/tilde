{ self # Flake reference.
}:

# This is a NixOS module:
{ config, lib, pkgs, ... }:

{
  imports = [
    ./generic-nixos.nix
  ];

  config = {
    networking.hostName = "slugworth";

    home-manager.users.pjones = { ... }: {
      tilde.programs.syncthing.enable = true;
    };
  };
}
