{ config, pkgs, lib, ... }:
let
  cfg = config.pjones.programs.mpd;
in
{
  options.pjones.programs.mpd = {
    enable = lib.mkEnableOption "Enable and configure MPD";
  };

  config = lib.mkIf cfg.enable {
    services.mpd = {
      enable = true;
      musicDirectory = "${config.home.homeDirectory}/documents/music";
      playlistDirectory = "${config.home.homeDirectory}/documents/playlists";
    };
  };
}
