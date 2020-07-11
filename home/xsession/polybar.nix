{ config
, pkgs
, lib
, ...
}:
let
  cfg = config.pjones.xsession.polybar;

  colors = import ./colors.nix;
  fonts = import ./fonts.nix { inherit pkgs; };

  # Make the background transparent.
  background = "#88" + lib.removePrefix "#" colors.background;
  foreground = colors.foreground;

  # Wrap an icon with the given color:
  icon = color: str: "%{F${color}}${str}%{F-}";
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
    "date"
    "pulseaudio"
    "temperature"
  ];

  modulesCenter = modList [ ];
in
{
  options.pjones.xsession.polybar = {
    enable = lib.mkEnableOption "Configure and start Polybar";
  };

  config = lib.mkIf cfg.enable {
    services.polybar = {
      enable = true;

      package = pkgs.polybar.override {
        pulseSupport = true;
      };

      script = ''
        polybar primary &
      '';

      config = {
        settings = {
          pseudo-transparency = false;
          screenchange-reload = true;
        };

        #  https://github.com/polybar/polybar/wiki/Module:-xworkspaces
        "module/workspace" = {
          type = "internal/xworkspaces";
          pin-workspaces = false;
          format = "<label-state>";
          label-active = "%index%";
          label-active-padding = 1;
          label-active-underline = colors.active;
          label-occupied = "%index%";
          label-occupied-padding = 1;
          label-urgent = "%index%";
          label-urgent-padding = 2;
          label-urgent-underline = colors.alert;
          label-empty = "%index%";
          label-empty-padding = 1;
        };

        # https://github.com/polybar/polybar/wiki/Module:-xwindow
        "module/window" = {
          type = "internal/xwindow";
          format = "<label>";
          label = iconOkay "" + " %title%";
          label-maxlen = 50;
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

        # https://github.com/polybar/polybar/wiki/Module:-temperature
        "module/temperature" = {
          type = "internal/temperature";
          base-temperature = 40;
          warn-temperature = 80;
          format = "<ramp> <label>";
          format-warn = "<ramp> <label-warn>";
          label = "%temperature-c%";
          label-warn = "%temperature-c%";
          label-warn-underline = colors.warn;
          ramp-0 = iconOkay "";
          ramp-1 = iconWarn "";
          ramp-2 = iconFail "";
        };

        "bar/primary" = {
          inherit background foreground;
          width = "90%";
          height = 20;
          offset-x = "5%";
          radius-bottom = "10.0";
          module-margin = 1;
          line-size = 2;
          padding = 2;

          font-0 = with fonts.primary; "${ftname};${toString offset}";
          font-1 = with fonts.mono; "${ftname};${toString offset}";
          font-2 = with fonts.font-awesome; "${ftname};${toString offset}";
          font-3 = with fonts.twemoji; "${ftname};${toString offset}";
          font-4 = with fonts.weather; "${ftname};${toString offset}";

          enable-ipc = true;
          tray-position = "left";
          tray-padding = 2;
          modules-left = modulesLeft;
          modules-right = modulesRight;
          modules-center = modulesCenter;
        };
      };
    };
  };
}
