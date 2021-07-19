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
    package = pkgs.sweet-nova;
    name = "Sweet-Nova";
  };

  icons = {
    package = pkgs.pop-icon-theme;
    name = "Pop";
  };

  cursor = {
    package = pkgs.bibata-cursors;
    name = "Bibata-Original-Classic";
    size = 24;
  };

  icon-categories = [
    "actions"
    "animations"
    "apps"
    "categories"
    "devices"
    "emblems"
    "emotes"
    "filesystem"
    "intl"
    "mimetypes"
    "places"
    "status"
    "stock"
  ];

  icon-path = size: lib.concatMapStringsSep ":"
    (cat:
      let base = config.home.profileDirectory;
      in "${base}/share/icons/${icons.name}/${size}/${cat}")
    icon-categories;
in
{
  options.tilde.xsession.theme = {
    enable = lib.mkEnableOption "Set a GUI theme";
  };

  config = lib.mkIf config.tilde.xsession.theme.enable {
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

    # For Gnome settings:
    dconf.enable = true;

    # Qt:
    home.packages = [ pkgs.libsForQt5.qtstyleplugin-kvantum ];
    home.sessionVariables.QT_STYLE_OVERRIDE = "Kvantum";
    xsession.importedVariables = [ "QT_STYLE_OVERRIDE" ];

    xdg.configFile."Kvantum/kvantum.kvconfig".text = ''
      theme=Sweet-Nova
    '';

    xdg.configFile."Kvantum/Sweet-Nova".source =
      "${pkgs.sweet-nova}/share/kvantum/Sweet-Nova";

    # Push icons into other applications:
    services.dunst.settings.global.icon_path = lib.mkForce (icon-path "64x64");

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
