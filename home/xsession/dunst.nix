{ config
, pkgs
, lib
, ...
}:
let
  cfg = config.pjones.xsession.dunst;

  fonts = import ./fonts.nix { inherit pkgs; };
  colors = import ./colors.nix;
in
{
  options.pjones.xsession.dunst = {
    enable = lib.mkEnableOption ''
      Install and configure the dunst notification daemon.
    '';
  };

  config = lib.mkIf cfg.enable {
    services.dunst = {
      enable = true;
      settings = {
        global = {
          geometry = "300x5-30+30";
          transparency = 10;
          padding = 5;
          horizontal_padding = 5;
          frame_width = 2;
          frame_color = colors.active;
          font = fonts.primary.name;
          markup = "full";
          format = "<b>%s</b>\\n%b";
          word_wrap = true;
          icon_position = "right";
          corner_radius = 5;
          idle_threshold = "3m";
          show_age_threshold = "1m";
        };

        urgency_low = {
          timeout = 5;
          foreground = colors.foreground;
          background = colors.background;
        };

        urgency_normal = {
          timeout = 5;
          foreground = colors.foreground;
          background = colors.background;
        };

        urgency_critical = {
          timeout = 15;
          frame_color = colors.fail;
          foreground = colors.foreground;
          background = colors.background;
        };
      };
    };
  };
}
