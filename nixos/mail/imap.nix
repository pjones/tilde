{ config, lib, pkgs, ... }:

# This file configures a private IMAP server that acts as a mail hub.
# Other tools are used to fetch mail from various sources and place
# them into the IMAP mail directory.
#
# NOTE: This IMAP server is *not* configured to work with a SMTP
# server such as Postfix.  It is designed so that a local service
# running fetchmail can insert mail into the IMAP mail directory.

let
  cfg = config.tilde.mail.imap;
  lmtpUser = "lmtp";

  userDefaultFields = lib.concatStringsSep " " [
    "uid=${builtins.toString cfg.virtualUID}"
    "gid=${builtins.toString cfg.virtualUID}"
  ];
in
{
  options.tilde.mail.imap = {
    enable = lib.mkEnableOption "Run an IMAP server.";
    debug = lib.mkEnableOption "Debug the IMAP server.";

    domain = lib.mkOption {
      type = lib.types.str;
      description = "The domain name to use.";
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
      default = config.sops.secrets.mail-dovecot-passwd.path;
    };
  };

  config = lib.mkIf cfg.enable {
    # Tools that need to be in the system environment:
    environment.systemPackages = [
      pkgs.dovecot_pigeonhole
    ];

    # Allow system scripts to insert mail into the IMAP process.
    security.wrappers.dovecot-lda = {
      source = "${pkgs.dovecot}/libexec/dovecot/dovecot-lda";
      setuid = true;
      setgid = true;
      owner = cfg.virtualUser;
      group = cfg.virtualGroup;
    };

    # Run a web server so we can get a certificate:
    services.httpd = {
      enable = lib.mkDefault true;
      virtualHosts.${cfg.domain} = {
        forceSSL = true;
        enableACME = true;
      };
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
      } // lib.optionalAttrs (cfg.lmtpUser == lmtpUser) {
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
      } // lib.optionalAttrs (cfg.lmtpGroup == lmtpUser) {
        ${cfg.lmtpGroup} = {
          gid = cfg.lmtpUID;
        };
      };
    };

    # Use dovecot as the IMAP server:
    services.dovecot2 = {
      enable = true;
      enableImap = true;
      enableLmtp = true;

      enablePop3 = false;
      enablePAM = false;
      enableQuota = false;

      sslServerCert = "${config.security.acme.certs.${cfg.domain}.directory}/fullchain.pem";
      sslServerKey = "${config.security.acme.certs.${cfg.domain}.directory}/key.pem";

      mailUser = cfg.virtualUser;
      mailGroup = cfg.virtualGroup;

      mailLocation =
        let path = "${cfg.homeDir}/%d/%n";
        in lib.concatStringsSep ":" [
          "maildir:${path}"
          "INBOX=${path}/Inbox"
          "LAYOUT=fs"
          "UTF-8"
        ];

      modules = [ pkgs.dovecot_pigeonhole ];
      protocols = [ "sieve" ];

      mailboxes = {
        Trash = {
          auto = "subscribe";
          specialUse = "Trash";
          autoexpunge = "90d";
        };

        Spam = {
          auto = "subscribe";
          specialUse = "Junk";
          autoexpunge = "90d";
        };

        Drafts = {
          auto = "subscribe";
          specialUse = "Drafts";
        };

        Sent = {
          auto = "subscribe";
          specialUse = "Sent";
        };
      };

      extraConfig = ''
        ${lib.optionalString cfg.debug ''
          mail_debug = yes
          auth_debug = yes
          verbose_ssl = yes
        ''}

        namespace inbox {
          separator = /
          inbox = yes
        }

        passdb {
          driver = passwd-file
          args = ${cfg.passwordFile}
        }

        userdb {
          driver = passwd-file
          args = ${cfg.passwordFile}
          default_fields = ${userDefaultFields}
        }

        mail_access_groups = ${cfg.virtualGroup}
        auth_mechanisms = plain login
        ssl = required
        ssl_min_protocol = TLSv1.2
        ssl_prefer_server_ciphers = yes

        service imap-login {
          inet_listener imap {
            port = 0
          }
          inet_listener imaps {
            port = 993
            ssl = yes
          }
        }

        protocol imap {
          mail_plugins = $mail_plugins imap_sieve
        }

        service auth {
          unix_listener auth {
            user = ${cfg.lmtpUser}
            group = ${cfg.lmtpGroup}
            mode = 0600
          }
        }

        recipient_delimiter = +
        lda_mailbox_autosubscribe = yes
        lda_mailbox_autocreate = yes

        service lmtp {
          unix_listener dovecot-lmtp {
            user = ${cfg.lmtpUser}
            group = ${cfg.lmtpGroup}
            mode = 0600
          }
        }

        protocol lmtp {
          mail_plugins = $mail_plugins sieve
        }
      '';

      # TODO: Configure the sieve plugin
    };

    # Make sure dovecot is restarted when the TLS cert is changed:
    security.acme.certs."${cfg.domain}".reloadServices = [
      "dovecot2.service"
    ];
  };
}
