# This is a NixOS module:
{ config, lib, pkgs, ... }:

{
  imports = [
    ./generic-nixos.nix
  ];

  config = {
    networking.hostName = "elphaba";

    services.kmonad = lib.mkIf (pkgs.system == "x86_64-linux") {
      enable = true;
      keyboards.internal = {
        device = "/dev/input/by-path/platform-i8042-serio-0-event-kbd";
        fallthrough = true;
        config = builtins.readFile ../support/keyboard/us_60.kbd;
      };
    };

    tilde = {
      xsession.enable = true;
      workstation.type = "laptop";
    };

    home-manager.users.pjones = { ... }: {
      tilde.programs.emacs.enable = true;
      tilde.programs.haskell.enable = true;

      tilde.programs.ssh = {
        keysDir = "~/keys/ssh";
        haveRestrictedKeys = true;
      };
    };
  };
}
