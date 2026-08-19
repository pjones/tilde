{ moduleWithSystem, ... }:
{
  flake.nixosModules.imapd = moduleWithSystem (
    { pkgs, ... }:
    { config, lib, ... }:

    # This file configures a private IMAP server that acts as a mail hub.
    # Other tools are used to fetch mail from various sources and place
    # them into the IMAP mail directory.
    #
    # NOTE: This IMAP server is *not* configured to work with a SMTP
    # server such as Postfix.  It is designed so that a local service
    # running fetchmail can insert mail into the IMAP mail directory.

    let
      cfg = config.tilde.programs.imapd;
      lmtpUser = "lmtp";

      sslCertDomain = if cfg.useACMEHost != null then cfg.useACMEHost else cfg.domain;
      sslCertDir = config.security.acme.certs.${sslCertDomain}.directory;
    in
    {
      options.tilde.programs.imapd = {
        enable = lib.mkEnableOption "Run an IMAP server.";
        debug = lib.mkEnableOption "Debug the IMAP server.";

        domain = lib.mkOption {
          type = lib.types.str;
          description = "The domain name to use.";
        };

        enableACME = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''
            Whether to ask Let's Encrypt to sign a certificate for this
            server.  Alternately, you can use an existing certificate
            through {option}`useACMEHost`.
          '';
        };

        useACMEHost = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = ''
            A host of an existing Let's Encrypt certificate to use.
          '';
        };

        homeDir = lib.mkOption {
          type = lib.types.path;
          default = "/var/lib/vmail";
          description = "Directory where mail is stored.";
        };

        virtualUser = lib.mkOption {
          type = lib.types.str;
          default = "vmail";
        };

        virtualGroup = lib.mkOption {
          type = lib.types.str;
          default = "vmail";
        };

        virtualUID = lib.mkOption {
          type = lib.types.int;
          default = 5000;
        };

        lmtpUser = lib.mkOption {
          type = lib.types.str;
          default = lmtpUser;
          description = "The user that is allowed to use dovecot-lda";
        };

        lmtpGroup = lib.mkOption {
          type = lib.types.str;
          default = lmtpUser;
          description = "The group that is allowed to use dovecot-lda";
        };

        lmtpUID = lib.mkOption {
          type = lib.types.int;
          default = 5001;
        };

        passwordFile = lib.mkOption {
          type = lib.types.path;
        };
      };

      config = lib.mkIf cfg.enable {
        # Tools that need to be in the system environment:
        environment.systemPackages = [ pkgs.dovecot_pigeonhole ];

        # Allow system scripts to insert mail into the IMAP process.
        security.wrappers.dovecot-lda = {
          source = "${config.services.dovecot2.package}/libexec/dovecot/dovecot-lda";
          setuid = true;
          setgid = true;
          owner = cfg.virtualUser;
          group = cfg.virtualGroup;
        };

        # Create system-level accounts for virtual mail:
        users = {
          users = {
            ${cfg.virtualUser} = {
              isSystemUser = true;
              uid = cfg.virtualUID;
              home = cfg.homeDir;
              createHome = true;
              group = cfg.virtualGroup;
            };
          }
          // lib.optionalAttrs (cfg.lmtpUser == lmtpUser) {
            ${cfg.lmtpUser} = {
              isSystemUser = true;
              uid = cfg.lmtpUID;
              home = "/var/lib/${cfg.lmtpUser}";
              createHome = true;
              group = cfg.lmtpUser;
            };
          };

          groups = {
            ${cfg.virtualGroup} = {
              gid = cfg.virtualUID;
            };
          }
          // lib.optionalAttrs (cfg.lmtpGroup == lmtpUser) {
            ${cfg.lmtpGroup} = {
              gid = cfg.lmtpUID;
            };
          };
        };

        # Use dovecot as the IMAP server:
        services.dovecot2 = {
          enable = true;
          package = pkgs.dovecot;
          createMailUser = false;

          settings = {
            dovecot_config_version = "2.4.4";
            dovecot_storage_version = "2.4.4";

            mail_debug = cfg.debug;
            auth_debug = cfg.debug;
            #verbose_ssl = cfg.debug;

            protocols = {
              imap = true;
              lmtp = true;
              sieve = true;
            };

            mail_uid = cfg.virtualUser;
            mail_gid = cfg.virtualGroup;
            mail_access_groups = cfg.virtualGroup;

            mail_driver = "maildir";
            mailbox_list_layout = "fs";
            mail_inbox_path = "${cfg.homeDir}/%{user | domain}/%{user | username}/Inbox";
            mail_path = "${cfg.homeDir}/%{user | domain}/%{user | username}";
            mailbox_list_utf8 = true;
            maildir_copy_with_hardlinks = true;

            "namespace inbox" = {
              inbox = "yes";
              separator = "/";

              "mailbox Trash" = {
                auto = "subscribe";
                special_use = "\\Trash";
                autoexpunge = "90d";
              };

              "mailbox Spam" = {
                auto = "subscribe";
                special_use = "\\Junk";
                autoexpunge = "90d";
              };

              "mailbox Drafts" = {
                auto = "subscribe";
                special_use = "\\Drafts";
              };

              "mailbox Sent" = {
                auto = "subscribe";
                special_use = "\\Sent";
              };
            };

            "passdb passwd-file" = {
              driver = "passwd-file";
              passwd_file_path = cfg.passwordFile;
            };

            "userdb passwd-file" = {
              driver = "passwd-file";
              passwd_file_path = cfg.passwordFile;

              fields = {
                uid = toString cfg.virtualUID;
                gid = toString cfg.virtualUID;
                home = "${cfg.homeDir}/%{user | domain}/%{user | username}";
              };
            };

            auth_mechanisms = [
              "plain"
              "login"
            ];

            ssl = "required";
            ssl_min_protocol = "TLSv1.2";

            ssl_server = {
              cert_file = "${sslCertDir}/fullchain.pem";
              key_file = "${sslCertDir}/key.pem";
            };

            "service imap-login" = {
              "inet_listener imap" = {
                port = 0;
              };

              "inet_listener imaps" = {
                port = 993;
                ssl = "yes";
              };
            };

            "protocol imap" = {
              mail_plugins = {
                imap_sieve = true;
              };
            };

            "service auth" = {
              "unix_listener auth" = {
                user = cfg.lmtpUser;
                group = cfg.lmtpGroup;
                mode = "0600";
              };
            };

            recipient_delimiter = "+";
            lda_mailbox_autosubscribe = "yes";
            lda_mailbox_autocreate = "yes";

            "service lmtp" = {
              "unix_listener dovecot-lmtp" = {
                user = cfg.lmtpUser;
                group = cfg.lmtpGroup;
                mode = "0600";
              };
            };

            "protocol lmtp" = {
              mail_plugins = {
                imap_sieve = true;
              };
            };
          };

          # TODO: Configure the sieve plugin
        };

        # Request a certificate or add our domain to an existing certificate:
        #
        # NOTE: dovecot runs as root so we don't need to worry about
        # certificate permissions here.
        security.acme.certs =
          let
            allCerts = {
              reloadServices = [ "dovecot.service" ];
            };
            ownCert = allCerts // {
              group = lib.mkDefault config.services.dovecot2.settings.default_internal_group;
              webroot = lib.mkDefault "/var/lib/acme/acme-challenge";
            };
            otherCert = allCerts // {
              extraDomainNames = [ cfg.domain ];
            };
          in
          if cfg.useACMEHost != null then
            { ${sslCertDomain} = otherCert; }
          else if cfg.enableACME then
            { ${sslCertDomain} = ownCert; }
          else
            { };
      };
    }
  );
}
