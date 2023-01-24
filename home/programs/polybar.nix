{ config
, pkgs
, lib
, ...
}:
let
  cfg = config.tilde.programs.polybar;
  oled = config.tilde.programs.oled-display;

  colors = import ../misc/colors.nix { inherit pkgs; };
  fonts = import ../misc/fonts.nix { inherit pkgs; };

  player-mpris-tail = pkgs.writeShellScriptBin "player-mpris-tail" ''
    ${pkgs.player-mpris-tail}/bin/player-mpris-tail \
      --icon-playing "${iconOkay ""}" \
      --icon-paused "${iconOkay ""}" \
      --icon-stopped "${iconDim ""}" \
      --icon-none "" \
      --format "{icon} {artist} - {title} ({album})" \
      --blacklist vlc \
      "$@"
  '';

  pomodoro-curl = pkgs.writeShellScript "pomodoro-curl" ''
    ${pkgs.curl}/bin/curl \
      --silent \
      --unix-socket ${oled.socket} \
      --no-buffer \
      http://localhost/stream
  '';

  # Make the background transparent.
  background = "#cc" + lib.removePrefix "#" colors.background;
  foreground = colors.foreground;

  # Wrap an icon with the given color:
  icon = color: str: "%{T1}%{F${color}}${str}%{F-}%{T-}";
  iconDim = icon colors.background-offset;
  iconOkay = icon colors.okay;
  iconWarn = icon colors.warn;
  iconFail = icon colors.fail;

  # Function to generate a module list:
  modList = lib.concatStringsSep " ";

  # Active modules:
  modulesLeft = modList [
    "workspace"
  ];

  modulesRight = modList
    ([
      # "temperature"
      "pulseaudio"
    ]
    ++ lib.optional cfg.backlight.enable "backlight"
    ++ lib.optional cfg.power.enable "battery"
    ++ [ "date" ]);

  modulesCenter = modList
    ([
      "xkeyboard"
      "mpris"
    ] ++ lib.optional oled.enable "pomodoro");
