# This is a NixOS module:
{ config, lib, pkgs, ... }:

{
  imports = [
    ./generic-nixos.nix
  ];

  tilde.xsession.enable = true;
  tilde.workstation.type = "laptop";

  home-manager.users.pjones = { ... }: {
    home.packages = with pkgs; [ grobi ];

    tilde.programs.ssh.keysDir = "~/keys/ssh";

    tilde.programs.polybar = {
      power.enable = true;
      backlight.enable = true;
    };

    services.grobi = {
      enable = true;
      rules =
        let
          internal = "eDP-1";
          external = "DP-1";
          treadmill = "DP-1-SAM-2302-0-SAMSUNG-";
        in
        [
          {
            name = "Treadmill Docking Station";
            outputs_connected = [ treadmill ];
            configure_single = "${external}@1920x1080";
          }
          {
            name = "Dual Monitors";
            outputs_connected = [ internal external ];
            configure_row = [ internal external ];
            primary = internal;
          }
          {
            name = "Internal Screen Only";
            configure_single = internal;
          }
        ];
    };
  };
}
