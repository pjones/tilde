{ pkgs, config, lib, ... }:
let
  bashrc = pkgs.pjones.bashrc;
  zshrc = pkgs.pjones.zshrc;
  tmuxrc = pkgs.pjones.tmuxrc;

  atuinCfg = pkgs.writers.writeTOML "atuin.toml" {
    enter_accept = true;
    filter_mode = "directory";
    inline_height = 7;
    keymap_cursor.emacs = "blink-bar";
    prefers_reduced_motion = true;
    show_help = false;
    show_tabs = false;
    style = "compact";
  };
in
{
  config = lib.mkIf config.tilde.enable {
    home.shell.enableShellIntegration = true;
    home.packages = [ pkgs.atuin ];

    programs.zsh = {
      enable = true;
      enableCompletion = true;

      syntaxHighlighting = {
        enable = true;
        highlighters = [ "main" "brackets" ];
      };

      initContent = ''
        source ${zshrc}/share/zshrc/zshrc
        eval "$(atuin init zsh --disable-up-arrow)"
      '';

      envExtra = ''
        source ${zshrc}/share/zshrc/zshenv
      '';
    };

    programs.bash = {
      enable = true;
      bashrcExtra = ''
        source ${bashrc}/share/bashrc
        eval "$(atuin init bash --disable-up-arrow)"
      '';
    };

    home.file = {
      # Line editing:
      ".inputrc".source = "${bashrc}/share/inputrc";

      # tmux: (sort of like a shell :)
      ".tmux.conf".source = "${tmuxrc}/config/tmux.conf";

    };

    # Atuin configuration:
    xdg.configFile."atuin/config.toml".source = "${atuinCfg}";
  };
}