in
{
  options.tilde.programs.polybar = {
    enable = lib.mkEnableOption "Configure and start Polybar";

    power = {
      enable = lib.mkEnableOption "Battery Display";

      battery = lib.mkOption {
        type = lib.types.str;
        default = "BAT0";
        description = ''
          Which battery to monitor.  The following command can be used
          to find a list of batteries:

          ls -1 /sys/class/power_supply/
        '';
      };

      adapter = lib.mkOption {
        type = lib.types.str;
        default = "AC";
        description = ''
          Which power adapter to monitor.  The following command can be
          used to find a list of power adapters:

          ls -1 /sys/class/power_supply/
        '';
      };
    };

    backlight = {
      enable = lib.mkEnableOption "Backlight Display";
      device = lib.mkOption {
        type = lib.types.str;
        default = "intel_backlight";
        description = ''
          The device/card to connect to and monitor.  The following
          command can be used to find a list of backlight devices:

          ls -1 /sys/class/backlight/
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ player-mpris-tail ];

    services.polybar = {
      enable = true;

      package = pkgs.polybar.override {
        pulseSupport = true;
      };

      script =
        let
          path = lib.makeBinPath (with pkgs; [
            coreutils
            procps
            tilde-scripts-misc
          ]);
        in
        ''
          export PATH=${path}:$PATH
          # FIXME: export CORETEMP=$(find-hwmon-device.sh -s coretemp.0)/temp1_input

          # Give herbstluftwm a second to start and advertise EWMH support.
          #
          # Starting this group in the background is important so
          # systemd doesn't sit and wait for polybar to timeout, all
          # while holding up the X session.
          {
            while ! pgrep herbstluftwm; do sleep 1; done
            sleep 1
            polybar primary
          } &
        '';

      config = {
        settings = {
          pseudo-transparency = false;
          screenchange-reload = true;
        };

        # https://github.com/polybar/polybar/wiki/Module:-xworkspaces
        "module/workspace" = {
          type = "internal/xworkspaces";
          pin-workspaces = false;
          format = iconOkay "" + " <label-state>";
          label-active = "%index%:%name%";
          label-active-padding = 1;
          label-urgent = "%{F${colors.alert}}%name%%{F-}";
          label-urgent-padding = 2;
          label-urgent-underline = colors.alert;
          label-occupied = "";
          label-occupied-padding = 0;
          label-empty = "";
          label-empty-padding = 0;
        };

        # https://github.com/polybar/polybar/wiki/Module:-date
        "module/date" = {
          type = "internal/date";
          label = iconOkay "" + " %date% " + iconOkay "" + " %time%";
          date-alt = "%Y-%m-%d";
          time-alt = "%H:%M:%S";
          date = "%A, %d %B %Y";
          time = "%H:%M";
        };

        # https://github.com/polybar/polybar/wiki/Module:-pulseaudio
        "module/pulseaudio" = {
          type = "internal/pulseaudio";
          format-volume = "<ramp-volume> <label-volume>";
          label-muted = iconWarn "";
          ramp-volume-0 = iconOkay "";
          ramp-volume-1 = iconOkay "";
          ramp-volume-2 = iconOkay "";
        };

        # https://github.com/polybar/polybar/wiki/Module:-battery
        "module/battery" = {
          type = "internal/battery";
          battery = cfg.power.battery;
          adapter = cfg.power.adapter;
          time-format = "%H:%M";
          format-charging = "<animation-charging> <label-charging>";
          format-discharging = "<ramp-capacity> <label-discharging>";
          format-full = "<ramp-capacity> <label-full>";
          label-charging = "%percentage%%";
          label-discharging = "%percentage%% (%time%@%consumption%W)";
          label-full = "%percentage%%";
          ramp-capacity-0 = iconFail "";
          ramp-capacity-1 = iconWarn "";
          ramp-capacity-2 = iconOkay "";
          ramp-capacity-3 = iconOkay "";
          ramp-capacity-4 = iconOkay "";

          animation-charging-0 = iconOkay "";
          animation-charging-1 = iconOkay "";
          animation-charging-2 = iconOkay "";
          animation-charging-3 = iconOkay "";
          animation-charging-4 = iconOkay "";
          animation-charging-framerate = 750;
        };

        # https://github.com/polybar/polybar/wiki/Module:-backlight
        "module/backlight" = {
          type = "internal/backlight";
          card = cfg.backlight.device;
          format = "<ramp> <label>";
          label = "%percentage%%";
          ramp-0 = iconOkay "";
          ramp-1 = iconOkay "";
          ramp-2 = iconOkay "";
          ramp-3 = iconOkay "";
          ramp-4 = iconOkay "";
        };

        # https://github.com/polybar/polybar-scripts/tree/master/polybar-scripts/player-mpris-tail
        "module/mpris" = {
          type = "custom/script";
          exec = "${player-mpris-tail}/bin/player-mpris-tail";
          tail = true;
        };

        "module/xkeyboard" = {
          type = "internal/xkeyboard";
          format = "<label-indicator>";
          blacklist-0 = "num lock";
          blacklist-1 = "scroll lock";
          label-indicator = "%icon%";
          indicator-icon-0 = "caps lock;;${iconFail ""}";
        };

        # https://github.com/polybar/polybar/wiki/Module:-temperature
        "module/temperature" = {
          type = "internal/temperature";
          hwmon-path = "\${env:CORETEMP}";
          units = false;
          base-temperature = 60;
          warn-temperature = 86;
          format = "<ramp> <label>°";
          format-warn = "<ramp> <label-warn>°";
          label = "%temperature-c%";
          label-warn = "%temperature-c%";
          label-warn-underline = colors.warn;
          ramp-0 = iconOkay "";
          ramp-1 = iconWarn "";
          ramp-2 = iconFail "";
        };

        # https://github.com/pjones/oled-display
        "module/pomodoro" = {
          type = "custom/script";
          exec = toString pomodoro-curl;
          exec-if = "test -S ${oled.socket}";
          tail = true;
          label = iconOkay "" + " %output%";
        };

        "base" = {
          inherit background foreground;

          module-margin = 3;
          line-size = 2;
          padding = 2;

          font-0 = with fonts.polybar; "${ftname};${toString offset}";
          font-1 = with fonts.font-awesome; "${ftname};${toString offset}";
          font-2 = with fonts.mono; "${ftname};${toString offset}";

          enable-ipc = true;
        };

        "bar/primary" = {
          "inherit" = "base";
          bottom = true;
          width = "100%";

          height =
            let
              base = 24;
              dpi = config.tilde.xsession.dpi;
              scaled =
                if dpi != null
                then builtins.floor (base * dpi / 96)
                else base;
            in
            scaled;

          modules-left = modulesLeft;
          modules-right = modulesRight;
          modules-center = modulesCenter;

          tray-position = "left";
          tray-detached = false;
          tray-padding = 4;
        };
      };
    };
  };
}
