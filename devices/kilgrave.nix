# This is a NixOS module:
{ config, lib, pkgs, ... }:

{
  imports = [
    ./generic-nixos.nix
  ];

  config = {
    networking.hostName = "kilgrave";

    home-manager.users.pjones = { ... }: {
      tilde.programs.neuron.enable = true;
      services.syncthing.enable = true;
    };
  };
}
