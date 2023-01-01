{ config
, pkgs
, lib
, ...
}:
let
  cfg = config.tilde.programs.wallpaper;
  images = pkgs.callPackage ../misc/images.nix { };
in
{
  options.tilde.programs.wallpaper = {
    enable = lib.mkEnableOption "Automatic wallpaper changing";

    directory = lib.mkOption {
      type = lib.types.path;
      default = "${config.xdg.configHome}/wallpapers";
      description = "Directory of images";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      services.random-background = {
        enable = true;
        imageDirectory = "--recursive ${cfg.directory}";
        display = "fill";
        interval = "5m";
        enableXinerama = true;
      };
    })

    ({
      xsession.initExtra = ''
        # Set initial background image when not using a wallpaper service:
        if [ "${toString cfg.enable}" -ne 1 ] || [ ! -e "${cfg.directory}" ]; then
          ${pkgs.feh}/bin/feh --bg-fill --no-fehbg ${images.login}
        fi
      '';
    })
  ];
}
