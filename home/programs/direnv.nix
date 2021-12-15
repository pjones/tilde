{ pkgs, config, lib, ... }:

{
  config = lib.mkIf config.tilde.enable {
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
      nix-direnv.enableFlakes = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
    };
  };
}
