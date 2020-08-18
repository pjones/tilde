{ config, lib, pkgs, ... }:

{
  imports = [
    ./generic-nixos.nix
  ];

  home-manager.users.pjones = { ... }: {
    tilde.programs.neuron.enable = true;
    services.syncthing.enable = true;
  };
}
