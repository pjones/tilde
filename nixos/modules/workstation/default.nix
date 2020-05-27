{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.pjones;

  # Set XDG environment variables to my liking:
  xdg-set-up = pkgs.writeScript "xdg-set-up"
    (readFile ../../../support/workstation/xdg.sh);

  # Reuse the startkde script from NixOS:
  xsessions = config.services.xserver.desktopManager.session;
  startkde = (head (filter (d: d.name == "plasma5") xsessions)).start;
in {
  # Additional files:
  imports = [
    ./firefox.nix
    ./keyboard.nix
    ./mail.nix
    ./mpd.nix
    ./oled-display.nix
    ./syncthing.nix
    ./yubikey.nix
  ];

  #### Implementation:
  config = mkIf cfg.isWorkstation {

    # Make sure X is enabled:
    services.xserver = mkIf cfg.startX11 {
      enable = mkDefault true;
      layout = mkDefault "us";

      # These need to be enabled so we can get the Plasma start script
      # from nixpkgs:
      displayManager.sddm.enable = mkDefault true;
      desktopManager.plasma5.enable = mkDefault true;

      # Add a custom desktop session:
      desktopManager.session = singleton {
        name = "plasma+xmonad";
        enable = true;
        start = ''
          exec /home/pjones/.xsession
        '';
      };
    };

    # Extra groups needed on a workstation:
    users.users.pjones.extraGroups =
      [ "cdrom" "dialout" "disk" "networkmanager" "scanner" ];

    # Some things only work if installed in the system environment:
    environment.systemPackages = with pkgs;
      [
        arc-icon-theme
        arc-theme
        gwenview
        hicolor_icon_theme
        kdeconnect
        plasma-browser-integration
        playbar2
        qt5.qttools
      ] ++ filter (p: isDerivation p && !(p.meta.broken or false))
      (attrValues pkgs.kdeApplications);

    # Extra packages:
    users.users.pjones.packages = with pkgs; [
      # Desktop
      calibre
      glabels
      libnotify
      libreoffice
      pamixer
      pavucontrol
      rofi
      wmctrl
      x11vnc
      xclip
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
      nixops
      pass

      # Network
      chromium
      firefox
      mu
      youtube-dl

      # Audio/Video
      abcde
      atomicparsley
      # beets (2020-04-24: broken)
      bs1770gain
      cantata
      cdparanoia
      cdrkit # cdrecord, mkisofs, etc.
      ffmpeg
      handbrake
      lame
      makemkv
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
      kicad
      librecad
      ngspice
      openscad
      pandoc
      pdftk
      prusa-slicer
      qmapshack
      slic3r
      xournal

      # Development
      haskellPackages.hlint
      libxml2
      libxslt
      mr
      niv
      nixfmt
      nodePackages.eslint
      nodejs-slim
      ripgrep
      shellcheck
      shfmt

      # My packages
      pjones.emacsrc
      pjones.encryption-utils
      pjones.rofirc
      pjones.vimeta
    ];

    # Fonts:
    fonts = {
      fontconfig.enable = true;
      enableFontDir = true;
      enableGhostscriptFonts = true;

      fonts = with pkgs; [
        cascadia-code
        corefonts
        dejavu_fonts
        emacs-all-the-icons-fonts
        fira-code
        hack-font
        hermit
        inconsolata
        powerline-fonts
        source-code-pro
        ubuntu_font_family
      ];
    };

    # Printing:
    services.printing = {
      enable = true;
      drivers = with pkgs; [ cups-googlecloudprint canon-cups-ufr2 ];
    };

    # Home Manager:
    home-manager.users.pjones = { ... }: {
      # Files in ~pjones:
      home.file.".emacs".source = "${pkgs.pjones.emacsrc}/dot.emacs.el";
      home.file.".local/share/applications/org-protocol.desktop".source =
        "${pkgs.pjones.emacsrc}/share/applications/org-protocol.desktop";
      home.file.".local/share/applications/gnus.desktop".source =
        "${pkgs.pjones.emacsrc}/share/applications/gnus.desktop";
      home.file.".local/share/applications/emacsclient.desktop".source =
        "${pkgs.pjones.emacsrc}/share/applications/emacsclient.desktop";

      home.file.".config/rofi/config.rasi".source =
        "${pkgs.pjones.rofirc}/etc/config.rasi";
      home.file.".config/rofi/themes".source = "${pkgs.pjones.rofirc}/themes";

      home.file.".config/kde.org/pjones.css".source =
        ../../../support/workstation/kde/theme.css;

      # MIME:
      xdg.mimeApps = {
        enable = true;
        defaultApplications = {
          "x-scheme-handler/mailto" = "gnus.desktop";
          "x-scheme-handler/org-protocol" = "org-protocol.desktop";
          "application/pdf" = "emacsclient.desktop";
        };
      };

      # Services:
      xsession = mkIf cfg.startX11 {
        enable = true;
        windowManager.command = ''
          ${xdg-set-up}
          export KDEWM=${pkgs.pjones.xmonadrc}/bin/xmonadrc
          ${startkde}
        '';
      };

      # Hide the mouse.
      services.unclutter.enable = cfg.startX11;

      # Nix drv caching and background building:
      services.lorri.enable = true;

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
      services.picom = mkIf cfg.startX11 {
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
    };
  };
}
