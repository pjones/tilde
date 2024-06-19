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
        config = builtins.readFile ../support/keyboard/us_60.kbd;

        defcfg = {
          enable = true;
          fallthrough = true;
        };
      };
    };

    tilde = {
      workstation.type = "laptop";
    };

    home-manager.users.pjones = { ... }: {
      tilde.programs.emacs.enable = true;
      tilde.programs.haskell.enable = true;

      tilde.programs.ssh = {
        keysDir = "~/keys/ssh";
        haveRestrictedKeys = true;
      };

      # For remote file editing:
      programs.ssh.matchBlocks.medusa = {
        hostname = "medusa.private.pmade.com";
        port = 4;
        forwardAgent = true;
        forwardX11 = true;
        forwardX11Trusted = true;
      };
    };
  };
}
