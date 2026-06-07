{ moduleWithSystem, ... }:
{
  flake.homeModules.waybar = moduleWithSystem (
    { pkgs, ... }:
    {
      lib,
      config,
      ...
    }:
    let
      colors = config.tilde.wayland.theme.colors;
    in
    {
      config = {
        home.packages = [ pkgs.org-clock-dbus ];

        programs.waybar = {
          enable = true;
          systemd.enable = true;
          style = null;

          settings.main = {
            output = [ config.tilde.wayland.primaryOutput ];
            name = lib.mkDefault "main";
            mode = "dock";
            layer = "top";
            exclusive = true;
            position = "bottom";
            height = lib.mkDefault 24;

            modules-left = [
              "niri/workspaces"
              "niri/window"
            ];

            modules-center = [
              "keyboard-state"
              "custom/org-clock-dbus"
              "mpris"
            ];

            modules-right = [
              "wireplumber"
              "backlight"
              "battery"
              "clock"
              "custom/notification"
              "tray"
            ];

            "niri/workspaces" = {
              all-outputs = true;
              current-only = true;
              format = "{icon} {name} [{index}]";
              format-icons = {
                default = "󰍹";
                focused = "󰍹";
                active = "󰶐";
              };
            };

            "niri/window" = {
              format = "{title}";
              separate-outputs = true; # Remove this after getting bar off eDP-1
              icon = true;
              icon-size = config.programs.waybar.settings.main.height - 4;
              "rewrite" = {
                "(.*) — Mozilla Firefox" = "$1";
                "(Emacs:.*) \\[\\d+\\]" = "$1";
              };
            };

            keyboard-state = {
              capslock = true;
              format = "{icon}";
              format-icons = {
                locked = "󰪛 Caps Lock";
                unlocked = "";
              };
            };

            "custom/org-clock-dbus" = {
              exec = "${pkgs.org-clock-dbus}/bin/org-clock-dbus monitor --mode waybar --down-from 25m";
              on-click = "${pkgs.org-clock-dbus}/bin/org-clock-dbus stop";
              return-type = "json";
              format = "{icon} {text}";
              format-icons.running = "";
              max-length = 100;
            };

            mpris = {
              format = "{status_icon} {dynamic}";
              format-paused = "{status_icon} {dynamic}";
              format-stopped = "";
              dynamic-order = [
                "artist"
                "title"
                "album"
              ];
              dynamic-len = 45;
              status-icons = {
                playing = "";
                paused = "";
                stopped = "";
              };
            };

            backlight = {
              format = "{icon} {percent}%";
              format-icons = [
                "󰃞"
                "󰃟"
                "󰃠"
              ];
            };

            battery =
              let
                charging = " {capacity}% {time}";
                discharging = "{icon} {capacity}% ({time}@{power:4.2f})";
              in
              {
                format = charging;
                format-charging = charging;
                format-discharging = discharging;
                format-time = "{H}:{m}";
                format-icons = [
                  "󰂃"
                  "󰁺"
                  "󰁻"
                  "󰁼"
                  "󰁽"
                  "󰁾"
                  "󰁿"
                  "󰂀"
                  "󰂁"
                  "󰂂"
                ];
                states = {
                  warning = 30;
                  critical = 15;
                };
              };

            clock = {
              format = " {:%A, %d %B %Y  %H:%M (%Z)}";
              tooltip-format = "<tt><small>{calendar}</small></tt>";

              calendar = {
                mode = "year";
                mode-mon-col = 3;
                weeks-pos = "right";
                on-scroll = 1;
                format = {
                  months = "{}";
                  days = "<span>{}</span>";
                  weeks = "<span>{}</span>";
                  weekdays = "<span>{}</span>";
                  today = "<span color='${colors.base0B}'><b>{}</b></span>";
                };
              };

              actions = {
                on-scroll-up = "shift_up";
                on-scroll-down = "shift_down";
              };
            };

            "custom/notification" =
              let
                client = "${pkgs.swaynotificationcenter}/bin/swaync-client";
              in
              {
                tooltip = false;
                format = "{icon}";
                format-icons = {
                  notification = "";
                  none = "";
                  dnd-notification = "";
                  dnd-none = "";
                  inhibited-notification = "";
                  inhibited-none = "";
                  dnd-inhibited-notification = "";
                  dnd-inhibited-none = "";
                };
                return-type = "json";
                exec = "${client} -swb";
                on-click = "toggle-presenter-mode";
                escape = true;
              };

            wireplumber = {
              format = "{icon} {volume}%";
              format-muted = "";
              on-click = "";
              format-icons = [
                ""
                ""
                ""
                "󰕾"
              ];
            };

            tray = {
              spacing = 5;
              icon-size = 16;
              show-passive-items = true;
            };
          };
        };

        xdg.configFile."waybar/style.css" = {
          source = "${config.tilde.wayland.theme}/theme/waybar.css";
          onChange = ''
            ${pkgs.procps}/bin/pkill -u $USER -USR2 waybar || true
          '';
        };

        xdg.configFile."waybar/colors.css" = {
          source = "${config.tilde.wayland.theme}/theme/colors.css";
          onChange = ''
            ${pkgs.procps}/bin/pkill -u $USER -USR2 waybar || true
          '';
        };
      };
    }
  );
}
