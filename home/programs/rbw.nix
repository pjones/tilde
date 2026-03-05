{ config, lib, ... }:

let
  cfg = config.tilde.programs.rbw;
in
{
  options.tilde.programs.rbw = {
    enable = lib.mkEnableOption "Enable RBW";
  };

  config = lib.mkIf cfg.enable {
    programs.rbw = {
      enable = true;

      settings = {
        email = config.programs.git.settings.user.email;
        pinentry = config.services.gpg-agent.pinentry.package;
        lock_timeout = config.services.gpg-agent.defaultCacheTtl;
      };
    };
  };
}
