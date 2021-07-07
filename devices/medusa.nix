# This is a NixOS module:
{ config, lib, pkgs, ... }:

{
  imports = [
    ./generic-nixos.nix
  ];

  tilde.xsession.enable = true;

  tilde.crontab = {
    image-import = {
      schedule = "*-*-* 01:15:00";
      path = [ pkgs.pjones.image-scripts ];
      script = "image-import -v";
    };
  };

  tilde.workstation.kmonad = {
    enable = true;
    keyboards.leopold = {
      device = "/dev/input/by-id/usb-Cypress_USB_Keyboard-event-kbd";
    };
  };

  home-manager.users.pjones = { ... }: {
    tilde.programs.oled-display.arduino.enable = true;

    tilde.programs.ssh = {
      keysDir = "~/keys/ssh";
      haveRestrictedKeys = true;

      rfa = {
        enable = true;
        vpnJumpHost = "192.168.122.95";
      };
    };

    tilde.xsession.lock = {
      bluetooth.devices = [
        "80:86:D9:3A:A9:BB"
      ];
    };

    services.grobi = {
      enable = true;
      rules =
        let
          useAll = name: outputs: {
            inherit name;
            outputs_connected = outputs;
            configure_row = outputs;
            primary = builtins.head outputs;
            atomic = false;
          };
        in
        [
          (useAll "Medusa Primary" [ "DisplayPort-0" "HDMI-0" ])
          (useAll "Fallback to DisplayPort" [ "DisplayPort-0" ])
        ];
    };
  };
}
