# This is a NixOS module:
{ config, lib, pkgs, ... }:
{
  networking.domain = lib.mkDefault "pmade.com";

  tilde = {
    enable = true;
    putInWheel = true;

    crontab = {
      # All machines should have their download directory cleaned
      # periodically:
      clean-download-directory = {
        schedule = "daily";
        path = [ pkgs.pjones.maintenance-scripts ];
        script = ''
          if [ -d "$HOME/download" ]; then
            delete-older-files.sh "$HOME/download"
          fi
        '';
      };
    };
  };
}
