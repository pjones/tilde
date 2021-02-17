{ config
, pkgs
, lib
, ...
}:
let
  cfg = config.tilde.xsession;

  # Set XDG environment variables to my liking:
  xdg-set-up = pkgs.writeScript "xdg-set-up"
    (lib.readFile ../../support/workstation/xdg.sh);

  # Background images:
  images = pkgs.callPackage ../misc/images.nix { };
in
{
  imports = [
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
    tilde.programs.oled-display.enable = lib.mkDefault true;
    tilde.programs.polybar.enable = lib.mkDefault true;
    tilde.programs.rofi.enable = lib.mkDefault true;
    tilde.xsession.theme.enable = lib.mkDefault true;
    tilde.xsession.wallpaper.enable = lib.mkDefault true;

    # Enabling an xsession also enables workstation settings:
    tilde.workstation.enable = true;

    xsession = {
      enable = true;
      windowManager.command = ''
        ${xdg-set-up}

        # Set initial background image when not using a wallpaper service:
        if [ "${toString config.tilde.xsession.wallpaper.enable}" -ne 1 ] ||
           [ ! -d "${config.tilde.xsession.wallpaper.directory}" ]; then
          ${pkgs.feh}/bin/feh --bg-fill --no-fehbg ${images.login}
        fi

        # Launch my window manager:
        ${pkgs.pjones.xmonadrc.bin}/bin/xmonadrc
      '';
    };

    # Services to start when running X11:
    services.blueman-applet.enable = true;
    services.network-manager-applet.enable = true;
    services.udiskie.enable = true;
    services.unclutter.enable = true;

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
      shadow = true;
      shadowExclude = [ "focused = 0" ];

      extraOptions = ''
        shadow-red   = 0;
        shadow-green = 0.91;
        shadow-blue  = 0.78;
        xinerama-shadow-crop = true;
      '';
    };

    # Extra programs to install:
    home.packages = with pkgs; [
      # Desktop
      calibre
      glabels
      kdeApplications.spectacle
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
      chromium-launcher
      firefox
      krdc
      signal-desktop
      slack
      tdesktop
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
