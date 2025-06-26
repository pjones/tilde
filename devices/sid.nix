{ self # Flake reference.
}:

# This is a NixOS module:
{ config, lib, pkgs, ... }:

{
  imports = [
    ./generic-nixos.nix
  ];

  config = {
    networking.hostName = "sid";

    services.kmonad = lib.mkIf (pkgs.system == "x86_64-linux") {
      enable = true;

      keyboards.internal = {
        device = "/dev/input/by-path/platform-i8042-serio-0-event-kbd";
        config = builtins.readFile ../support/keyboard/us_60.kbd;

        defcfg = {
          enable = true;
          fallthrough = true;
          compose.key = "compose";
        };
      };
    };

    services.logind =
      let ignore = lib.mkForce "ignore"; in {
        lidSwitch = ignore;
        lidSwitchDocked = ignore;
        lidSwitchExternalPower = ignore;
      };

    tilde = {
      crontab = {
        image-import = {
          schedule = "*-*-* 00/4:15:00";
          path = [ pkgs.pjones.image-scripts ];
          script = "image-import";
        };
      };
    };

    home-manager.users.pjones = { ... }: {
      tilde.programs.beets.enable = true;
      tilde.programs.emacs.enable = true;
      tilde.programs.syncthing.enable = true;

      tilde.programs.ssh = {
        keysDir = "~/keys/ssh";
        haveRestrictedKeys = true;
      };
    };
  };
}
