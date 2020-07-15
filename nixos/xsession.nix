{ config
, pkgs
, lib
, ...
}:
let
  cfg = config.pjones.xsession;
in
{
  options.pjones.xsession = {
    enable = lib.mkEnableOption ''
      Enable the X server and configure Peter's xsession.

      Implies that this machine is a workstation as well.
    '';
  };

  config = {
    # Enable workstation settings:
    pjones.workstation.enable = true;

    # For setting GTK themes:
    services.dbus.packages = [ pkgs.gnome3.dconf ];

    services.xserver = lib.mkIf cfg.enable {
      enable = lib.mkDefault true;
      layout = lib.mkDefault "us";

      displayManager.sddm.enable = lib.mkDefault true;
      desktopManager.plasma5.enable = lib.mkDefault true;

      # Add a custom desktop session:
      desktopManager.session = lib.singleton {
        name = "xmonad";
        enable = true;
        start = ''
          exec /home/pjones/.xsession
        '';
      };
    };

    # Fonts:
    fonts =
      let
        specs = import ../home/xsession/fonts.nix { inherit pkgs; };
        others = map (f: f.package) (lib.attrValues specs);
      in
      {
        fontconfig.enable = true;
        enableFontDir = true;
        enableGhostscriptFonts = true;

        fonts = with pkgs; [
          dejavu_fonts
          emacs-all-the-icons-fonts
          powerline-fonts
          ubuntu_font_family
        ] ++ others;
      };
  };
}
