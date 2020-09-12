{ pkgs, config, lib, ... }:

{
  config = lib.mkIf config.tilde.enable {
    programs.direnv = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      enableNixDirenvIntegration = true;
    };
  };
}
