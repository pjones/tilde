{ moduleWithSystem, ... }:
{
  flake.nixosModules.fetchmail = moduleWithSystem (
    { pkgs, ... }:
    { config, lib, ... }:
    let
      cfg = config.tilde.programs.fetchmail;
      imapCfg = config.tilde.programs.imapd;
      lmtpUser = imapCfg.lmtpUser;

      fetchmailFlags = [
        "--softbounce"
        "--fetchall"
        "--nokeep"
        "--idle"
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

      mkFetchmailFlags =
        acct:
        fetchmailFlags
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
          "/var/lib/${lmtpUser}/fetchmail.${acct.name}.ids"
        ]
        ++ [
          "--pidfile"
          "/var/lib/${lmtpUser}/fetchmail.${acct.name}.pid"
        ]
        ++ [
          "--mda"
          "${ldaScript acct}"
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
          serviceConfig.User = imapCfg.lmtpUser;
          serviceConfig.Group = imapCfg.lmtpGroup;
          serviceConfig.WorkingDirectory = "/var/lib/${lmtpUser}";
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
      };
    }
  );
}
