{ config, lib, pkgs, ... }:
{
  config = lib.mkMerge [

    ############################################################################
    # Packages to install on all systems:
    (lib.mkIf config.tilde.enable {
      home.packages = with pkgs; [
        bc # GNU software calculator
        bind # For dig(1): Domain name server
        binutils # Tools for manipulating binaries (linker, assembler, etc.)
        coreutils # The basic file, shell and text manipulation utilities of the GNU operating system
        curl # A command line tool for transferring files with URL syntax
        file # A program that shows the type of files
        gawk # GNU implementation of the Awk programming language
        gnugrep # GNU implementation of the Unix grep command
        gnumake # A tool to control the generation of non-source files from sources
        gnutls # The GNU Transport Layer Security Library
        htop # An interactive process viewer for Linux
        inetutils # Collection of common network programs
        jq # A lightweight and flexible command-line JSON processor
        libossp_uuid # OSSP uuid ISO-C and C++ shared library
        mkpasswd # Overfeatured front-end to crypt, from the Debian whois package
        netcat # Arbitrary TCP and UDP connections and listens
        nix-prefetch-scripts # Collection of all the nix-prefetch-* scripts which may be used to obtain source hashes
        openssh # An implementation of the SSH protocol
        openssl # A cryptographic library that implements the SSL and TLS protocols
        pjones.encryption-utils # Scripts for various encryption tasks
        pjones.network-scripts # Scripts related to networking
        pwgen # Password generator which creates passwords which can be easily memorized by a human
        rdiff-backup # Backup system trying to combine best a mirror and an incremental backup system
        rsync # A fast incremental file transfer utility
        tmux # Terminal multiplexer
        tree # Command to produce a depth indented directory listing
        unzip # An extraction utility for archives compressed in .zip format
        wget # Tool for retrieving files using HTTP, HTTPS, and FTP
        which # Shows the full path of (shell) commands
        zip # Compressor/archiver for creating and modifying zipfiles
      ] ++
      lib.optionals pkgs.stdenv.isLinux (with pkgs; [
        cryptsetup # LUKS for dm-crypt
        inotify-tools # Command-line programs providing a simple interface to inotify
        procps # Utilities that give information about processes using the /proc filesystem
        psmisc # A set of small useful utilities that use the proc filesystem (such as fuser, killall and pstree)
      ]);
    })

    ############################################################################
    # Packages to install on workstations:
    (lib.mkIf config.tilde.workstation.enable {
      home.packages = with pkgs; [
        abcde # Command-line audio CD ripper
        atomicparsley # A CLI program for reading, parsing and setting metadata into MPEG-4 files
        cdparanoia # A tool and library for reading digital audio from CDs
        cdrkit # cdrecord, mkisofs, etc.
        duckdb # Embeddable SQL OLAP Database Management System
        ffmpeg # A complete, cross-platform solution to record, convert and stream audio and video
        gdb # GNU Project debugger (so I have local documentation)
        lame # A high quality MPEG Audio Layer III (MP3) encoder
        pandoc # Conversion between markup formats
        pass # Stores, retrieves, generates, and synchronizes passwords securely
        pjones.image-scripts # Scripts for working with images
        ripgrep # A utility that combines the usability of The Silver Searcher with the raw speed of grep
        yt-dlp # Command-line tool to download videos from YouTube.com and other sites (youtube-dl fork)

        # General-purpose media player, fork of MPlayer and mplayer2
        (mpv.override {
          scripts = with mpvScripts; [
            mpris
            sponsorblock
          ];
        })
      ] ++
      lib.optionals pkgs.stdenv.isLinux (with pkgs; [
        nixpkgs-fmt # Nix code formatter for nixpkgs
        shellcheck # Shell script analysis tool
        shfmt # A shell parser and formatter
      ]) ++
      lib.optionals (pkgs.stdenv.isx86_64 || pkgs.stdenv.isAarch64) (with pkgs; [
        # Doesn't work in amr7l.
        pdftk # Command-line tool for working with PDFs
      ]);
    })

    ############################################################################
    # Packages to install on workstations with a GUI running:
    (lib.mkIf config.tilde.graphical.enable {
      home.packages = with pkgs; [
        anki-bin # Spaced repetition flashcard program
        chromium # A wrapper around chromium:
        evince # GNOME's document viewer
        gimp # The GNU Image Manipulation Program
        handbrake # A tool for converting video files and ripping DVDs
        imagemagick # A software suite to create, edit, compose, or convert bitmap images
        imv # A command line image viewer for tiling window managers
        inkscape # Vector graphics editor
        libnotify # A library that sends desktop notifications to a notification daemon
        libreoffice # Comprehensive, professional-quality productivity suite, a variant of openoffice.org
        pamixer # Pulseaudio command line mixer
        pavucontrol # PulseAudio Volume Control
        remmina # Remote desktop client written in GTK
        rnote # Simple drawing application to create handwritten notes
        tilde-scripts-browser # Browser scripts
        virt-viewer # Viewer for remote virtual machines
        vlc # Cross-platform media player and streaming server
        wlvncc # Wayland Native VNC Client
        xournalpp # Xournal++ is a handwriting Notetaking software with PDF annotation support
      ] ++
      # Packages that don't build on aarch64:
      lib.optionals pkgs.stdenv.isx86_64 (with pkgs; [
        makemkv # Convert blu-ray and dvd to mkv
        signal-desktop # Private, simple, and secure messenger
      ]) ++
      lib.optionals config.tilde.graphical.design (with pkgs; [
        openscad # 3D parametric model compiler
        prusa-slicer # G-code generator for 3D printer
        qcad # 2D CAD package based on Qt
      ]) ++
      lib.optionals config.tilde.graphical.ee (with pkgs; [
        kicad # Open Source Electronics Design Automation suite
      ]) ++
      lib.optionals config.tilde.graphical.gis (with pkgs; [
        gdal # Translator library for raster geospatial data formats
        qmapshack # Consumer grade GIS software
      ]) ++
      lib.optionals config.tilde.graphical.photography (with pkgs; [
        darktable # Virtual lighttable and darkroom for photographers
        digikam # Photo Management Program
      ]);
    })
  ];
}
