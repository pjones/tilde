# This is a NixOS module:
{ config, lib, pkgs, ... }:

{
  imports = [
    ./generic-nixos.nix
  ];

  config = {
    networking.hostName = "elphaba";

    tilde = {
      xsession.enable = true;
      workstation.type = "laptop";

      workstation.kmonad = {
        enable = true;
        keyboards = {
          internal.device = "/dev/input/by-path/platform-i8042-serio-0-event-kbd";
        };
      };
    };

    home-manager.users.pjones = { ... }: {
      tilde.programs.emacs.enable = true;

      tilde.programs.ssh = {
        keysDir = "~/keys/ssh";
        haveRestrictedKeys = true;
      };
    };
  };
}
