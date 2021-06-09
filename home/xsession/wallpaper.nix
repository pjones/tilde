{ config
, pkgs
, lib
, ...
}:
let
  cfg = config.tilde.xsession.wallpaper;
  images = pkgs.callPackage ../misc/images.nix { };
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

    xsession.initExtra = ''
      # Set initial background image when not using a wallpaper service:
      if [ "${toString config.tilde.xsession.wallpaper.enable}" -ne 1 ] ||
         [ ! -d "${config.tilde.xsession.wallpaper.directory}" ]; then
        ${pkgs.feh}/bin/feh --bg-fill --no-fehbg ${images.login}
      fi
    '';
  };
}
