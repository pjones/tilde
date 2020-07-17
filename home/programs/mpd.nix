{ config, pkgs, lib, ... }:
let
  cfg = config.tilde.programs.mpd;
in
{
  options.tilde.programs.mpd = {
    enable = lib.mkEnableOption "Enable and configure MPD";
  };

  config = lib.mkIf cfg.enable {
    services.mpd = {
      enable = true;
      musicDirectory = "${config.home.homeDirectory}/documents/music";
      playlistDirectory = "${config.home.homeDirectory}/documents/playlists";
    };

    # D-Bus broadcasting:
    services.mpdris2.enable = config.tilde.xsession.enable;
  };
}
