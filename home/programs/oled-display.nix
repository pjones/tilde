{ config, pkgs, lib, ... }:
let
  cfg = config.tilde.programs.oled-display;

  package =
    pkgs.haskell.lib.justStaticExecutables
      pkgs.pjones.oled-display;

  flags = lib.concatStringsSep " " (
    [
      "-a ${cfg.arduino.path}"
      "-s ${cfg.socket}"
    ] ++
    lib.optional (! cfg.arduino.enable) "-A"
  );

  start = pkgs.writeShellScript "oled-display-start" ''
    ${pkgs.coreutils}/bin/rm -f ${cfg.socket}
    ${package}/bin/display-control ${flags}
  '';
in
{
  #### Interface:
  options.tilde.programs.oled-display = {
    enable = lib.mkEnableOption "OLED Pomodoro Timer";

    socket = lib.mkOption {
      type = lib.types.str;
      default = "~/.display-control.sock";
      description = "Path to the HTTP socket file";
    };

    arduino = {
      enable = lib.mkEnableOption "Display results via an Arduino";

      path = lib.mkOption {
        type = lib.types.path;
        default = "/dev/ttyACM0";
        description = "Path to the Arduino serial port";
      };
    };
  };

  #### Implementation:
  config = lib.mkIf cfg.enable {
    systemd.user.services.oled-display = {
      Unit = {
        Description = "OLED Display Controller";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = toString start;
        Restart = "always";
        RestartSec = 3;
      };
    };
  };
}
