{ pkgs, config, lib, ... }:

let
  cfg = config.tilde.programs.xfce;
  images = pkgs.callPackage ../misc/images.nix { };

  # Generate a desktop file to automatically start something:
  makeAutorun = args:
    let item = pkgs.makeDesktopItem args;
    in "${item}/share/applications/${args.name}.desktop";

  # A package that replaces XFCE components with alternatives:
  wrappers = pkgs.stdenvNoCC.mkDerivation {
    name = "xfce-herbstluftwm-wrappers";

    dontUnpack = true;
    dontBuild = true;

    installPhase = ''
      mkdir -p "$out/bin"
      ln -s ${pkgs.pjones.hlwmrc}/libexec/hlwmrc "$out/bin/xfwm4"
      ln -s ${pkgs.coreutils}/bin/true "$out/bin/xfdesktop"
      ln -s ${pkgs.coreutils}/bin/true "$out/bin/xfce4-panel"
    '';
  };
in
{
  options.tilde.programs.xfce = {
    enable = lib.mkEnableOption "Configure XFCE";

    wallpaperDirectory = lib.mkOption {
      type = lib.types.path;
      default = "${config.home.homeDirectory}/.config/wallpapers";
      description = "Directory of images";
    };
  };

  config = lib.mkIf cfg.enable {
    tilde.programs.polybar.enable = true;

    # Start my window manager:
    xsession = {
      enable = true;
      windowManager.command = ''
        export PATH=${wrappers}/bin:$PATH
        ${pkgs.runtimeShell} ${pkgs.xfce.xfce4-session.xinitrc}
      '';
    };

    # I'm not quite sure why this doesn't start on its own:
    xdg.configFile."autostart/xfce4-notifyd.desktop".source =
      makeAutorun {
        name = "xfce4-notifyd";
        desktopName = "xfce4-notifyd";
        exec = "${pkgs.xfce.xfce4-notifyd}/lib/xfce4/notifyd/xfce4-notifyd";
      };

    # Swap out desktop wallpaper:
    services.random-background = {
      enable = true;
      imageDirectory = "--recursive ${cfg.wallpaperDirectory}";
      display = "fill";
      interval = "5m";
      enableXinerama = true;
    };

    # Set a default wallpaper:
    xsession.initExtra = ''
      # Set initial background image when not using a wallpaper service:
      if [ ! -d "${cfg.wallpaperDirectory}" ]; then
        ${pkgs.feh}/bin/feh --bg-fill --no-fehbg ${images.login}
      fi
    '';
  };
}
