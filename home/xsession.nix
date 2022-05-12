{ config
, pkgs
, lib
, ...
}:
let
  cfg = config.tilde.xsession;

in
{
  options.tilde.xsession = {
    enable = lib.mkEnableOption "Enable an X11 session";
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      # Enabling an xsession also enables workstation settings:
      tilde.workstation.enable = true;

      # Enable other xsession modules:
      tilde.programs.browser.enable = lib.mkDefault true;
      tilde.programs.gromit-mpx.enable = lib.mkDefault true;
      tilde.programs.konsole.enable = lib.mkDefault true;
      tilde.programs.oled-display.enable = lib.mkDefault true;
      tilde.programs.plasma.enable = lib.mkDefault true;

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

        start-desktop-apps = {
          name = "Start Desktop Apps";
          exec = "${../scripts/misc/start-desktop-apps.sh}";
          terminal = false;
          categories = [ "Application" ];
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

      # Make Plasma load the Home Manager environment:
      xdg.configFile."plasma-workspace/env/hm-session-vars.sh".text = ''
        if [ -e "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh" ]; then
          . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
        fi

        if [ -e "/etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh" ]; then
          . "/etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh"
        fi
      '';
    })
  ];
}
