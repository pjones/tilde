# Configure IPFS:
{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.pjones;

in
{
  config = mkIf cfg.isWorkstation {
    networking.firewall = {
      allowedTCPPorts = [
        4001 # IPFS Swarm.
      ];
    };

    services.ipfs = {
      enable = true;
      autoMount = true;
    };
  };
}
