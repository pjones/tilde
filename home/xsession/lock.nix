{ config
, pkgs
, lib
, ...
}:
let
  cfg = config.pjones.xsession;
  colors = import ./colors.nix;
  images = pkgs.callPackage ./images.nix { };
  scripts = pkgs.callPackage ../../scripts { };

  inputs = with pkgs; [
    coreutils
    findutils
    i3lock
    xorg.xset
  ];

  lockCmd = pkgs.writeShellScript "screen-lock" ''
    set -e
    set -u

    PATH=${lib.concatMapStringsSep ":" (p: "${p}/bin") inputs}:$PATH

    disable_dpms() {
      xset dpms 0 0 0
    }

    trap disable_dpms HUP INT TERM

    image=$(${scripts}/bin/random-file \
      -g "[!.]*.png" \
      -d ~/documents/pictures/backgrounds/lock-screen \
      -D "${images.lock}")

    xset +dpms dpms 5 5 5

    i3lock \
      --nofork \
      --image="$image" \
      --color="${colors.background}" \
      --ignore-empty-password \
      --show-failed-attempts

    disable_dpms
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
