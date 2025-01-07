{ config, lib, pkgs, ... }:

let
  mailCfg = config.tilde.mail;
  cfg = mailCfg.mbsync;

  tlsOptions = {
    always = "IMAPS";
    starttls = "STARTTLS";
  };

  toConfigLine = { name, value }:
    let
      hasSpace = v: builtins.match ".* .*" v != null;
      escapeValue = lib.escape [ ''"'' ];
      encode = v:
        if builtins.isString v && hasSpace v
        then ''"${escapeValue v}"''
        else if builtins.isString v
        then v
        else builtins.toString v;
    in
    "${name} ${encode value}";

  toConfig = attrs:
    lib.concatMapStringsSep "\n"
      toConfigLine
      (lib.attrsToList attrs);

  mkAccount = acct:
    let
      server = acct.imapServer;
      tls = tlsOptions.${server.tls};

      imapAccount = {
        Host = server.hostname;
        Port = if server.port == null then 993 else server.port;
        User = server.username;
        PassCmd = server.passwordCmd;
        TLSType = tls;
      } // lib.optionalAttrs (server.serverCertFile != null) {
        CertificateFile = server.serverCertFile;
      };

      imapStore = {
        Account = acct.name;
      };

      mailStore = {
        Path = "${mailCfg.directory}/${acct.name}/";
        Inbox = "${mailCfg.directory}/${acct.name}/Inbox/";
        SubFolders = "Verbatim";
      };

      channel = {
        Far = ":${acct.name}-remote:";
        Near = ":${acct.name}-local:";
        Pattern = "*";
        Create = "Both";
        Remove = "Both";
        Expunge = "Both";
        SyncState = "*";
      };
    in
    ''
      ${toConfig {IMAPAccount = acct.name;}}
      ${toConfig imapAccount}

      ${toConfig {IMAPStore = "${acct.name}-remote";}}
      ${toConfig imapStore}

      ${toConfig {MaildirStore = "${acct.name}-local";}}
      ${toConfig mailStore}

      ${toConfig {Channel = acct.name;}}
      ${toConfig channel}
    '';

  mbsyncScript = pkgs.writeShellApplication {
    name = "run-mbsync";

    runtimeInputs = [
      pkgs.coreutils
      pkgs.isync
      pkgs.mu
      pkgs.procps
    ];

    text = ''
      flags=()
      maildir="${mailCfg.directory}"

      ${lib.optionalString mailCfg.debug ''
        set -x
        flags+=("--verbose")
      ''}

      if [ $# -ne 1 ]; then
        echo >&2 "ERROR: missing account name"
        exit 1
      fi

      if [ ! -d "$maildir" ]; then
        # shellcheck disable=SC2174
        mkdir --parents --mode=0700 "$maildir"
      fi

      if [ ! -d "$maildir/$1" ]; then
        echo >&2 "Running mbsync for the first time..."
        # shellcheck disable=SC2174
        mkdir --parents --mode=0700 "$maildir/$1"
        mbsync --pull "''${flags[@]}" "$1"
      else
        echo >&2 "Syncing existing store..."
        mbsync "''${flags[@]}" "$1"
      fi

      if ! pgrep -u "$USER" mu; then
        mu index
      fi
    '';
  };

  mbsyncService = acct: {
    name = "mbsync-${acct.name}";
    value = {
      Unit = {
        Description = "Sync email for ${acct.name}.";
        After = [ "network.target" ];
        PartOf = [ "network-online.target" ];
        OnSuccess = [ "maildir-${acct.name}.service" ];
      };

      Service = {
        Type = "oneshot";
        ExecStart = "${mbsyncScript}/bin/run-mbsync ${lib.escapeShellArg acct.name}";
        Restart = "on-failure";
        RestartSec = 30;
        RestartMaxDelaySec = 900;
        RestartSteps = 10;

        # Sandboxing.
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        NoNewPrivileges = true;
        PrivateUsers = true;
        RestrictNamespaces = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = "@system-service";
      } // lib.optionalAttrs (cfg.needGnuPG) {
        Environment = [ "GNUPGHOME=${config.programs.gpg.homedir}" ];
        ExecCondition = "${config.tilde.programs.gnupg.cardIsUnlockedScript}";
      };
    };
  };

  watchService = acct:
    let
      script = pkgs.writeShellApplication {
        name = "watch-maildir-${acct.name}";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.inotify-tools
          pkgs.systemd
        ];
        text = ''
          while :; do
            inotifywait \
              --no-dereference \
              --recursive \
              --event modify \
              --event move \
              --event create \
              --event delete \
              ${lib.escapeShellArg "${mailCfg.directory}/${acct.name}"}
            ${pkgs.systemd}/bin/systemctl --user start mbsync-${acct.name}.service
          done
        '';
      };
    in
    {
      name = "maildir-${acct.name}";
      value = {
        Unit = {
          Description = "Sync mail with maildir ${acct.name} changes.";
          After = [ "network.target" ];
          PartOf = [ "network-online.target" ];
          Conflicts = [ "mbsync-${acct.name}.service" ];
          ConditionPathIsDirectory = "|${mailCfg.directory}/${acct.name}";
        };

        Service = {
          ExecStart = "${script}/bin/watch-maildir-${acct.name}";
          Restart = "on-failure";
          RestartSec = 30;
          RestartMaxDelaySec = 900;
          RestartSteps = 10;
        };

        Install.WantedBy = [ "default.target" ];
      };
    };
in
{
  options.tilde.mail.mbsync = {
    enable = lib.mkEnableOption "Configure mbsync";

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
  };

  config = lib.mkIf (mailCfg.enable && cfg.enable) {
    home.packages = [ pkgs.isync ];

    xdg.configFile."isyncrc".text =
      lib.concatMapStringsSep "\n"
        mkAccount
        (builtins.filter (a: a.mbsync)
          (builtins.attrValues mailCfg.accounts));

    systemd.user.services =
      let accts = lib.attrValues mailCfg.accounts;
      in lib.listToAttrs (
        (map mbsyncService accts)
        ++ (map watchService accts)
      );
  };
}
