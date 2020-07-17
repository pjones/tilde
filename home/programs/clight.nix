{ config, pkgs, lib, ... }:
let
  cfg = config.tilde.programs.clight;
in
{
  options.tilde.programs.clight = {
    enable = lib.mkEnableOption "Automatic control of the backlight";
  };

  config = lib.mkIf cfg.enable {
    systemd.user.services.clight = {
      Unit = {
        Description = "clight User Session";
        After = [ "clightd.service" ];
      };

      Install = { WantedBy = [ "default.target" ]; };

      Service = {
        ExecStart = "${pkgs.clight}/bin/clight";
        Restart = "always";
        RestartSec = 3;
      };
    };
  };
}
