{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.pjones;

in
{
  config = mkIf cfg.putInWheel {
    users.users.pjones.extraGroups = [
      "wheel"
    ];
  };
}
