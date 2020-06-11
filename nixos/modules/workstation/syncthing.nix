# Start syncthing and open the firewall.
{ config, pkgs, lib, ... }:

with lib;

let cfg = config.pjones;

in {
  #### Interface:
  options.pjones.syncthing = { enable = mkEnableOption "Syncthing"; };

  #### Implementation:
  config = mkIf (cfg.isWorkstation || cfg.syncthing.enable) {
    networking.firewall = {
      allowedTCPPorts = [
        22000 # Syncthing
      ];

      allowedUDPPorts = [
        21027 # Syncthing
      ];
    };

    home-manager.users.pjones = { config, ... }: {
      services.syncthing.enable = true;
    };
  };
}
