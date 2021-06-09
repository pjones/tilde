{ config
, pkgs
, lib
, ...
}:
let
  cfg = config.tilde.xsession.fonts;
in
{
  options.tilde.xsession.fonts = {
    enable = lib.mkEnableOption "Fonts and font managers";
  };

  config = lib.mkIf cfg.enable {
    fonts =
      let
        specs = import ../../home/misc/fonts.nix { inherit pkgs; };
        others = map (f: f.package) (lib.attrValues specs);
      in
      {
        fontconfig.enable = true;
        fontDir.enable = true;
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
