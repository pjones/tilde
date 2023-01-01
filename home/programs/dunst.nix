{ config, pkgs, lib, ... }:
let
  cfg = config.tilde.programs.dunst;

  fonts = pkgs.callPackage ../misc/fonts.nix { };
  colors = pkgs.callPackage ../misc/colors.nix { };

  dmenu = pkgs.writeShellScript "rofi-dmenu" ''
    ${pkgs.rofi}/bin/rofi -dmenu "$@"
  '';

in
{
  options.tilde.programs.dunst = {
    enable = lib.mkEnableOption ''
      Install and configure the dunst notification daemon.
    '';
  };

  config = lib.mkIf cfg.enable {
    services.dunst = {
      enable = true;

      iconTheme = {
        package = config.gtk.iconTheme.package;
        name = config.gtk.iconTheme.name;
        size = "48x48";
      };

      settings = {
        global = {
          dmenu = toString dmenu;
          geometry = "350x6-30+30";
          transparency = 10;
          padding = 10;
          horizontal_padding = 10;
          frame_width = 2;
          frame_color = colors.background-offset;
          font = fonts.primary.name;
          markup = "full";
          format = "<span size=\"large\"><b>%s</b></span>\\n\\n%b";
          word_wrap = true;
          icon_position = "right";
          idle_threshold = "3m";
          show_age_threshold = "1m";
        };

        urgency_low = {
          timeout = 5;
          foreground = colors.foreground;
          background = colors.background;
        };

        urgency_normal = {
          timeout = 8;
          foreground = colors.foreground;
          background = colors.background;
        };

        urgency_critical = {
          timeout = 16;
          frame_color = colors.fail;
          foreground = colors.foreground;
          background = colors.background;
        };
      };
    };
  };
}
