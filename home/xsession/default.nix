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
        blur = false;
        fade = true;
        inactiveDim = "0.4";

        extraOptions = ''
          # Windows that are considered to always be focused.
          #
          # visible-monitor is a tag I put on windows that are on
          # monitors that are visible but are not the primary monitor.
          focus-exclude = [
            "class_g = 'Rofi'",
            "class_g = 'Polybar'",
            "_HLWMRC_TAGS@:s *?= 'visible-monitor'"
          ];
        '';
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

      # Extra programs to install:
      home.packages = with pkgs; [
        # Desktop
        calibre
        glabels
        spectacle
        libnotify
        libreoffice
        pamixer
        pavucontrol
        wmctrl
        x11vnc
        xclip
        xdo
        xdotool
        xorg.xev
        xorg.xhost
        xorg.xrandr
        xorg.xset
        xorg.xwininfo
        xtitle

        # Network
        brave
        chromium-launcher
        element-desktop
        remmina
        signal-desktop
        slack
        tilde-scripts-browser
        zulip

        # Audio/Video
        cantata
        cdparanoia
        handbrake
        makemkv
        spotify
        vlc

        # Creative
        darktable
        dia
        gdal
        gimp
        gwenview
        imagemagick
        inkscape
        kicad
        ngspice
        openscad
        prusa-slicer
        qcad
        qmapshack
        vscode
        xournal
      ];
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
