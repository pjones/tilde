{ config, pkgs, lib, ... }:

let
  cfg = config.tilde.programs.syncthing;
in
{
  options.tilde.programs.syncthing = {
    enable = lib.mkEnableOption "Syncthing File Synchronization";
  };

  config = lib.mkIf cfg.enable {
    services.syncthing = {
      enable = true;

      extraOptions = [
        "--gui-address=0.0.0.0:8384" # Safe thanks to the firewall.
        "--no-default-folder"
      ];
    };
  };
}
