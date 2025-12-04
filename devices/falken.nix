{ self # Flake reference.
}:

# This is a NixOS module:
{ ... }:

{
  imports = [
    ./generic-nixos.nix
    self.inputs.superkey.nixosModules.falken
  ];

  config = {
    networking.hostName = "falken";

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

    tilde = {
      workstation.type = "laptop";
      graphical.enable = true;
      programs.qmk.enable = true;
    };

    home-manager.users.pjones = { ... }: {
      tilde.programs.beets.enable = true;
      tilde.programs.emacs.enable = true;
      tilde.programs.ssh.keysDir = "~/keys/ssh";
    };
  };
}
