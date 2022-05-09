{ config
, pkgs
, lib
, ...
}:
let
  cfg = config.tilde.xsession.lock;

  inhibitCmd =
    let
      path = lib.makeBinPath (with pkgs; [
        bashInteractive # for sh(1)
        coreutils
        procps # for pgrep(1)
        systemd # to run loginctl
        tilde-scripts-lock-screen # for the bluetooth ping script
        xorg.xset
      ]);
      devices = lib.concatStringsSep " "
        cfg.bluetooth.devices;
    in
    pkgs.writeShellScript "inhibit-screensaver" ''
      export PATH=/run/wrappers/bin:${path}:$PATH
      exec >&2 # Redirect stdout to stderr
      ${pkgs.pjones.inhibit-screensaver}/bin/inhibit-screensaver \
        --frequency ${toString cfg.bluetooth.frequency} \
        -- bluetooth-ping.sh ${devices}
    '';
in
{
  options.tilde.xsession.lock = {
    bluetooth = {
      enable = lib.mkEnableOption "Inhibit the lock screen";

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

  config = lib.mkMerge [
    (lib.mkIf
      (false &&
        cfg.bluetooth.enable &&
        pkgs.stdenv.isx86_64 &&
        cfg.bluetooth.devices != [ ])
      {
        # Inhibit the screensaver while Bluetooth devices are nearby:
        systemd.user.services.lock-screen-inhibit = {
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
      })
  ];
}
