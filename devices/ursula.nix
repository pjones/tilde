{ self # Flake reference.
}:

# This is a NixOS module:
{ config, lib, pkgs, ... }:

{
  imports = [
    ./generic-nixos.nix
  ];

  config = {
    networking.hostName = "ursula";

    home-manager.users.pjones = { ... }: {
      tilde.programs.syncthing.enable = true;
    };
  };
}
