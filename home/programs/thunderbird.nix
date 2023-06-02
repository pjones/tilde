{ config
, pkgs
, lib
, ...
}:
let
  cfg = config.tilde.programs.thunderbird;
in
{
  options.tilde.programs.thunderbird = {
    enable = lib.mkEnableOption "Thunderbird";
  };

  config = lib.mkIf cfg.enable {
    programs.thunderbird = {
      enable = true;

      settings = {
        "app.donation.eoy.version.viewed" = 1;
        "calendar.alarms.onforevents" = 1;
        "calendar.alarms.onfortodos" = 1;
        "calendar.week.start" = 1;
        "privacy.donottrackheader.enabled" = true;
        "widget.gtk.overlay-scrollbars.enabled" = false;
      };

      profiles.default = {
        isDefault = true;
      };
    };
  };
}
