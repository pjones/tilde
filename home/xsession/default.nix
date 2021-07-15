{ config
, pkgs
, lib
, ...
}:
let
  cfg = config.tilde.xsession;

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
  };

  config = lib.mkIf cfg.enable {
    # Enable other xsession modules:
    tilde.programs.dunst.enable = lib.mkDefault true;
    tilde.programs.herbstluftwm.enable = lib.mkDefault true;
    tilde.programs.konsole.enable = lib.mkDefault true;
    tilde.programs.oled-display.enable = lib.mkDefault true;
    tilde.programs.polybar.enable = lib.mkDefault true;
    tilde.programs.rofi.enable = lib.mkDefault true;
    tilde.xsession.lock.enable = lib.mkDefault true;
    tilde.xsession.theme.enable = lib.mkDefault true;
    tilde.xsession.wallpaper.enable = lib.mkDefault true;

    # Enabling an xsession also enables workstation settings:
    tilde.workstation.enable = true;

    # Services to start when running X11:
    services.blueman-applet.enable = true;
    services.network-manager-applet.enable = true;
    services.unclutter.enable = true;

    services.udiskie = {
      enable = true;
      automount = false;
    };

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
      blur = true;
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
      firefox
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
  };
}
