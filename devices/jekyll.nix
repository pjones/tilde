# This is a NixOS module:
{ config, lib, pkgs, ... }:

{
  imports = [
    ./generic-nixos.nix
  ];

  config = {
    networking.hostName = "jekyll";

    services.kmonad = lib.mkIf (pkgs.system == "x86_64-linux") {
      enable = true;

      keyboards.internal = {
        device = "/dev/input/by-path/platform-i8042-serio-0-event-kbd";
        config = builtins.readFile ../support/keyboard/us_60.kbd;

        defcfg = {
          enable = true;
          fallthrough = true;
        };
      };
    };

    tilde = {
      xsession.enable = true;
      xsession.dpi = 144;
      workstation.type = "laptop";
    };

    home-manager.users.pjones = { ... }: {
      tilde.programs.emacs.enable = true;
      tilde.programs.haskell.enable = true;

      tilde.programs.ssh = {
        keysDir = "~/keys/ssh";
        haveRestrictedKeys = true;

        rfa = {
          enable = true;
          vpnJumpHost = "192.168.122.19";
        };
      };

      # For remote file editing:
      programs.ssh.matchBlocks.medusa = {
        hostname = "medusa.private.pmade.com";
        port = 4;
        forwardAgent = true;
        forwardX11 = true;
        forwardX11Trusted = true;
      };

      tilde.programs.polybar = {
        backlight.enable = true;
        power.enable = true;
        power.battery = "BAT1";
        power.adapter = "ACAD";
      };

      services.polybar.config."bar/primary" = {
        dpi-x = 144;
        dpi-y = 144;
      };

      # Automatically deal with new monitor connections:
      services.grobi = {
        enable = true;

        rules =
          let
            pactl = "${config.hardware.pulseaudio.package}/bin/pactl";
            systemctl = "${config.systemd.package}/bin/systemctl";

            # When connected to the TV in the lounge:
            loungeTV = output: {
              name = "Lounge TV (${output})";
              outputs_connected = [ "${output}-ONK-3635-0-HT-R393-" ];
              configure_row = [ "eDP-1" "${output}@1920x1080" ];
              primary = "eDP-1";
              execute_after = [
                "${systemctl} --user stop xautolock-session.service"
                "${systemctl} --user start random-background.service"
                "${pactl} set-card-profile 0 output:hdmi-stereo"
              ];
            };

            # When connected to my stand-up station:
            standupStation = output: {
              name = "Stand Up Station (#{output})";
              outputs_connected = [ "${output}-LEN-26336-1111774804-G24qe-20-U563BDVT" ];
              configure_single = "${output}@2560x1440";
              execute_after = [
                "${systemctl} --user start random-background.service"
              ];
            };

            # When connected to some other external monitor:
            autoExternal = output: {
              name = "Auto External (${output})";
              outputs_connected = [ output ];
              configure_row = [ "eDP-1" output ];
              primary = "eDP-1";
            };

            # Default configuration:
            fallback = {
              name = "Fallback";
              configure_single = "eDP-1";
              execute_after = [
                "${systemctl} --user start xautolock-session.service"
              ];
            };

            # All of the external devices on my laptop:
            devices = [ "DP-1" "DP-2" "DP-3" "DP-4" ];
          in
          map loungeTV devices
          ++ map standupStation devices
          ++ map autoExternal devices
          ++ [ fallback ];
      };
    };
  };
}
