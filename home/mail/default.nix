{ config, lib, ... }:

let
  cfg = config.tilde.mail;
in
{
  imports = [
    ./mbsync.nix
    ./msmtp.nix
  ];

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
    assertions =
      let
        accounts = builtins.attrValues cfg.accounts;
        defaultAccounts = builtins.filter (a: a.default) accounts;

        defaultDomains = builtins.listToAttrs (map
          (acct: {
            name = acct.name;
            value = builtins.length
              (builtins.filter (d: d.default)
                (builtins.attrValues acct.domains));
          })
          accounts
        );
      in
      [
        {
          assertion = builtins.length defaultAccounts == 1;
          message = ''
            Exactly one mail account must be marked as the default account.
          '';
        }
        {
          assertion =
            builtins.all (num: num == 1)
              (builtins.attrValues defaultDomains);
          message = ''
            Each mail account should have exactly one default domain:
            ${builtins.toJSON defaultDomains}
          '';
        }
      ];

    xdg.configFile."tilde/mail.json".text = builtins.toJSON cfg.accounts;
  };
}
