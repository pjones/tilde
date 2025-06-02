{ pkgs, config, lib, ... }:
let
  bashrc = pkgs.pjones.bashrc;
  zshrc = pkgs.pjones.zshrc;
  tmuxrc = pkgs.pjones.tmuxrc;
in
{
  config = lib.mkIf config.tilde.enable {
    home.shell.enableShellIntegration = true;

    programs.zsh = {
      enable = true;
      enableCompletion = true;

      syntaxHighlighting = {
        enable = true;
        highlighters = [ "main" "brackets" ];
      };

      initContent = ''
        source ${zshrc}/share/zshrc/zshrc
      '';

      envExtra = ''
        source ${zshrc}/share/zshrc/zshenv
      '';
    };

    programs.bash = {
      enable = true;
      bashrcExtra = ''
        source ${bashrc}/share/bashrc
      '';
    };

    home.file = {
      # Line editing:
      ".inputrc".source = "${bashrc}/share/inputrc";

      # tmux: (sort of like a shell :)
      ".tmux.conf".source = "${tmuxrc}/config/tmux.conf";
    };
  };
}
