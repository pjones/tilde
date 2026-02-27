{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.tilde.graphical;
in
{
  options.tilde.graphical = {
    enable = lib.mkEnableOption "Enable a graphical session";

    design = lib.mkEnableOption "Configure for 3D printing";
    ee = lib.mkEnableOption "Configure for Electrical Engineering";
    gis = lib.mkEnableOption "Configure for mapping and GIS";
    photography = lib.mkEnableOption "Configure for photography";
  };

  config = lib.mkIf cfg.enable {
    # Enabling an graphical also enables workstation settings:
    tilde.workstation.enable = true;

    # Enable other graphical modules:
    tilde.programs.beamerpresenter.enable = lib.mkDefault true;
    tilde.programs.browser.enable = lib.mkDefault true;
    tilde.programs.contacts.enable = lib.mkDefault true;
    tilde.programs.gnupg.enable = lib.mkDefault true;
    tilde.programs.gromit-mpx.enable = lib.mkDefault true;
    tilde.programs.peaclock.enable = lib.mkDefault true;
    tilde.programs.recoll.enable = lib.mkDefault true;

    # Manually allow applications access to the network:
    services.opensnitch-ui.enable = true;

    # Password management:
    services.pass-secret-service.enable = true;

    # Communicate with my phone:
    services.kdeconnect = {
      enable = true;
      indicator = true;
    };

    xdg.desktopEntries =
      let
        url = name: url: {
          inherit name;
          exec = "browser ${url}";
          icon = "user-bookmarks";
          terminal = false;
        };
      in
      {
        image-view = {
          name = "IMV";
          genericName = "Image Viewer";
          exec = "${pkgs.imv}/bin/imv %U";
          terminal = false;
          categories = [ "Application" ];
          mimeType = [
            "image/jpeg"
            "image/png"
          ];
        };

        memento-mori = {
          name = "Memento Mori";
          exec = "${pkgs.tilde-scripts-misc}/bin/memento-mori.sh";
          icon = "image-x-generic";
          terminal = false;
          categories = [ "Application" ];
        };

        start-desktop-apps = {
          name = "Start Desktop Apps";
          exec = "${pkgs.tilde-scripts-misc}/bin/start-desktop-apps.sh";
          icon = "text-x-script";
          terminal = false;
          categories = [ "Application" ];
        };

        add-deploy-key =
          let
            script = pkgs.writeShellScript "ssh-add-deploy" ''
              ${pkgs.openssh}/bin/ssh-add ~/keys/ssh/deploy.id_ed25519
            '';
          in
          {
            name = "SSH: Add Deployment Key";
            exec = "${script}";
            icon = "text-x-script";
            terminal = false;
            categories = [ "Application" ];
          };

        calendar = url "Calendar" "https://app.fastmail.com/calendar/month";
        discord = url "Discord" "https://discord.com/channels/688750797378682946/689772813481279547";
        google-voice = url "Google Voice" "https://voice.google.com/u/0/messages";
        mastodon = url "Mastodon" "https://hostux.social/";
        slack = url "Slack" "https://app.slack.com/client/T0304H0EMPS/C08T7QXJX0A";
        whatsapp = url "WhatsApp" "https://web.whatsapp.com/";
      };

    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "image/jpeg" = "image-view.desktop";
        "image/png" = "image-view.desktop";
        "x-scheme-handler/sgnl" = "signal-desktop.desktop";
        "x-scheme-handler/signalcaptcha" = "signal-desktop.desktop";
      };
    };

    # Some apps are rude and overwrite this file:
    # https://github.com/nix-community/home-manager/issues/1213
    xdg.configFile."mimeapps.list".force = true;
  };
}
