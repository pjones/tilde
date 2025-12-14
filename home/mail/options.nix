{ lib, ... }:
let
  serverOptions =
    { config, ... }:
    {
      options = {
        hostname = lib.mkOption {
          type = lib.types.str;
          default = null;
          description = "Hostname for the server.";
        };

        domain = lib.mkOption {
          type = lib.types.str;
          default = config.hostname;
          description = ''
            Domain name for things like cert checking or EHLO messages
            if different than the hostname.
          '';
        };

        port = lib.mkOption {
          type = lib.types.nullOr (lib.types.ints.positive);
          default = null;
          description = ''
            The port number to use.  Use null to use the default port.
          '';
        };

        tls = lib.mkOption {
          type = lib.types.enum [
            "always"
            "starttls"
          ];
          default = "always";
          description = "How to use TLS.";
        };

        username = lib.mkOption {
          type = lib.types.str;
          default = null;
          description = "User name for the server.";
        };

        passwordCmd = lib.mkOption {
          type = lib.types.str;
          default = null;
          description = "Command used to get the password for this server.";
        };

        serverCertFile = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = "Verify server certificate matches the given file.";
        };
      };
    };

  domainOptions =
    { name, ... }:
    {
      options = {
        name = lib.mkOption {
          type = lib.types.str;
          default = name;
        };

        default = lib.mkEnableOption ''
          Exactly one domain should be marked as the default domain.
          The first mailbox given will be used with the domain to
          generate the default email address.
        '';

        users = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = ''
            Mailboxes used at this domain (local part portion of the
            email address).
          '';
        };
      };
    };

  accountOptions =
    { name, ... }:
    {
      options = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
        };

        name = lib.mkOption {
          type = lib.types.str;
          default = name;
        };

        default = lib.mkEnableOption ''
          Mark this account as the default account.  Exactly one account
          must be the default.
        '';

        msmtp = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Include this account in the msmtp configuration.";
        };

        mbsync = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Include this account in the mbsync configuration.";
        };

        imapServer = lib.mkOption {
          type = lib.types.submodule serverOptions;
          default = null;
          description = "IMAP server configuration.";
        };

        smtpServer = lib.mkOption {
          type = lib.types.submodule serverOptions;
          default = null;
          description = "SMTP server configuration.";
        };

        domains = lib.mkOption {
          type = lib.types.attrsOf (lib.types.submodule domainOptions);
          default = { };
          description = ''
            Domains and available mailboxes.
          '';
        };
      };
    };
in
rec {
  inherit accountOptions;

  # Return a list containing a single account, the default account.
  defaultAccount = accounts: builtins.filter (acct: acct.default) (builtins.attrValues accounts);

  # Return a list of accounts that are not the default account.
  otherAccounts = accounts: builtins.filter (acct: !acct.default) (builtins.attrValues accounts);

  # Return a list containing a single domain, the default domain.
  defaultDomain = acct: builtins.filter (d: d.default) (builtins.attrValues acct.domains);

  # Return a list of domains that are not the default domain.
  otherDomains = acct: builtins.filter (d: !d.default) (builtins.attrValues acct.domains);

  # Return a list of all email addresses.  The default email address
  # will be listed first.
  allEmailAddresses =
    accounts:
    builtins.concatMap (
      acct:
      builtins.concatMap (domain: builtins.map (user: "${user}@${domain.name}") domain.users) (
        defaultDomain acct ++ otherDomains acct
      )
    ) (defaultAccount accounts ++ otherAccounts accounts);
}
