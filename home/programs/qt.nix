{ config, lib, pkgs, ... }:
let
  cfg = config.tilde.programs.gtk;

  fonts = import ../misc/fonts.nix { inherit pkgs; };
  colors = import ../misc/colors.nix { inherit pkgs; };
in
{
  options.tilde.programs.qt = {
    enable = lib.mkEnableOption "Qt Configuration";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.libsForQt5.qtstyleplugin-kvantum ];
    home.sessionVariables.QT_STYLE_OVERRIDE = "Kvantum";
    xsession.importedVariables = [ "QT_STYLE_OVERRIDE" ];

    xdg.configFile."Kvantum/kvantum.kvconfig".text = ''
      theme=${colors.theme.name}
    '';

    xdg.configFile."Kvantum/${colors.theme.name}".source =
      "${colors.theme.package}/share/Kvantum/${colors.theme.name}";
  };
}
