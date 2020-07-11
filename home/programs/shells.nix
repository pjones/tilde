{ pkgs, ... }:
let
  bashrc = pkgs.pjones.bashrc;
  zshrc = pkgs.pjones.zshrc;
  tmuxrc = pkgs.pjones.tmuxrc;

in
{
  config = {
    programs.zsh = {
      enable = true;
      enableCompletion = true;
    };

    home.file = {
      # Bash
      ".bashrc".source = "${bashrc}/share/bashrc";
      ".bash_profile".source = "${bashrc}/share/bash_profile";
      ".inputrc".source = "${bashrc}/share/inputrc";

      # ZSH:
      ".zshrc".source = "${zshrc}/share/zshrc/zshrc";
      ".zshenv".source = "${zshrc}/share/zshrc/zshenv";
      ".zsh".source = "${zshrc}/share/zshrc/zsh";

      # tmux: (sort of like a shell :)
      ".tmux.conf".source = "${tmuxrc}/config/tmux.conf";
    };
  };
}
