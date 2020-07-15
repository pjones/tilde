{ config
, pkgs
, lib
, ...
}:
let
  cfg = config.pjones.xsession.wallpaper;
in
{
  options.pjones.xsession.wallpaper = {
    enable = lib.mkEnableOption "Automatic wallpaper changing";
  };

  config = lib.mkIf cfg.enable {
    services.random-background = {
      enable = true;
      imageDirectory = "--recursive %h/documents/pictures/backgrounds/automatic";
      display = "fill";
      interval = "5m";
      enableXinerama = true;
    };
  };
}
