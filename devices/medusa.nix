# This is a NixOS module:
{ config, lib, pkgs, ... }:

{
  imports = [
    ./generic-nixos.nix
  ];

  config = {
    networking.hostName = "medusa";

    tilde = {
      crontab = {
        image-import = {
          schedule = "*-*-* 01:15:00";
          path = [ pkgs.pjones.image-scripts ];
          script = "image-import -v";
        };
      };
    };

    home-manager.users.pjones = { ... }: {
      tilde.programs.emacs.enable = true;
      tilde.programs.haskell.enable = true;
      tilde.programs.oled-display.enable = true;
      tilde.programs.oled-display.arduino.enable = true;

      tilde.programs.ssh = {
        keysDir = "~/keys/ssh";
        haveRestrictedKeys = true;
      };

      xsession.initExtra = ''
        xrandr \
          --output DP-1 --auto --primary \
          --output HDMI-1 --mode 2560x1440 --rate 59.95 --right-of DP-1
      '';
    };
  };
}
