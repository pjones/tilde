{ config
, pkgs
, lib
, ...
}:
let
  cfg = config.tilde.xsession;
  colors = import ../misc/colors.nix;
  images = pkgs.callPackage ../misc/images.nix { };
  scripts = pkgs.callPackage ../../scripts { };

  inputs = (with pkgs; [
    coreutils
    findutils
    gnugrep
    i3lock
    imagemagick
    inotifyTools
    polybar-scripts.player-mpris-tail
    xorg.xrandr
    xorg.xset
  ]) ++ [ scripts ];

  PATH = lib.concatMapStringsSep ":" (p: "${p}/bin") inputs;

  lockCmd = pkgs.writeShellScript "screen-lock" ''
    export PATH=${PATH}:$PATH

    # Use a fancy locker, with fallback to simple i3lock:
    lock-screen "${images.lock}" "${colors.background}" ||
      i3lock --nofork --color="${colors.fail}"
  '';

  cacheCmd = pkgs.writeShellScript "image-cache" ''
    export PATH=${PATH}:$PATH
    ${scripts}/bin/image-cache -b ${images.lock}
  '';
in
{
  config = lib.mkIf cfg.enable {
    services.screen-locker = {
      enable = true;
      lockCmd = toString lockCmd;
      inactiveInterval = 10;
    };

    systemd.user.services.lock-screen-image-cache = {
      Unit = {
        Description = "Cache lock screen images";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = toString cacheCmd;
        Restart = "always";
        RestartSec = 3;
      };
    };
  };
}
