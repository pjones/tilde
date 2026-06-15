{ moduleWithSystem, ... }:
{
  flake.nixosModules.fetchmail = moduleWithSystem (
    { pkgs, ... }:
    { config, lib, ... }:
    let
      cfg = config.tilde.programs.fetchmail;
      imapCfg = config.tilde.programs.imapd;

      fetchmailFlags = [
        "--softbounce"
        "--fetchall"
        "--nokeep"
        "--ssl"
        "--verbose"
      ]
      ++ [
        # Separated to emphasize that these must stay together:
        "--protocol"
        "imap"
      ];

      accountOptions =
        { name, ... }:
        {
          options = {
            name = lib.mkOption {
              type = lib.types.str;
              default = name;
              description = "Name for the systemd service and files.";
            };

            localUserName = lib.mkOption {
              type = lib.types.str;
              default = null;
              description = ''
                The local IMAP user name to use when handing mail over to
                Dovecot.
              '';
            };

            commandFile = lib.mkOption {
              type = lib.types.path;
              description = ''
                Path to a fetchmail run command file.  It should contain the
                following contents:

                poll SERVERNAME username NAME password PASSWORD

                Note: This file must be readable by the LMTP user
                account specified in the IMAP configuration.  It will
                be sent to the standard input of the fetchmail program
                to workaround its strict permission requirements.
              '';
            };

            moveTo = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = ''
                Don't delete messages, instead move them to a specific
                folder.  Settting this option passes the --moveto FOLDER
                command-line option to fetchmail.
              '';
            };

            lda = lib.mkOption {
              type = lib.types.nullOr lib.types.path;
              default = null;
              description = ''
                Path to a script that can deliver a mail message from
                standard input.  Leave as null to use the correct invocation
                of dovecot-lda.
              '';
            };

            useIDLE = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = ''
                Use IMAP IDLE instead of polling.

                Not all servers support this, even if they say they
                do.
              '';
            };

            pollInterval = lib.mkOption {
              type = lib.types.ints.positive;
              default = 300;
              description = ''
                Number of seconds to sleep in between polls.  Only
                used when IDLE has been disabled by the `useIDLE`
                option.
              '';
            };

            extraFetchmailFlags = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "Extra flags to pass to fetchmail.";
            };
          };
        };

      ldaScript =
        acct:
        if acct.lda != null then
          acct.lda
        else
          pkgs.writeShellScript "lda-${acct.name}" ''
            PATH=$PATH:/run/wrappers/bin
            exec dovecot-lda -e -d ${lib.escapeShellArg acct.localUserName}
          '';

      baseHome = "/var/lib/${imapCfg.lmtpUser}/fetchmail/";
      accountHome = acct: "${baseHome}/${acct.name}";

      mkFetchmailFlags =
        acct:
        fetchmailFlags
        ++ lib.optional acct.useIDLE "--idle"
        ++ lib.optionals (acct.moveTo != null) [
          "--moveto"
          acct.moveTo
        ]
        ++ [
          "--fetchmailrc"
          "-"
        ]
        ++ [
          "--idfile"
          "${accountHome acct}/ids"
        ]
        ++ [
          "--pidfile"
          "${accountHome acct}/pid"
        ]
        ++ [
          "--mda"
          "${ldaScript acct}"
        ]
        ++ lib.optionals (!acct.useIDLE) [
          "--daemon"
          (toString acct.pollInterval)
        ]
        ++ acct.extraFetchmailFlags;

      mkService = acct: {
        name = "fetchmail-${acct.name}";
        value = {
          enable = true;
          description = "Fetchmail from remote IMAP server.";
          wantedBy = [ "multi-user.target" ];
          wants = [
            "dovecot.service"
            "network-online.target"
          ];
          after = [
            "dovecot.service"
            "network-online.target"
          ];
          path = [ pkgs.fetchmail ];
          environment.FETCHMAILHOME = accountHome acct;
          serviceConfig.User = imapCfg.lmtpUser;
          serviceConfig.Group = imapCfg.lmtpGroup;
          serviceConfig.WorkingDirectory = accountHome acct;
          serviceConfig.Restart = "always";

          script = ''
            fetchmail \
              ${lib.escapeShellArgs (mkFetchmailFlags acct)} \
              <"${acct.commandFile}"
          '';
        };
      };
    in
    {
      options.tilde.programs.fetchmail = {
        enable = lib.mkEnableOption ''
          Fetch mail from other servers and insert them into the IMAP
          server running on the current server.

          Requires the IMAP server to be configured and enabled.
        '';

        accounts = lib.mkOption {
          type = lib.types.attrsOf (lib.types.submodule accountOptions);
          default = { };
          description = "Accounts to fetch mail for.";
        };
      };

      config = lib.mkIf (cfg.enable && imapCfg.enable) {
        systemd.services = builtins.listToAttrs (map mkService (builtins.attrValues cfg.accounts));

        systemd.tmpfiles.rules = [
          "d ${baseHome} 0750 ${imapCfg.lmtpUser} ${imapCfg.lmtpGroup} - -"
        ]
        ++ map (acct: "d ${accountHome acct} 0750 ${imapCfg.lmtpUser} ${imapCfg.lmtpGroup} - -") (
          builtins.attrValues cfg.accounts
        );
      };
    }
  );
}
