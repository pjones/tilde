{ config
, pkgs
, lib
, ...
}:
let
  cfg = config.pjones.xsession;
  colors = import ../misc/colors.nix;
  images = pkgs.callPackage ../misc/images.nix { };
  scripts = pkgs.callPackage ../../scripts { };

  inputs = (with pkgs; [
    coreutils
    findutils
    gnugrep
    i3lock
    imagemagick
    polybar-scripts.player-mpris-tail
    xorg.xrandr
    xorg.xset
  ]) ++ [ scripts ];

  lockCmd = pkgs.writeShellScript "screen-lock" ''
    export PATH=${lib.concatMapStringsSep ":" (p: "${p}/bin") inputs}:$PATH

    # Use a fancy locker, with fallback to simple i3lock:
    lock-screen "${images.lock}" "${colors.background}" ||
      i3lock --nofork --color="${colors.fail}"
  '';
in
{
  config = lib.mkIf cfg.enable {
    services.screen-locker = {
      enable = true;
      lockCmd = toString lockCmd;
      inactiveInterval = 10;
    };
  };
}
