{ config
, pkgs
, lib
, ...
}:
let
  cfg = config.tilde.xsession;
  colors = import ../misc/colors.nix;
  images = pkgs.callPackage ../misc/images.nix { };

  path = lib.makeBinPath (with pkgs; [
    tilde-scripts-lock-screen
    i3lock
  ]);

  lockCmd = pkgs.writeShellScript "screen-lock" ''
    # Use a fancy locker, with fallback to simple i3lock:
    export PATH=${path}:$PATH
    lock-screen "${images.lock}" "${colors.background}" ||
      i3lock --nofork --color="${colors.fail}"
  '';

  cacheCmd = pkgs.writeShellScript "image-cache" ''
    export PATH=${path}:$PATH
    image-cache -b ${images.lock}
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
