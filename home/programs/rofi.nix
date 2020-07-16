{ config
, pkgs
, lib
, ...
}:
let
  cfg = config.pjones.programs.rofi;
in
{
  options.pjones.programs.rofi = {
    enable = lib.mkEnableOption "Install and configure rofi";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      rofi
      pjones.rofirc
    ];

    home.file.".config/rofi/config.rasi".source =
      "${pkgs.pjones.rofirc}/etc/config.rasi";
    home.file.".config/rofi/themes".source =
      "${pkgs.pjones.rofirc}/themes";
  };
}
