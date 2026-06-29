{ self, moduleWithSystem, ... }:
{
  flake.nixosModules.basic = moduleWithSystem (
    { ... }:
    { ... }:
    {
      # Placeholder.
    }
  );

  flake.homeModules.basic = moduleWithSystem (
    { pkgs, ... }:
    { ... }:
    {
      imports = with self.homeModules; [
        git
        shells
      ];

      home.packages =
        with pkgs;
        [
          acl # Library and tools for manipulating access control lists
          bind # For dig(1): Domain name server
          binutils # Tools for manipulating binaries (linker, assembler, etc.)
          coreutils # The basic file, shell and text manipulation utilities of the GNU operating system
          curl # A command line tool for transferring files with URL syntax
          file # A program that shows the type of files
          gawk # GNU implementation of the Awk programming language
          gnugrep # GNU implementation of the Unix grep command
          gnumake # A tool to control the generation of non-source files from sources
          htop # An interactive process viewer for Linux
          inetutils # Collection of common network programs
          jq # A lightweight and flexible command-line JSON processor
          openssh # An implementation of the SSH protocol
          rdiff-backup # Backup system trying to combine best a mirror and an incremental backup system
          rsync # A fast incremental file transfer utility
          tmux # Terminal multiplexer
          tree # Command to produce a depth indented directory listing
          unzip # An extraction utility for archives compressed in .zip format
          which # Shows the full path of (shell) commands
          yt-dlp # Command-line tool to download videos from YouTube.com and other sites (youtube-dl fork)
          zip # Compressor/archiver for creating and modifying zipfiles
        ]
        ++ lib.optionals pkgs.stdenv.isLinux (
          with pkgs;
          [
            cryptsetup # LUKS for dm-crypt
            inotify-tools # Command-line programs providing a simple interface to inotify
            lm_sensors # Tools for reading hardware sensors
            lsscsi
            parted # Create, destroy, resize, check, and copy partitions
            pciutils # Collection of programs for inspecting and manipulating configuration of PCI devices
            procps # Utilities that give information about processes using the /proc filesystem
            psmisc # A set of small useful utilities that use the proc filesystem (such as fuser, killall and pstree)
            usbutils # Tools for working with USB devices, such as lsusb
          ]
        );
    }
  );
}
