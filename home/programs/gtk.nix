{ config, lib, pkgs, ... }:
let
  cfg = config.tilde.programs.gtk;

  fonts = import ../misc/fonts.nix { inherit pkgs; };
  colors = import ../misc/colors.nix { inherit pkgs; };
in
{
  options.tilde.programs.gtk = {
    enable = lib.mkEnableOption "GTK Configuration";
  };

  config = lib.mkIf cfg.enable {
    # For Gnome settings:
    dconf.enable = true;

    gtk = {
      enable = true;
      theme = colors.theme;
      font = { inherit (fonts.primary) package name; };

      gtk2.extraConfig = ''
        gtk-key-theme-name="Emacs"
      '';

      gtk3.extraConfig = {
        gtk-key-theme-name = "Emacs";
      };
    };
  };
}
