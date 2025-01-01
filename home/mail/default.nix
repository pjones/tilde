{ config, lib, ... }:

let
  cfg = config.tilde.mail;
in
{
  options.tilde.mail = {
    enable = lib.mkEnableOption "Generate mail configuration files.";

    accounts = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule (import ./options.nix { inherit lib; })
      );
      default = { };
      description = "Set of mail accounts.";
    };
  };

  config = lib.mkIf cfg.enable {
    xdg.configFile."tilde/mail.json".text = builtins.toJSON cfg.accounts;
  };
}
