{ self, moduleWithSystem, ... }:
{
  flake.homeModules.wayle = moduleWithSystem (
    { pkgs, system, ... }:
    { config, lib, ... }:
    let
      cfg = config.tilde.programs.wayle;
    in
    {
      options.tilde.programs.wayle = {
        wallpapers = lib.mkOption {
          type = lib.types.path;
          default = "${config.home.homeDirectory}/documents/pictures/backgrounds/primary";
          description = "Directory of images to display on the primary output";
        };
      };

      config = {
        services.wayle = {
          enable = true;

          settings = {

            general = {
              font-sans = "Atkinson Hyperlegible";
              font-mono = "Hermit";
            };

            styling = {
              theme-provider = "matugen";
              theming-monitor = config.tilde.wayland.primaryOutput;
              matugen-scheme = "rainbow";

              palette = {
                bg = "#282a36";
                surface = "#343746";
                elevated = "#44475a";
                fg = "#f8f8f2";
                fg_muted = "#6272a4";
                primary = "#bd93f9";
                red = "#ff5555";
                yellow = "#f1fa8c";
                green = "#50fa7b";
                blue = "#8be9fd";
              };
            };

            wallpaper = {
              engine-enabled = true;
              cycling-enabled = true;
              cycling-mode = "shuffle";
              cycling-interval-mins = 15;
              cycling-same-image = true;
              cycling-directory = cfg.wallpapers;
            };

            bar = {
              background-opacity = 80;
              button-bg-opacity = 0;
              button-group-background = "transparent";
              button-group-module-gap = 0.0;
              button-group-opacity = 0;
              button-group-rounding = "none";
              button-icon-padding = 0.75;
              button-icon-size = 0.9;
              button-label-weight = "normal";
              button-rounding = "none";
              button-variant = "basic";
              inset-ends = 0.0;
              module-gap = 1.0;
              padding = 0.0;
              rounding = "none";
              scale = 0.9;

              layout = lib.singleton {
                monitor = "*";
                show = true;

                left = [
                  "dashboard"
                  "niri-workspaces"
                ];

                center = [
                  "window-title"

                  {
                    name = "media";
                    modules = [
                      "cava"
                      "media"
                    ];
                  }

                  {
                    class = "org-clock-dbus";
                    module = "custom-org-clock-dbus";
                  }
                ];

                right = [
                  "systray"

                  {
                    name = "status";
                    modules = [
                      "volume"
                      "microphone"
                      "bluetooth"
                      "network"
                      "brightness"
                      "battery"
                    ];
                  }

                  "clock"

                  {
                    name = "state";
                    modules = [
                      "notifications"
                      "idle-inhibit"
                    ];
                  }
                ];
              };
            };

            modules = {
              bluetooth = {
                icon-show = true;
                label-show = false;
              };

              cava = {
                bars = 7;
                bar-width = 3;
              };

              clock = {
                icon-name = "ld-watch-symbolic";
                format = "%Y-%m-%d %H:%M (%Z)";
              };

              dashboard = {
                icon-color = "blue";
                dropdown-lock-command = "loginctl lock-session";
                right-click = "${self.packages.${system}.superkey}/bin/superkey-panel.sh -H";
                middle-click = "${self.packages.${system}.superkey}/bin/superkey-panel.sh";
              };

              idle-inhibit = {
                icon-show = true;
                label-show = false;
                icon-active = "tb-device-projector-symbolic";
                icon-inactive = "tb-device-desktop-analytics-symbolic";
                format = "{{ duration }}";
                left-click = "${self.packages.${system}.superkey}/bin/superkey-presenter.sh";
                right-click = "";
              };

              network = {
                icon-show = true;
                label-show = false;
                wired-connected-icon = "ld-ethernet-port-symbolic";
              };

              niri-workspaces = {
                active-indicator = "underline";
                hide-trailing-empty = false;
                label-size = 0.75;
                label-strategy = "index-and-name";
                monitor-specific = false;
                workspace-padding = 0.25;
                left-click = "${self.packages.${system}.superkey}/bin/superkey-workspace.sh -t";
              };

              notifications = {
                icon-show = true;
                label-show = false;
                icon-name = "ld-message-square-dashed-symbolic";
                icon-dnd = "ld-message-square-off-symbolic";
                icon-unread = "ld-message-square-warning-symbolic";
              };

              media = {
                icon-type = "application-mapped";
                format = "{{ artist }}: {{ title }} ({{ album }})";

                player-priority = [
                  "*mpv*"
                  "*spotify*"
                  "*firefox*"
                ];

                player-icons = {
                  "*.mpv" = "ld-play-circle-symbolic";
                  "*spotify*" = "si-spotify-symbolic";
                  "*firefox*" = "ld-globe-symbolic";
                };
              };

              microphone = {
                icon-show = true;
                label-show = false;
                right-click = "wayle audio input-mute";
              };

              systray = {
                blacklist = [
                  "*Bitwarden*"
                  "*blueman*"
                  "*Connect*"
                  "*nm-applet*"
                  "*remmina*"
                  "*spotify*"
                ];

                overrides = [
                  {
                    name = "*udisk*";
                    icon = "tb-device-floppy-symbolic";
                    color = "blue";
                  }
                ];
              };

              volume = {
                icon-show = true;
                label-show = false;
                right-click = "wayle audio output-mute";
              };

              weather = {
                location = "Tübingen";
              };

              custom = [
                {
                  id = "org-clock-dbus";
                  icon-name = "tb-time-duration-30-symbolic";
                  command = "${pkgs.org-clock-dbus}/bin/org-clock-dbus monitor --mode wayle --down-from 25m";
                  left-click = "${pkgs.org-clock-dbus}/bin/org-clock-dbus stop";
                  mode = "watch";
                  format = "{{ text }}";
                  class-format = "{{ sign }}";
                  hide-if-empty = true;
                }
              ];
            };
          };
        };

        # Automatically sync icons used in the configuration file.
        xdg.configFile."wayle/config.toml".onChange = ''
          ${config.services.wayle.package}/bin/wayle icons sync || :
        '';

        xdg.configFile."wayle/styles/index.scss".text = ''
          .org-clock-dbus.negative menubutton.bar-button {
            --bar-btn-label-color: var(--bg-surface);
            --bar-btn-bg: var(--status-error);
            --bar-button-bg-opacity: 80%;
            --bar-btn-label-weight: 700;

            image {
              --bar-btn-icon-color: var(--bg-surface);
            }
          }
        '';
      };
    }
  );

}
