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

    tilde.programs.polybar = {
      sensorPath = "/sys/devices/platform/coretemp.0/hwmon/hwmon4/temp1_input";
    };
  };
}
