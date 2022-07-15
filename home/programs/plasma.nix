{ pkgs, config, lib, ... }:

let
  cfg = config.tilde.programs.plasma;

  gtkConfig = pkgs.writeScript "gtk-config"
    (builtins.readFile ../../support/gtk-config.sh);
in
{
  options.tilde.programs.plasma = {
    enable = lib.mkEnableOption "Configure KDE Plasma";
  };

  config = lib.mkIf cfg.enable {
    programs.plasma = (import ../../support/workstation/plasma.nix).programs.plasma;

    home.packages = with pkgs; [
      crudini # For editing the GTK settings.ini file.
      krunner-pass # Access passwords in krunner
      libsForQt5.ktouch # A touch typing tutor from the KDE software collection
      libsForQt5.qtstyleplugin-kvantum # For some themes
      qt5.qttools # for qdbus(1)
    ];

    home.activation.configure-gtk = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD ${gtkConfig}
    '';
  };
}
