{
  self, # Flake reference.
}:

# This is a NixOS module:
{ lib, pkgs, ... }:

{
  imports = [ ./generic-nixos.nix ];

  config = {
    networking.hostName = "sid";

    services.kmonad = {
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

    # Ignore all lid switch events:
    services.logind.settings.Login =
      let
        ignore = lib.mkForce "ignore";
        keys = [
          "HandleLidSwitch"
          "HandleLidSwitchDocked"
          "HandleLidSwitchExternalPower"
        ];
      in
      builtins.listToAttrs (
        map (key: {
          name = key;
          value = ignore;
        }) keys
      );

    tilde = {
      crontab = {
        image-import = {
          schedule = "*-*-* 00/4:15:00";
          path = [ pkgs.pjones.image-scripts ];
          script = "image-import";
        };
      };
    };

    home-manager.users.pjones =
      { ... }:
      {
        tilde.programs.beets.enable = true;
        tilde.programs.emacs.enable = true;
        tilde.programs.ssh.keysDir = "~/keys/ssh";
        tilde.programs.syncthing.enable = true;
      };
  };
}
