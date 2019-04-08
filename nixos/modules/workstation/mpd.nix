{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.pjones;

in
{
  config = mkIf cfg.isWorkstation {
    home-manager.users.pjones = { config, ... }: {
      services.mpd = {
        enable = true;
        musicDirectory = "${config.home.homeDirectory}/documents/music";
        playlistDirectory = "${config.home.homeDirectory}/documents/playlists";
      };

      services.mpdris2.enable = true;
    };
  };
}
