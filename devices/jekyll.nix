{ self # Flake reference.
}:

# This is a NixOS module:
{ config, lib, pkgs, ... }:

{
  imports = [
    ./generic-nixos.nix
    self.inputs.superkey.nixosModules.jekyll
  ];

  config = {
    networking.hostName = "jekyll";

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

    tilde = {
      workstation.type = "laptop";
      graphical.enable = true;
      programs.qmk.enable = true;
      programs.android.enable = true;
    };

    home-manager.users.pjones = { ... }: {
      tilde.programs.emacs.enable = true;
      tilde.programs.haskell.enable = true;
      tilde.programs.oled-display.enable = false;

      tilde.programs.ssh = {
        keysDir = "~/keys/ssh";
        haveRestrictedKeys = true;
      };
    };
  };
}
