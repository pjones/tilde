# This is a nix-on-droid module:
# https://github.com/t184256/nix-on-droid/
{ pkgs, ... }:

{
  system.stateVersion = "20.03";
  environment.etcBackupExtension = ".backup";
  user.shell = "${pkgs.zsh}/bin/zsh";
  time.timeZone = "America/Phoenix";

  home-manager.config = { pkgs, ... }: {
    imports = [
      ../home
      ./generic-linux.nix
    ];

    home.packages = with pkgs; [
      okc-agents
    ];

    programs.zsh.initExtra = ''
      start_okc_agent() {
        # https://github.com/DDoSolitary/OkcAgent
        if type -p okc-ssh-agent > /dev/null; then
          export SSH_AUTH_SOCK=$HOME/.okc-ssh-agent
          ${pkgs.procps}/bin/pkill okc-ssh-agent || :
          okc-ssh-agent "$SSH_AUTH_SOCK" &
        fi
      }
      start_okc_agent > /dev/null 2>&1
    '';
  };
}
