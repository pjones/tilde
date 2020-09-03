{ config, pkgs, lib, ... }:
let
  cfg = config.tilde.lock-screen-inhibit;

  bluetoothJSON = pkgs.writeTextFile {
    name = "bluetooth-json";
    text = builtins.toJSON cfg.bluetooth;
  };

  haveBluetoothDevices =
    builtins.length cfg.bluetooth.devices != 0;

  bluetooth-ping = pkgs.writeShellScript "bluetooth-ping"
    (builtins.readFile ./bluetooth-ping.sh);

  onlineFile = "${cfg.bluetooth.directory}/online";

  systemctl = "${pkgs.systemd}/bin/systemctl";
in
{
  options.tilde.lock-screen-inhibit = {
    enable = lib.mkEnableOption "Inhibit the lock screen";

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
        type = lib.types.str;
        default = "*:0/5";
        example = "minutely";
        description = ''
          How often to ping devices given in systemd.time(7) calendar
          event description syntax.
        '';
      };

      directory = lib.mkOption {
        type = lib.types.path;
        default = "/var/lib/bluetooth-device-status";
        description = "Directory where status files are stored.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # systemd service and timer for pining devices:
    systemd =
      let
        name = "bluetooth-ping-devices";
        description = "Ping Bluetooth devices that inhibit the lock screen.";
      in
      {
        services.${name} = lib.mkIf haveBluetoothDevices {
          inherit description;
          serviceConfig.Type = "simple";
          serviceConfig.ExecStart = "${bluetooth-ping} ${bluetoothJSON}";
          path = with pkgs; [ bluez jq ];
        };
        timers.${name} = lib.mkIf haveBluetoothDevices {
          inherit description;
          wantedBy = [ "timers.target" ];
          timerConfig.OnCalendar = cfg.bluetooth.frequency;
          timerConfig.Unit = "${name}.service";
        };
        tmpfiles.rules =
          # Automatically create the status directory, remove all
          # files inside it, and expire files that get too old.  This
          # is important to allow the auto locking to trigger if this
          # module somehow fails to update the online file and it goes
          # stale.
          lib.optional haveBluetoothDevices
            "D ${cfg.bluetooth.directory} 0755 root wheel 10m --remove";
      };

    # Alter home-manager screen-lock settings:
    home-manager.users.${config.tilde.username} = { config, ... }: {
      config = lib.mkIf config.services.screen-locker.enable {
        systemd.user = lib.mkIf haveBluetoothDevices {
          # Prevent auto locker from running if devices are online:
          services.xautolock-session.Unit.ConditionPathExists = "!${onlineFile}";

          # Simple service that will restart auto locking:
          services.bluetooth-device-status = {
            Unit.Description = "Restart services on Bluetooth device changes";
            Install.WantedBy = [ "default.target" ];
            Service.Type = "oneshot";
            Service.ExecStart = "${systemctl} --user restart xautolock-session.service";
          };

          # Trigger the service above when device status files change.
          paths.bluetooth-device-status = {
            Unit.Description = "Inhibit auto locking if bluetooth devices are present";
            Install.WantedBy = [ "default.target" ];
            Path.PathModified = onlineFile;
            Path.Unit = "bluetooth-device-status.service";
          };
        };
      };
    };
  };
}
