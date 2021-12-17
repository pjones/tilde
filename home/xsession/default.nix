{ config
, pkgs
, lib
, ...
}:
let
  cfg = config.tilde.xsession;

  deType = {
    options = {
      enable = lib.mkEnableOption "Use a desktop environment.";

      command = lib.mkOption {
        type = lib.types.str;
        description = "Command to start a desktop environment.";
      };

      envVar = lib.mkOption {
        type = lib.types.str;
        description = ''
          Environment variable name to tell the DE what window manger
          to use.
        '';
      };
    };
  };

in
{
  imports = [
    ./browser.nix
    ./lock.nix
    ./theme.nix
    ./wallpaper.nix
  ];

  options.tilde.xsession = {
    enable = lib.mkEnableOption "Enable an X11 session";

    desktopEnv = lib.mkOption {
      type = lib.types.submodule deType;
      default = { };
      description = ''
        If you want to use a desktop environment you can set these
        options in order to get it started with the chosen window
        manger.
      '';
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      # Enabling an xsession also enables workstation settings:
      tilde.workstation.enable = true;

      # Enable other xsession modules:
      tilde.programs.firefox.enable = lib.mkDefault true;
      tilde.programs.gromit-mpx.enable = lib.mkDefault true;
      tilde.programs.herbstluftwm.enable = lib.mkDefault true;
      tilde.programs.konsole.enable = lib.mkDefault true;
      tilde.programs.oled-display.enable = lib.mkDefault true;
      tilde.programs.rofi.enable = lib.mkDefault true;
      tilde.xsession.lock.bluetooth.enable = lib.mkDefault true;

      # Communicate with my phone:
      services.kdeconnect = {
        enable = true;
        indicator = true;
      };

      # Cache passphrases and keys:
      services.gpg-agent = {
        enable = true;
        enableSshSupport = true;
        defaultCacheTtl = 3600;
        defaultCacheTtlSsh = 14400;
        maxCacheTtl = 7200;
        maxCacheTtlSsh = 21600;
      };

      # Make things pretty:
      services.picom = {
        enable = true;
        fade = true;
      };

      # Set XDG user directories:
      xdg.userDirs = {
        enable = true;
        createDirectories = false;

        desktop = "$HOME/desktop";
        documents = "$HOME/documents";
        download = "$HOME/download";
        music = "$HOME/documents/music";
        pictures = "$HOME/documents/pictures";
        publicShare = "$HOME/public";
        templates = "$HOME/documents/templates";
        videos = "$HOME/documents/videos";
      };
    })

    (lib.mkIf (cfg.enable && !cfg.desktopEnv.enable) {
      # Services to start when running X11:
      tilde.programs.dunst.enable = lib.mkDefault true;
      tilde.programs.polybar.enable = lib.mkDefault true;
      tilde.xsession.lock.enable = lib.mkDefault true;
      tilde.xsession.theme.enable = lib.mkDefault true;
      tilde.xsession.wallpaper.enable = lib.mkDefault true;

      services.network-manager-applet.enable = true;
      services.unclutter.enable = true;

      # Enable blueman and disable unwanted plugins:
      services.blueman-applet.enable = true;

      dconf.settings."org/blueman/general" = {
        plugin-list = [ "!ConnectionNotifier" ];
      };

      services.udiskie = {
        enable = true;
        automount = false;
      };
    })
  ];
}
