# Themes, fonts, cursors, etc.
{ config
, lib
, pkgs
, ...
}:
let
  fonts = import ../misc/fonts.nix { inherit pkgs; };
  colors = import ../misc/colors.nix;

  theme = {
    package = pkgs.sweet;
    name = "Sweet-Dark";
  };

  icons = {
    package = pkgs.pantheon.elementary-icon-theme;
    name = "elementary";
  };

  cursor = {
    package = pkgs.oreo-cursors;
    name = "oreo_pink_cursors";
  };

in
{
  options.pjones.xsession.theme = {
    enable = lib.mkEnableOption "Set a GUI theme";
  };

  config = lib.mkIf config.pjones.xsession.theme.enable {
    gtk = {
      inherit theme;
      enable = true;
      iconTheme = icons;
      font = { inherit (fonts.primary) package name; };

      gtk2.extraConfig = ''
        gtk-key-theme-name="Emacs"
      '';

      gtk3.extraConfig = {
        gtk-key-theme-name = "Emacs";
      };
    };

    qt = {
      enable = true;
      platformTheme = "gtk";
    };

    # For Gnome settings:
    dconf.enable = true;

    # Push icons into other applications:
    services.dunst.iconTheme = icons;

    # X-Resources:
    xresources.properties = {
      "*background" = colors.black;
      "*foreground" = colors.white;
      "*color0" = colors.black;
      # "*color8" = ??;
      "*color1" = colors.red;
      # "*color9" = ??;
      "*color2" = colors.green;
      # "*color10" = ??;
      "*color3" = colors.yellow;
      # "*color11" = ??;
      "*color4" = colors.blue;
      # "*color12" = ??;
      "*color5" = colors.purple;
      "*color13" = colors.darkpurple;
      "*color6" = colors.cyan;
      # "*color14" = ??;
      "*color7" = colors.white;
      "*color15" = colors.gray;
    };

    # XCursor:
    xsession.pointerCursor = cursor;
  };
}
