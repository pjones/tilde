{ config
, pkgs
, lib
, ...
}:
let
  cfg = config.tilde.xsession.wallpaper;
in
{
  options.tilde.xsession.wallpaper = {
    enable = lib.mkEnableOption "Automatic wallpaper changing";

    directory = lib.mkOption {
      type = lib.types.path;
      default = "${config.home.homeDirectory}/documents/pictures/backgrounds/automatic";
      description = "Directory of images";
    };
  };

  config = lib.mkIf cfg.enable {
    services.random-background = {
      enable = true;
      imageDirectory = "--recursive ${cfg.directory}";
      display = "fill";
      interval = "5m";
      enableXinerama = true;
    };
  };
}
