{ config, pkgs, lib, ... }: with lib;

{
  #### Interface:
  options.pjones.oled-display = {
    enable = mkEnableOption "OLED Pomodoro Timer";
  };

  #### Implementation:
  config = mkIf config.pjones.oled-display.enable {
    home-manager.users.pjones = { ... }: {
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
  };
}
