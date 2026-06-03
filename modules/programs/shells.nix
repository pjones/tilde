{ moduleWithSystem, ... }:
{
  flake.homeModules.shells = moduleWithSystem (
    { pkgs, ... }:
    { config, ... }:
    let
      bashrc = pkgs.pjones.bashrc;
      zshrc = pkgs.pjones.zshrc;
      tmuxrc = pkgs.pjones.tmuxrc;
    in
    {
      config = {
        home.shell.enableShellIntegration = true;

        programs.zsh = {
          enable = true;
          enableCompletion = true;

          # I'm old and this is where I'm keeping my zshrc for now:
          dotDir = config.home.homeDirectory;

          syntaxHighlighting = {
            enable = true;
            highlighters = [
              "main"
              "brackets"
            ];
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
  );
}
