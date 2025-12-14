{ config, lib, ... }:

let
  cfg = config.tilde.mail;
  options = import ./options.nix { inherit lib; };
in
{
  imports = [
    ./mbsync.nix
    ./msmtp.nix
    ./mu.nix
  ];

  options.tilde.mail = {
    enable = lib.mkEnableOption "Generate mail configuration files.";
    debug = lib.mkEnableOption "Enable debugging output.";

    accounts = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule options.accountOptions);
      default = { };
      description = "Set of mail accounts.";
    };

    directory = lib.mkOption {
      type = lib.types.path;
      default = "${config.home.homeDirectory}/mail";
      description = "Location to store mail locally.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions =
      let
        accounts = builtins.attrValues cfg.accounts;
        defaultAccounts = builtins.filter (a: a.default) accounts;

        defaultDomains = builtins.listToAttrs (
          map (acct: {
            name = acct.name;
            value = builtins.length (builtins.filter (d: d.default) (builtins.attrValues acct.domains));
          }) accounts
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
          assertion = builtins.all (num: num == 1) (builtins.attrValues defaultDomains);
          message = ''
            Each mail account should have exactly one default domain:
            ${builtins.toJSON defaultDomains}
          '';
        }
      ];

    xdg.configFile = {
      "tilde/email-addrs.json".text = builtins.toJSON (options.allEmailAddresses cfg.accounts);

      "tilde/mail.json".text = builtins.toJSON cfg.accounts;
    };
  };
}
