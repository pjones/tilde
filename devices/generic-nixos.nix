# This is a NixOS module:
{ config, lib, pkgs, ... }:
let
  sources = import ../nix/sources.nix;

in
{
  imports = [
    "${sources.home-manager}/nixos"
    ../nixos
  ];

  tilde = {
    enable = true;
    putInWheel = true;

    crontab =
      let
        maintenance-scripts =
          pkgs.callPackage sources."pjones/maintenance-scripts" { };
      in
      {
        # All machines should have their download directory cleaned
        # periodically:
        clean-download-directory = {
          schedule = "daily";
          path = [ maintenance-scripts ];
          script = ''
            if [ -d "$HOME/download" ]; then
              delete-older-files.sh "$HOME/download"
            fi
          '';
        };
      };
  };

  home-manager = {
    backupFileExtension = "backup";
    useUserPackages = true;

    users.${config.tilde.username} = { ... }: {
      imports = [ ./generic-linux.nix ];
    };
  };
}
