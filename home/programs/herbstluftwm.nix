{ pkgs, config, lib, ... }:
let
  cfg = config.tilde.programs.herbstluftwm;

in
{
  options.tilde.programs.herbstluftwm = {
    enable = lib.mkEnableOption ''
      The Herbstluftwm Window Manager as a standalone desktop
      environment
    '';
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      hicolor-icon-theme
      xfce.xfce4-icon-theme
    ];

    gtk.iconTheme = {
      name = "Rodent";
      package = pkgs.xfce.xfce4-icon-theme;
    };

    services.blueman-applet.enable = true;
    services.network-manager-applet.enable = true;

    # Tray icon for disks:
    services.udiskie = {
      enable = true;
      automount = false;
    };

    tilde.programs.dunst.enable = true;
    tilde.programs.polybar.enable = true;
    tilde.programs.screen-lock.enable = true;
    tilde.programs.wallpaper.enable = true;

    xsession = {
      enable = lib.mkDefault true;
      windowManager.command = "${pkgs.pjones.hlwmrc}/libexec/hlwmrc";
    };
  };
}
