{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.tilde.programs.chromium;
in
{
  options.tilde.programs.chromium = {
    enable = lib.mkEnableOption "Enable Chromium";
  };
  config = lib.mkIf cfg.enable {
    programs.chromium = {
      enable = true;
      package = pkgs.ungoogled-chromium;
      dictionaries = with pkgs.hunspellDictsChromium; [ en_US ];
    };
  };
}
