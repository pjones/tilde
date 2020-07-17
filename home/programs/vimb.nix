{ config
, pkgs
, lib
, ...
}:
let
  cfg = config.tilde.programs.vimb;
in
{
  options.tilde.programs.vimb = {
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
