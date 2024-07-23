{ config, lib, ... }:

let
  cfg = config.tilde.programs.android;
in
{
  options.tilde.programs.android = {
    enable = lib.mkEnableOption "Android support";
  };

  config = lib.mkIf cfg.enable {
    programs.adb.enable = true;
    users.users.${config.tilde.username}.extraGroups = [ "adbusers" ];
  };
}
