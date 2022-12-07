{ pkgs, config, lib, ... }:

let
  cfg = config.tilde.programs.plasma;

  gtkConfig = pkgs.writeShellApplication
    {
      name = "gtk-config";
      runtimeInputs = with pkgs; [ crudini ];
      text = (builtins.readFile ../../support/gtk-config.sh);
    };

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
      pjones.rofirc
      libsForQt5.ktouch # A touch typing tutor from the KDE software collection
      qt5.qttools # for qdbus(1)
    ];

    xdg.desktopEntries = {
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

    home.file = {
      ".local/share/kwin/scripts/jumplist".source =
        builtins.toString (mkKWinScript "jumplist" ../../scripts/kwin/jumplist);

      ".local/share/kwin/scripts/pullwindow".source =
        builtins.toString (mkKWinScript "pullwindow" ../../scripts/kwin/pullwindow);

      ".local/share/kwin/scripts/windowpos".source =
        builtins.toString (mkKWinScript "windowpos" ../../scripts/kwin/windowpos);
    };

    home.activation.configure-gtk = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD ${gtkConfig}/bin/gtk-config
    '';
  };
}
