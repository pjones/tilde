{ config, lib, pkgs, ... }:

{
  imports = [
    ./generic-nixos.nix
  ];

  tilde.xsession.enable = true;
  tilde.workstation.type = "laptop";

  home-manager.users.pjones = { ... }: {
    tilde.programs.grobi.name = config.networking.hostName;

    tilde.programs.polybar = {
      sensorPath = "/sys/devices/platform/coretemp.0/hwmon/hwmon4/temp1_input";
      power.enable = true;
      backlight.enable = true;
    };
  };
}
