# This is a NixOS module:
{ config, lib, pkgs, ... }:

{
  imports = [
    ./generic-nixos.nix
  ];

  tilde.xsession.enable = true;
  tilde.workstation.type = "laptop";

  home-manager.users.pjones = { ... }: {
    tilde.programs.grobi.name = config.networking.hostName;
    tilde.programs.ssh.keysDir = "~/keys/ssh";

    tilde.programs.polybar = {
      power.enable = true;
      backlight.enable = true;
    };
  };
}
