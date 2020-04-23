# Start syncthing and open the firewall.
{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.pjones;

in
{
  config = mkIf cfg.isWorkstation {
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
