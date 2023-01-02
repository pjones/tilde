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
          --output DisplayPort-0 --auto --primary \
          --output HDMI-0 --auto --right-of DisplayPort-0 --rotate left | :
      '';
    };
  };
}
