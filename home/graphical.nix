{ config
, pkgs
, lib
, ...
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
    tilde.programs.browser.enable = lib.mkDefault true;
    tilde.programs.contacts.enable = lib.mkDefault true;
    tilde.programs.gnupg.enable = lib.mkDefault true;
    tilde.programs.gromit-mpx.enable = lib.mkDefault true;
    tilde.programs.recoll.enable = lib.mkDefault true;

    # Communicate with my phone:
    services.kdeconnect = {
      enable = true;
      indicator = true;
    };

    xdg.desktopEntries = {
      image-view = {
        name = "IMV";
        genericName = "Image Viewer";
        exec = "${pkgs.imv}/bin/imv %U";
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

      add-deploy-key =
        let
          script = pkgs.writeShellScript "ssh-add-deploy" ''
            ${pkgs.openssh}/bin/ssh-add ~/keys/ssh/deploy.id_ed25519
          '';
        in
        {
          name = "SSH: Add Deployment Key";
          exec = "${script}";
          icon = "document-open";
          terminal = false;
          categories = [ "Application" ];
        };
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
