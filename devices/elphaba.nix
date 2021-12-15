# This is a NixOS module:
{ config, lib, pkgs, ... }:

{
  imports = [
    ./generic-nixos.nix
  ];

  config = {
    networking.hostName = "elphaba";

    tilde = {
      xsession.enable = true;
      workstation.type = "laptop";

      workstation.kmonad = {
        enable = true;
        keyboards = {
          internal.device = "/dev/input/by-path/platform-i8042-serio-0-event-kbd";
        };
      };
    };

    home-manager.users.pjones = { ... }: {
      home.packages = with pkgs; [ grobi ];
      tilde.programs.emacs.enable = true;

      tilde.programs.ssh = {
        keysDir = "~/keys/ssh";
        haveRestrictedKeys = true;
      };

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
            treadmill = "${external}-AUS-9377-16843009-VG245-L8LMQS164419";
          in
          [
            {
              name = "Treadmill Docking Station";
              outputs_connected = [ treadmill ];
              configure_single = external;
              execute_after = [
                # Use the dock's Ethernet connection:
                "${pkgs.networkmanager}/bin/nmcli radio wifi off"
              ];
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
              execute_after = [
                # Ensure WiFi is restored:
                "${pkgs.networkmanager}/bin/nmcli radio wifi on"
              ];
            }
          ];
      };
    };
  };
}
