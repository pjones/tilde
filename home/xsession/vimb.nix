{ config
, pkgs
, lib
, ...
}:
let
  cfg = config.pjones.xsession.vimb;
in
{
  options.pjones.xsession.vimb = {
    enable = lib.mkEnableOption ''
      Install and configure the vimb web browser.
    '';
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      vimb
      pjones.vimbrc
    ];

    home.file.".config/vimb/config".source =
      "${pkgs.pjones.vimbrc}/etc/config";
    home.file.".config/vimb/style.css".source =
      "${pkgs.pjones.vimbrc}/etc/style.css";
  };
}
