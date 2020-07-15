{ config
, pkgs
, lib
, ...
}:
let
  cfg = config.pjones.xsession.polybar;
  oled = config.pjones.programs.oled-display;

  colors = import ./colors.nix;
  fonts = import ./fonts.nix { inherit pkgs; };

  player-mpris-tail = pkgs.writeShellScriptBin "player-mpris-tail" ''
    ${pkgs.polybar-scripts.player-mpris-tail}/bin/player-mpris-tail \
      --icon-playing "${iconOkay ""}" \
      --icon-paused "${iconOkay ""}" \
      --icon-stopped "${iconOkay ""}" \
      --icon-none "" \
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
  iconOkay = icon colors.okay;
  iconWarn = icon colors.warn;
  iconFail = icon colors.fail;

  # Function to generate a module list:
  modList = lib.concatStringsSep " ";

  # Active modules:
  modulesLeft = modList [
    "workspace"
    "window"
  ];

  modulesRight = modList [
    "pulseaudio"
    "temperature"
    "date"
  ];

  modulesCenter = modList
    ([
      "mpris"
    ] ++ lib.optional oled.enable "pomodoro");
in
{
  options.pjones.xsession.polybar = {
    enable = lib.mkEnableOption "Configure and start Polybar";

    thermalZone = lib.mkOption {
      type = lib.types.int;
      default = 1;
      description = ''
        Which thermal zone to use for the temperature gauge.  To get a
        list of termal zones use this shell fragment:

        for i in /sys/class/thermal/thermal_zone*; do echo "$i: $(<$i/type)"; done
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ player-mpris-tail ];

    services.polybar = {
      enable = true;

      package = pkgs.polybar.override {
        pulseSupport = true;
      };

      script = ''
        export PATH=${pkgs.coreutils}/bin:${pkgs.procps}/bin:$PATH

        {
          # Give xmonad a second to start and advertise EWMH support.
          while ! pgrep xmonadrc; do sleep 1; done
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
          label-active = "%{F${colors.active}}%index%%{F-}";
          label-active-padding = 1;
          label-active-underline = colors.active;
          label-occupied = "%{F${colors.foreground}}%index%%{F-}";
          label-occupied-padding = 1;
          label-urgent = "%{F${colors.alert}}%index%%{F-}";
          label-urgent-padding = 2;
          label-urgent-underline = colors.alert;
          label-empty = "%{F${colors.foreground-dim}}%index%%{F-}";
          label-empty-padding = 1;
        };

        # https://github.com/polybar/polybar/wiki/Module:-xwindow
        "module/window" = {
          type = "internal/xwindow";
          format = "<label>";
          label = iconOkay "" + " %title%";
          label-maxlen = 100;
          label-empty = "";
        };

        # https://github.com/polybar/polybar/wiki/Module:-date
        "module/date" = {
          type = "internal/date";
          label = iconOkay "" + " %date% %time%";
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

        # https://github.com/polybar/polybar-scripts/tree/master/polybar-scripts/player-mpris-tail
        "module/mpris" = {
          type = "custom/script";
          exec = "${player-mpris-tail}/bin/player-mpris-tail";
          tail = true;
        };

        # https://github.com/polybar/polybar/wiki/Module:-temperature
        "module/temperature" = {
          type = "internal/temperature";
          thermal-zone = cfg.thermalZone;
          units = false;
          base-temperature = 40;
          warn-temperature = 80;
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

        "module/menu" = {
          type = "custom/menu";
          label-open = "";
          label-close = iconWarn "" + " ";
          label-separator = "|";

          menu-0-0 = "Polybar Tray";
          menu-0-0-exec = "polybar tray &";
        };

        "module/quit" = {
          type = "custom/ipc";
          format = iconOkay "";
          hook-0 = "echo"; # Because you have to define *something*.
          click-left = "polybar-msg -p %pid% cmd quit";
        };

        "base" = {
          inherit background foreground;

          module-margin = 3;
          line-size = 2;
          padding = 2;

          font-0 = with fonts.polybar; "${ftname};${toString offset}";
          font-1 = with fonts.font-awesome; "${ftname};${toString offset}";
          font-2 = with fonts.twemoji; "${ftname};${toString offset}";
          font-3 = with fonts.weather; "${ftname};${toString offset}";
          font-4 = with fonts.mono; "${ftname};${toString offset}";

          enable-ipc = true;
        };

        "bar/primary" = {
          "inherit" = "base";
          width = "90%";
          height = 20;
          offset-x = "5%";
          radius-bottom = "8.0";
          modules-left = modulesLeft;
          modules-right = modulesRight;
          modules-center = modulesCenter;
        };

        "bar/tray" = {
          "inherit" = "base";
          width = 100;
          height = 20;
          tray-position = "right";
          modules-left = "quit";
        };
      };
    };
  };
}
