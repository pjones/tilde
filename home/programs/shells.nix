{ pkgs, config, lib, ... }:
let
  bashrc = pkgs.pjones.bashrc;
  zshrc = pkgs.pjones.zshrc;
  tmuxrc = pkgs.pjones.tmuxrc;

in
{
  config = lib.mkIf config.tilde.enable {
    programs.zsh = {
      enable = true;
      enableCompletion = true;

      initExtra = ''
        source ${zshrc}/share/zshrc/zshrc
      '';

      envExtra = ''
        source ${zshrc}/share/zshrc/zshenv
      '';
    };

    home.file = {
      # Bash
      ".bashrc".source = "${bashrc}/share/bashrc";
      ".bash_profile".source = "${bashrc}/share/bash_profile";
      ".inputrc".source = "${bashrc}/share/inputrc";

      # tmux: (sort of like a shell :)
      ".tmux.conf".source = "${tmuxrc}/config/tmux.conf";
    };
  };
}
