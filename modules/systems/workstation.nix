{ self, moduleWithSystem, ... }:
{
  flake.nixosModules.workstation = moduleWithSystem (
    { ... }:
    { config, ... }:
    {
      imports = with self.nixosModules; [
        avahi
        basic
        bluetooth
        documentation
        flatpack
        greetd
        gtk
        gtklock
        libvirt
        networking
        podman
        printing
        sound
        udiskie
        wayland
      ];

      config = {
        home-manager.users.${config.tilde.username} = {
          imports = [ self.homeModules.workstation ];
        };
      };
    }
  );

  flake.homeModules.workstation = moduleWithSystem (
    { pkgs, system, ... }:
    { config, lib, ... }:
    let
      mpvWithOverrides = pkgs.mpv.override {
        scripts = with pkgs.mpvScripts; [
          mpris
          sponsorblock
        ];
      };
    in
    {
      imports = with self.homeModules; [
        anki
        basic
        beamerpresenter
        beets
        bookmarks
        browser
        chromium
        contacts
        direnv
        documentation
        emacs
        firefox
        gtk
        gtklock
        kdeconnect
        network-manager-applet
        niri
        peaclock
        rbw
        recoil
        ssh
        suspend
        swayidle
        swaync
        syncthing
        udiskie
        waybar
        wayland
        wayland-pipewire-idle-inhibit
        wlinhibit
        wpaperd
        xdg
      ];

      options.tilde.workstation = {
        design = lib.mkEnableOption "Configure for 3D printing";
        ee = lib.mkEnableOption "Configure for Electrical Engineering";
        gis = lib.mkEnableOption "Configure for mapping and GIS";
        photography = lib.mkEnableOption "Configure for photography";
      };

      config = {
        # Can I get by without this?
        # services.gnome.gnome-keyring.enable = true;

        home.packages =
          with pkgs;
          [
            abcde # Command-line audio CD ripper
            atomicparsley # A CLI program for reading, parsing and setting metadata into MPEG-4 files
            brightnessctl # This program allows you read and control device brightness
            cdparanoia # A tool and library for reading digital audio from CDs
            cdrkit # cdrecord, mkisofs, etc.
            duckdb # Embeddable SQL OLAP Database Management System
            eduvpn-client # Linux client for eduVPN
            evince # GNOME's document viewer
            ffmpeg # A complete, cross-platform solution to record, convert and stream audio and video
            gdb # GNU Project debugger (so I have local documentation)
            ghostty # Fast, native, feature-rich terminal emulator pushing modern features
            gimp # The GNU Image Manipulation Program
            gnutls # The GNU Transport Layer Security Library
            handbrake # A tool for converting video files and ripping DVDs
            imagemagick # A software suite to create, edit, compose, or convert bitmap images
            imv # A command line image viewer for tiling window managers
            inkscape # Vector graphics editor
            jq # A lightweight and flexible command-line JSON processor
            lame # A high quality MPEG Audio Layer III (MP3) encoder
            libnotify # A library that sends desktop notifications to a notification daemon
            libnotify # A library that sends desktop notifications to a notification daemon
            libossp_uuid # OSSP uuid ISO-C and C++ shared library
            libreoffice # Comprehensive, professional-quality productivity suite, a variant of openoffice.org
            man-pages # Developer man pages.
            mkpasswd # Overfeatured front-end to crypt, from the Debian whois package
            mpvWithOverrides # General-purpose media player, fork of MPlayer and mplayer2
            nautilus # File manager for GNOME
            netcat # Arbitrary TCP and UDP connections and listens
            networkmanagerapplet # NetworkManager control applet for GNOME
            nix-prefetch-scripts # Collection of all the nix-prefetch-* scripts which may be used to obtain source hashes
            nixd # Feature-rich Nix language server interoperating with C++ nix
            nixfmt # Official formatter for Nix code
            nwg-displays # Output management utility for Sway and Hyprland
            openssl # A cryptographic library that implements the SSL and TLS protocols
            pamixer # Pulseaudio command line mixer
            pamixer # Pulseaudio command line mixer
            pandoc # Conversion between markup formats
            pass # Stores, retrieves, generates, and synchronizes passwords securely
            pavucontrol # PulseAudio Volume Control
            pjones.encryption-utils # Scripts for various encryption tasks
            pjones.image-scripts # Scripts for working with images
            pjones.network-scripts # Scripts related to networking
            playerctl # Command-line utility for controlling media players
            pwgen # Password generator which creates passwords which can be easily memorized by a human
            remmina # Remote desktop client written in GTK
            ripgrep # A utility that combines the usability of The Silver Searcher with the raw speed of grep
            rofi # Window switcher, run dialog and dmenu replacement for Wayland
            self.packages.${system}.pjones-avatar # For tools that use an avatar
            self.packages.${system}.presenter-mode # Toggle presenter mode.
            self.packages.${system}.rofirc # Rofi launcher configuration
            self.packages.${system}.superkey # Wayland scripts.
            self.packages.${system}.tilde-scripts-browser # Browser scripts
            shellcheck # Shell script analysis tool
            shfmt # A shell parser and formatter
            sushi # Quick previewer for Nautilus
            virt-viewer # Viewer for remote virtual machines
            vlc # Cross-platform media player and streaming server
            wayland-utils # Wayland utilities (wayland-info)
            wev # Wayland event viewer
            wirelesstools # Wireless tools for Linux
            wl-clipboard # Command-line copy/paste utilities for Wayland
            wl-mirror # Simple Wayland output mirror client
            wlvncc # Wayland Native VNC Client
            wtype # xdotool type for wayland
            xournalpp # Xournal++ is a handwriting Notetaking software with PDF annotation support
          ]
          ++ lib.optionals (pkgs.stdenv.isx86_64 || pkgs.stdenv.isAarch64) (
            with pkgs;
            [
              # Doesn't work in amr7l.
              pdftk # Command-line tool for working with PDFs
            ]
          )
          ++
            # Packages that don't build on aarch64:
            lib.optionals pkgs.stdenv.isx86_64 (
              with pkgs;
              [
                makemkv # Convert blu-ray and dvd to mkv
              ]
            )
          ++ lib.optionals config.tilde.workstation.design (
            with pkgs;
            [
              openscad # 3D parametric model compiler
              prusa-slicer # G-code generator for 3D printer
              qcad # 2D CAD package based on Qt
            ]
          )
          ++ lib.optionals config.tilde.workstation.ee (
            with pkgs;
            [
              kicad # Open Source Electronics Design Automation suite
            ]
          )
          ++ lib.optionals config.tilde.workstation.gis (
            with pkgs;
            [
              gdal # Translator library for raster geospatial data formats
              qmapshack # Consumer grade GIS software
            ]
          )
          ++ lib.optionals config.tilde.workstation.photography (
            with pkgs;
            [
              darktable # Virtual lighttable and darkroom for photographers
              digikam # Photo Management Program
            ]
          );

      };
    }
  );
}
