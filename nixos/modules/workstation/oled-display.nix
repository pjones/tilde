{ config, pkgs, lib, ... }: with lib;

let
  base = import ../../../pkgs { inherit pkgs; };
in
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
          ExecStart = "${base.oled-display}/bin/display-control";
          Restart = "always";
          RestartSec = 3;
        };
      };
    };
  };
}
