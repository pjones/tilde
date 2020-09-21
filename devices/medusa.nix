# This is a NixOS module:
{ config, lib, pkgs, ... }:

{
  imports = [
    ./generic-nixos.nix
  ];

  tilde.xsession.enable = true;

  home-manager.users.pjones = { ... }: {
    tilde.programs.oled-display.arduino.enable = true;
    tilde.programs.grobi.name = config.networking.hostName;
    tilde.programs.ssh.keysDir = "~/keys/ssh";

    tilde.xsession.lock = {
      bluetooth.devices = [
        "80:86:D9:3A:A9:BB"
      ];
    };
  };
}
