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

    # ncmpcpp:
    programs.ncmpcpp = {
      enable = true;

      settings = {
        # Playlist
        song_list_format =
          " $0$8$8%l$0$8 $1|$7 $7%a$7 $1|$7 $6%t$1 $R $1%b$1";
        song_columns_list_format =
          "$L(9)[white]{l} (20)[red]{a} (30)[green]{b}$R(20)[cyan]{t}";
        song_library_format = "{%n > }{%t}|{%f}";
        now_playing_prefix = "$b";
        playlist_display_mode = "classic";

        # Bars
        song_status_format = "{%a - }{%t - }{%b}";
        progressbar_look = "─╼ ";
        titles_visibility = "no";
        header_visibility = "no";
        statusbar_visibility = "no";

        # Browser
        browser_playlist_prefix = "$2plist »$9 ";
        browser_display_mode = "classic";

        # Others
        song_window_title_format = "MPD: {%a > }{%t}{ [%b{ Disc %d}]}|{%f}";
        search_engine_display_mode = "columns";
        follow_now_playing_lyrics = "yes";
      };

      bindings = [
        { key = "j"; command = "scroll_down"; }
        { key = "k"; command = "scroll_up"; }
        { key = "l"; command = "previous_column"; }
        { key = "h"; command = "next_column"; }
        { key = "J"; command = [ "select_item" "scroll_down" ]; }
        { key = "K"; command = [ "select_item" "scroll_up" ]; }
        { key = "g"; command = "move_home"; }
        { key = "G"; command = "move_end"; }
        { key = "ctrl-f"; command = "page_down"; }
        { key = "ctrl-b"; command = "page_up"; }
        { key = "n"; command = "next_found_item"; }
        { key = "N"; command = "previous_found_item"; }
      ];
    };
  };
}
