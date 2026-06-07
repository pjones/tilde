{ moduleWithSystem, ... }:
{
  flake.homeModules.wpaperd = moduleWithSystem (
    { pkgs, ... }:
    { config, lib, ... }:
    let
      cfg = config.tilde.programs.wpaperd;

      # https://www.reddit.com/r/wallpapers/comments/ge4hrd/geometry/
      defaultImage = pkgs.fetchurl {
        url = "https://i.redd.it/tg9ac8kn10x41.jpg";
        sha256 = "0pb32hzrngl06c1icb2hmdq8ja7v1gc2m4ss32ihp6rk45c59lji";
      };

      setDefaultImage = pkgs.writeShellApplication {
        name = "set-default-wallpaper";

        # FIXME:
        text = ''
          if [ ! -d "${cfg.primaryWallpaperDirectory}" ]; then
            echo ${defaultImage}
          fi
        '';
      };
    in
    {
      options.tilde.programs.wpaperd = {
        primaryWallpaperDirectory = lib.mkOption {
          type = lib.types.path;
          default = "${config.home.homeDirectory}/documents/pictures/backgrounds/primary";
          description = "Directory of images to display on the primary output";
        };

        secondaryWallpaperDirectory = lib.mkOption {
          type = lib.types.path;
          default = "${config.home.homeDirectory}/documents/pictures/backgrounds/secondary";
          description = "Directory of images to display on secondary outputs";
        };
      };

      config = {
        wayland.windowManager.niri.extraConfig = ''
          spawn-at-startup "${setDefaultImage}/bin/set-default-wallpaper"
        '';

        services.wpaperd = {
          enable = true;

          settings = {
            default = {
              duration = "1h";
              sorting = "random";
              mode = "center";
              transition-time = 600;
              queue-size = 10;
            };

            any.path = cfg.secondaryWallpaperDirectory;
            ${config.tilde.wayland.primaryOutput}.path = cfg.primaryWallpaperDirectory;
          };
        };
      };
    }
  );
}
