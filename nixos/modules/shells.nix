{ config, pkgs, lib, ... }:

with lib;

let
  base = import ../../pkgs { inherit pkgs; };

  bashrc = base.bashrc;
  zshrc  = base.zshrc;
  tmuxrc = base.tmuxrc;

in
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;
  };

  home-manager.users.pjones.home.file = {

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
}
