{ config, pkgs, lib, ... }:
let
  cfg = config.tilde.programs.screen-lock;
  colors = pkgs.callPackage ../misc/colors.nix { };
  images = pkgs.callPackage ../misc/images.nix { };

  path = lib.makeBinPath (with pkgs; [
    tilde-scripts-lock-screen
    i3lock
  ]);

  lockCmd = pkgs.writeShellScript "screen-lock" ''
    # Use a fancy locker, with fallback to simple i3lock:
    export PATH=${path}:$PATH
    lock-screen "${images.lock}" "${cfg.directory}" "${colors.background}" ||
      i3lock --nofork --color="${colors.fail}"
  '';

  cacheCmd = pkgs.writeShellScript "image-cache" ''
    export PATH=${path}:$PATH
    image-cache -b ${images.lock} -d ${cfg.directory}
  '';
in
{
  options.tilde.programs.screen-lock = {
    enable = lib.mkEnableOption "Screen/session locker";

    directory = lib.mkOption {
      type = lib.types.path;
      default = "${config.xdg.configHome}/lock-screen";
      description = "Directory of images";
    };

    lockAfterMin = lib.mkOption {
      type = lib.types.int;
      default = 30;
      description = ''
        Automatically lock the screen after the given number of
        minutes.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.screen-locker = {
      enable = true;
      lockCmd = toString lockCmd;
      inactiveInterval = cfg.lockAfterMin;
      xss-lock.screensaverCycle = cfg.lockAfterMin * 60;
    };

    # Cache correctly sized images for the lock screen:
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
