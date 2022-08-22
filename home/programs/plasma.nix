{ pkgs, config, lib, ... }:

let
  cfg = config.tilde.programs.plasma;

  gtkConfig = pkgs.writeScript "gtk-config"
    (builtins.readFile ../../support/gtk-config.sh);

  mkKWinScript = name: src:
    pkgs.stdenvNoCC.mkDerivation {
      inherit name src;
      phases = [ "unpackPhase" "installPhase" "fixupPhase" ];

      installPhase = ''
        mkdir -p "$out/contents/code"
        cp ${name}.js "$out/contents/code/main.js"
        cp metadata.* "$out"
      '';
    };
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

    home.file = {
      ".local/share/kwin/scripts/jumplist".source =
        builtins.toString (mkKWinScript "jumplist" ../../scripts/kwin/jumplist);

      ".local/share/kwin/scripts/pullwindow".source =
        builtins.toString (mkKWinScript "pullwindow" ../../scripts/kwin/pullwindow);

      ".local/share/kwin/scripts/windowpos".source =
        builtins.toString (mkKWinScript "windowpos" ../../scripts/kwin/windowpos);
    };

    home.activation.configure-gtk = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD ${gtkConfig}
    '';
  };
}
