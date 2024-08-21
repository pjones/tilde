{ config, lib, pkgs, ... }:

let
  cfg = config.tilde.programs.beets;
in
{
  options.tilde.programs.beets = {
    enable = lib.mkEnableOption "Beets";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      beets # Music tagger and library organizer
      mp3gain # Lossless mp3 normalizer with statistical analysis
    ];

    xdg.configFile = {
      "beets/config.yaml".source = "${pkgs.pjones.mediarc}/etc/beets.yaml";
    };
  };
}
