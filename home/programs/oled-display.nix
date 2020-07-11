{ config, pkgs, lib, ... }:
let
  cfg = config.pjones.programs.oled-display;
in
{
  #### Interface:
  options.pjones.programs.oled-display = {
    enable = lib.mkEnableOption "OLED Pomodoro Timer";
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
        ExecStart = "${pkgs.pjones.oled-display}/bin/display-control";
        Restart = "always";
        RestartSec = 3;
      };
    };
  };
}
