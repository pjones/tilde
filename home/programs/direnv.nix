{ pkgs, config, lib, ... }:

{
  config = lib.mkIf config.tilde.workstation.enable {
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
    };
  };
}
