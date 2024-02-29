{ config
, pkgs
, lib
, ...
}:
let
  cfg = config.tilde.xsession;
  colors = import misc/colors.nix { inherit pkgs; };
in
{
  options.tilde.xsession = {
    enable = lib.mkEnableOption "Enable an X11 session";

    dpi = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default = null;
      description = ''
        Scale the primary screen by setting its DPI directly.

        The default scale (100%) is 96 DPI.  If you want to scale
        everything up by 150% then set this option to 144.
      '';
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      # Allow other desktop sessions to be started if wanted:
      xsession.scriptPath = ".hm-xsession";

      # Enabling an xsession also enables workstation settings:
      tilde.workstation.enable = true;

      # Enable other xsession modules:
      tilde.programs.browser.enable = lib.mkDefault true;
      tilde.programs.gromit-mpx.enable = lib.mkDefault true;
      tilde.programs.gtk.enable = lib.mkDefault true;
      tilde.programs.herbstluftwm.enable = lib.mkDefault true;
      tilde.programs.qt.enable = lib.mkDefault true;
      tilde.programs.thunderbird.enable = lib.mkDefault true;

      # Hide the mouse cursor when not in use:
      services.unclutter = {
        enable = true;
        extraOptions = [ "ignore-scrolling" ];
      };

      # Communicate with my phone:
      services.kdeconnect = {
        enable = true;
        indicator = true;
      };

      # Use GnuPG and cache passphrases:
      programs.gpg = {
        enable = true;
        homedir = "${config.home.homeDirectory}/keys/gpg";
        settings = {
          default-key = "204284CB";
          default-recipient-self = true;
        };
      };

      services.gpg-agent = {
        enable = true;
        enableSshSupport = false;
        defaultCacheTtl = 3600;
        defaultCacheTtlSsh = 14400;
        maxCacheTtl = 7200;
        maxCacheTtlSsh = 21600;
        pinentryFlavor = "gtk2";
      };

      # And we need a compositor:
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

      xdg.desktopEntries = {
        feh-view = {
          name = "FEH";
          genericName = "Image Viewer";
          exec = "${pkgs.feh}/bin/feh --auto-zoom --scale-down %U";
          terminal = false;
          categories = [ "Application" ];
          mimeType = [ "image/jpeg" "image/png" ];
        };

        memento-mori = {
          name = "Memento Mori";
          exec = "${pkgs.tilde-scripts-misc}/bin/memento-mori.sh";
          icon = "document-open";
          terminal = false;
          categories = [ "Application" ];
        };

        start-desktop-apps = {
          name = "Start Desktop Apps";
          exec = "${pkgs.tilde-scripts-misc}/bin/start-desktop-apps.sh";
          icon = "document-open";
          terminal = false;
          categories = [ "Application" ];
        };

        ssh-add-all = {
          name = "Add All SSH Keys to the Agent";
          exec = "${pkgs.pjones.network-scripts}/bin/ssh-add-all-keys";
          icon = "document-open";
          terminal = false;
          categories = [ "Application" ];
        };

        lock-screen = {
          name = "Lock Screen";
          exec = "loginctl lock-session";
          icon = "emblem-system";
          terminal = false;
          categories = [ "System" ];
        };

        sleep-system = {
          name = "Sleep";
          exec = "systemctl suspend-then-hibernate";
          icon = "emblem-system";
          terminal = false;
          categories = [ "System" ];
        };
      };

      xdg.mimeApps = {
        enable = true;
        defaultApplications = {
          "image/jpeg" = "feh-view.desktop";
          "image/png" = "feh-view.desktop";
          "x-scheme-handler/sgnl" = "signal-desktop.desktop";
          "x-scheme-handler/signalcaptcha" = "signal-desktop.desktop";
        };
      };

      # Some apps are rude and overwrite this file:
      # https://github.com/nix-community/home-manager/issues/1213
      xdg.configFile."mimeapps.list".force = true;

      # X-Resources:
      xresources.properties = {
        "*background" = colors.black;
        "*foreground" = colors.white;
        "*color0" = colors.black;
        # "*color8" = ??;
        "*color1" = colors.red;
        # "*color9" = ??;
        "*color2" = colors.green;
        # "*color10" = ??;
        "*color3" = colors.yellow;
        # "*color11" = ??;
        "*color4" = colors.blue;
        # "*color12" = ??;
        "*color5" = colors.purple;
        "*color13" = colors.darkpurple;
        "*color6" = colors.cyan;
        # "*color14" = ??;
        "*color7" = colors.white;
        "*color15" = colors.gray;
      };

      # For apps that want a user picture like GDM:
      home.file.".face".source = "${pkgs.pjones-avatar}/share/faces/pjones.jpg";

      # Random settings:
      home.activation.random-ini-settings =
        let
          script = pkgs.writeShellApplication {
            name = "set-ini";
            runtimeInputs = with pkgs; [ crudini ];
            text = (builtins.readFile ../support/workstation/set-ini.sh);
          };
        in
        lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          $DRY_RUN_CMD ${script}/bin/set-ini
        '';
    })

    (lib.mkIf (cfg.dpi != null) {
      xresources.properties."Xft.dpi" = cfg.dpi;
    })
  ];
}
