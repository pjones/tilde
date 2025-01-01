{ lib, ... }:
let
  serverOptions = { config, ... }: {
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
        type = lib.types.enum [ "always" "starttls" ];
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
    };
  };

  domainOptions = { name, ... }: {
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

      mailboxes = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = ''
          Mailboxes used at this domain (user name portion of the email address).
        '';
      };
    };
  };

  accountOptions = { name, ... }: {
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
accountOptions
