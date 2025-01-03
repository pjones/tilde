{ config, lib, pkgs, ... }:

let
  mailCfg = config.tilde.mail;
  cfg = mailCfg.imapnotify;

  accountConfig = acct:
    let
      server = acct.imapServer;

      service = lib.escapeShellArg "mbsync-${acct.name}";

      mbsync = pkgs.writeShellScript "imapnotify-mbsync" ''
        ${pkgs.systemd}/bin/systemctl --user start ${service}
      '';

      doCertCheck =
        if server.serverCertFile != null
        then false
        else true;
    in
    {
      host = server.hostname;
      port = if server.port == null then 993 else server.port;
      tls = true;
      tlsOptions.rejectUnauthorized = doCertCheck;
      tlsOptions.starttls = server.tls == "starttls";
      username = server.username;
      passwordCMD = server.passwordCmd;
      xoAuth2 = false;
      onDeletedMail = mbsync;
    } // lib.optionalAttrs cfg.mbsync {
      onNewMail = "${mbsync}";
    };

  imapnotifyConfig = builtins.toJSON {
    configurations =
      builtins.map accountConfig
        (builtins.attrValues mailCfg.accounts);
  };

in
{
  options.tilde.mail.imapnotify = {
    enable = lib.mkEnableOption "Configure goimapnotify";

    needGnuPG = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Whether or not a loaded GnuPG key is needed in order to access
        the IMAP server.  If this option is true and a key isn't
        loaded then the systemd user service will wait for the key to
        become available.
      '';
    };

    mbsync = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Run the mbsync command after syncing mail.";
    };

    mu = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Run the mu index command after syncing mail.";
    };
  };

  config = lib.mkIf (mailCfg.enable && cfg.enable) {
    home.packages = [ pkgs.goimapnotify ];

    xdg.configFile."goimapnotify/goimapnotify.yaml".text =
      imapnotifyConfig;

    systemd.user.services.imapnotify = {
      Unit = {
        Description = "Sync email when new messages arrive.";
        After = [ "network.target" ];
        PartOf = [ "network-online.target" ];
      };

      Service =
        let
          flags = lib.optional mailCfg.debug "-debug";
        in
        {
          ExecStart = "${pkgs.goimapnotify}/bin/goimapnotify ${lib.escapeShellArgs flags}";
          Restart = "on-failure";

          # Sandboxing.
          # LockPersonality = true;
          # MemoryDenyWriteExecute = true;
          # NoNewPrivileges = true;
          # PrivateUsers = true;
          # RestrictNamespaces = true;
          # SystemCallArchitectures = "native";
          # SystemCallFilter = "@system-service";
        } // lib.optionalAttrs (cfg.needGnuPG) {
          Environment = [ "GNUPGHOME=${config.programs.gpg.homedir}" ];
          ExecCondition = "${config.tilde.programs.gnupg.cardIsUnlockedScript}";
        };

      Install = { WantedBy = [ "default.target" ]; };
    };
  };
}
