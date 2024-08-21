{ pkgs, config, lib, ... }:
let
  bashrc = pkgs.pjones.bashrc;
  zshrc = pkgs.pjones.zshrc;
  tmuxrc = pkgs.pjones.tmuxrc;

  atuinCfg = pkgs.writers.writeTOML "atuin.toml" {
    style = "compact";
    enter_accept = true;
    keymap_cursor.emacs = "blink-bar";
  };
in
{
  config = lib.mkIf config.tilde.enable {
    home.packages = [ pkgs.atuin ];

    programs.zsh = {
      enable = true;
      enableCompletion = true;

      syntaxHighlighting = {
        enable = true;
        highlighters = [ "main" "brackets" ];
      };

      initExtra = ''
        source ${zshrc}/share/zshrc/zshrc
        eval "$(atuin init zsh)"
      '';

      envExtra = ''
        source ${zshrc}/share/zshrc/zshenv
      '';
    };

    programs.bash = {
      enable = true;
      bashrcExtra = ''
        source ${bashrc}/share/bashrc
        eval "$(atuin init bash)"
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
