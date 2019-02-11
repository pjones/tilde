{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.pjones;
  base = import ../../pkgs { inherit pkgs; };

  emacsrc = base.emacsrc;
  encryption-utils = base.encryption-utils;

  # Restart plasmashell after switching display configuration (the
  # plasma panel goes a bit wonky):
  autorandr-postswitch = pkgs.writeScript "autorandr-postswitch" ''
    #!${pkgs.stdenv.shell}
    kquitapp5 plasmashell; kstart5 plasmashell > /dev/null 2>&1 &
  '';

  # Set XDG environment variables to my liking:
  xdg-set-up = pkgs.writeScript "xdg-set-up" (readFile ../../support/workstation/xdg.sh);

  # Reuse the startkde script from NixOS:
  xsessions = config.services.xserver.desktopManager.session.list;
  startkde = (head (filter (d: d.name == "plasma5") xsessions)).start;
in
{
  # Additional files:
  imports = [
    ./mail.nix
  ];

  #### Implementation:
  config = mkIf cfg.isWorkstation {

    # Extra groups needed on a workstation:
    users.users.pjones.extraGroups = [
      "cdrom"
      "dialout"
      "disk"
      "networkmanager"
      "scanner"
    ];

    # Extra packages:
    users.users.pjones.packages = with pkgs; [
      # Desktop
      arc-icon-theme
      arc-theme
      autorandr
      bspwm
      calibre
      glabels
      gwenview
      hicolor_icon_theme
      kdeApplications.krdc
      kdeconnect
      libnotify
      libreoffice
      pamixer
      pavucontrol
      plasma5.user-manager
      playbar2
      qt5.qttools
      rofi
      rofi-pass
      sxhkd
      x11vnc
      xdo
      xdotool
      xorg.xev
      xorg.xhost
      xorg.xrandr
      xorg.xset
      xtitle
      zathura

      # System and Security
      aspell
      aspellDicts.en
      dict
      pass

      # Network
      chromium
      firefox
      youtube-dl

      # Audio/Video
      ffmpeg
      moc
      mpc_cli
      mpg123
      ncmpcpp
      spotify
      vlc

      # Creative
      darktable
      geda
      gimp
      imagemagick
      inkscape
      librecad
      ngspice
      openscad
      pdftk
      qgis
      qmapshack
      slic3r
      xournal

      # Development
      haskellPackages.hlint
      libxml2
      libxslt
      mr
      nodePackages.eslint
      nodejs-slim-8_x
      shellcheck

    ] ++ [
      # My packages
      encryption-utils
      emacsrc
    ];

    # NixOS services:
    services.autorandr.enable = true;
    services.dbus.enable = true;

    # Home Manager:
    home-manager.users.pjones = { ... }: {
      # Files in ~pjones:
      home.file.".emacs".source = "${emacsrc}/dot.emacs.el";
      xdg.configFile."autorandr/postswitch".source = "${autorandr-postswitch}";

      # Services:
      xsession = {
        enable = true;
        windowManager.command = startkde;

        # Run before the window manager:
        initExtra = ''
          ${xdg-set-up}
          export KDEWM=${pkgs.bspwm}/bin/bspwm
        '';
      };

      # Hide the mouse.
      services.unclutter.enable = true;

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
      services.compton = {
        enable = true;

        fade = true;
        fadeExclude = [
          "window_type *= 'menu'"
        ];

        inactiveOpacity = "0.85";
        opacityRule = [
          "20:class_i *= 'presel_feedback'"
          "100:class_g = 'rofi'" # Why doesn't this work?
        ];

        extraOptions = ''
          unredir-if-possible = true;
          use-ewmh-active-win = true;
        '';
      };
    };
  };
}
