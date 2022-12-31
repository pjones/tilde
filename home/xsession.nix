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
  };

  config = lib.mkIf cfg.enable {
    # Allow other desktop sessions to be started if wanted:
    xsession.scriptPath = ".hm-xsession";

    # Enabling an xsession also enables workstation settings:
    tilde.workstation.enable = true;

    # Enable other xsession modules:
    services.blueman-applet.enable = true;
    tilde.programs.browser.enable = lib.mkDefault true;
    tilde.programs.gromit-mpx.enable = lib.mkDefault true;
    tilde.programs.gtk.enable = lib.mkDefault true;
    tilde.programs.konsole.enable = lib.mkDefault true;
    tilde.programs.qt.enable = lib.mkDefault true;
    tilde.programs.xfce.enable = lib.mkDefault true;

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

    # Cache passphrases and keys:
    services.gpg-agent = {
      enable = true;
      enableSshSupport = true;
      defaultCacheTtl = 3600;
      defaultCacheTtlSsh = 14400;
      maxCacheTtl = 7200;
      maxCacheTtlSsh = 21600;
      pinentryFlavor = "qt";
    };

    # Tray icon for disks:
    services.udiskie = {
      enable = true;
      automount = false;
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
      pictures = "$HOME/.config/wallpapers";
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

      start-desktop-apps = {
        name = "Start Desktop Apps";
        exec = "${../scripts/misc/start-desktop-apps.sh}";
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
        "x-scheme-handler/element" = "element-desktop.desktop";
        "x-scheme-handler/sgnl" = "signal-desktop.desktop";
        "x-scheme-handler/signalcaptcha" = "signal-desktop.desktop";
        "x-scheme-handler/slack" = "slack.desktop";
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

    # XCursor:
    # xsession.pointerCursor = cursor;

    # https://github.com/nix-community/home-manager/issues/2064
    #   systemd.user.targets.tray = {
    #     Unit = {
    #       Description = "Home Manager System Tray";
    #       Requires = [ "graphical-session-pre.target" ];
    #     };
    #   };
  };
}
