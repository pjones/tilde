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
      herbstluftwm
      libsForQt5.ktouch # A touch typing tutor from the KDE software collection
      pjones.rofirc
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

    # Make Plasma load the Home Manager environment:
    xdg.configFile."plasma-workspace/env/hm-session-vars.sh".text = ''
      if [ -e "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh" ]; then
        . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
      fi

      if [ -e "/etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh" ]; then
        . "/etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh"
      fi
    '';

    # https://maxnatt.gitlab.io/posts/kde-plasma-with-i3wm/#kde-525-and-newer
    systemd.user.services.plasma-herbstluftwm = {
      Unit = {
        Description = "Use herbstluftwm instead of KWin";
        Before = [ "plasma-workspace.target" ];
      };

      Install = {
        WantedBy = [ "plasma-workspace.target" ];
      };

      Service = {
        ExecStart = "${pkgs.pjones.hlwmrc}/libexec/hlwmrc";
        Restart = "on-failure";
        RestartSec = 3;
      };
    };

    # Disable KWin:
    home.activation.disableKWin = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      $DRY_RUN_CMD ln -nfs /dev/null ~/.config/systemd/user/plasma-kwin_x11.service
    '';

    # And we need a compositor:
    services.picom = {
      enable = true;
      fade = true;
    };

    # Update GTK settings:
    home.activation.configure-gtk = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD ${gtkConfig}/bin/gtk-config
    '';
  };
}
