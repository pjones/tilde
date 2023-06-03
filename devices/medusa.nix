# This is a NixOS module:
{ config, lib, pkgs, ... }:

{
  imports = [
    ./generic-nixos.nix
  ];

  config = {
    networking.hostName = "medusa";

    tilde = {
      xsession.enable = true;

      crontab = {
        image-import = {
          schedule = "*-*-* 01:15:00";
          path = [ pkgs.pjones.image-scripts ];
          script = "image-import -v";
        };

        generate-wiki = {
          schedule = "*-*-* 04:30:00";
          path = [ pkgs.nix pkgs.git ];
          script = "cd ~/notes && nix run";
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

        rfa = {
          enable = true;
          vpnJumpHost = "192.168.122.95";
        };
      };

      xsession.initExtra = ''
        xrandr \
          --output DP-1 --auto --primary \
          --output HDMI-1 --mode 2560x1440 --rate 59.95 --right-of DP-1
      '';
    };
  };
}
