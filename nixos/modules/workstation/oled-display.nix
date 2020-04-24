{ config, pkgs, lib, ... }: with lib;

{
  config = mkIf config.pjones.startX11 {
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
