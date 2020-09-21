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

  inhibitCmd =
    let
      path = lib.makeBinPath (with pkgs; [
        coreutils
        procps # for pgrep(1)
        systemd # to run loginctl
        tilde-scripts-lock-screen # for the bluetooth ping script
        xorg.xset
      ]);
      devices = lib.concatStringsSep " "
        cfg.lock.bluetooth.devices;
    in
    pkgs.writeShellScript "inhibit-screensaver" ''
      export PATH=/run/wrappers/bin:${path}:$PATH
      ${pkgs.pjones.inhibit-screensaver.bin}/bin/inhibit-screensaver \
        --frequency ${cfg.lock.bluetooth.frequency} \
        --activate \
        --query 'pgrep i3lock' \
        -- bluetooth-ping.sh ${devices}
    '';
in
{
  options.tilde.xsession.lock = {
    bluetooth = {
      devices = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [
          "BC:A8:A6:7D:A5:77"
        ];
        description = ''
          A list of Bluetooth device MAC addresses in dotted hex
          notation.  If one of these devices can be reached via l2ping
          the lock screen will be inhibited.
        '';
      };

      frequency = lib.mkOption {
        type = lib.types.int;
        default = 120;
        description = "How often to ping devices given in seconds.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.screen-locker = {
      enable = true;
      lockCmd = toString lockCmd;
      inactiveInterval = 10;
    };

    # Disable xautolock-session, it's not needed:
    systemd.user.services.xautolock-session =
      lib.mkForce { };

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

    # Inhibit the screensaver while Bluetooth devices are nearby:
    systemd.user.services.lock-screen-inhibit =
      lib.mkIf (cfg.lock.bluetooth.devices != [ ]) {
        Unit = {
          Description = "Inhibit the lock screen";
          After = [ "graphical-session-pre.target" ];
          PartOf = [ "graphical-session.target" ];
        };

        Install = {
          WantedBy = [ "graphical-session.target" ];
        };

        Service = {
          ExecStart = toString inhibitCmd;
          Restart = "always";
          RestartSec = 3;
        };
      };
  };
}
