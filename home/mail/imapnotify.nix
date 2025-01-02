{ config, lib, pkgs, ... }:

let
  mailCfg = config.tilde.mail;
  cfg = mailCfg.imapnotify;

  mbsyncScript = pkgs.writeShellScript "imapnotify-mbsync" ''
    PATH=$PATH:${pkgs.isync}/bin

    if [ $# -ne 1 ]; then
      echo >&2 "ERROR: missing account name"
      exit 1
    fi

    if [ ! -d "${mailCfg.directory}" ]; then
      mkdir --parents --mode=0700 "${mailCfg.directory}"
    fi

    if [ ! -d "${mailCfg.directory}/$1" ]; then
      mkdir --parents --mode=0700 "${mailCfg.directory}/$1"
      mbsync --pull "$1"
    else
      mbsync "$1"
    fi
  '';

  accountConfig = acct:
    let
      server = acct.imapServer;

      mbsync =
        if cfg.mbsync
        then "${mbsyncScript} ${acct.name}"
        else "";

      mu =
        if cfg.mu
        then "${pkgs.mu}/bin/mu index"
        else "";
    in
    {
      host = server.hostname;
      port = if server.port == null then 993 else server.port;
      tls = true;
      tlsOptions.rejectUnauthorized = true;
      tlsOptions.starttls = server.tls == "starttls";
      username = server.username;
      passwordCMD = server.passwordCmd;
      xoAuth2 = false;
      onNewMail = mbsync;
      onNewMailPost = mu;
      onDeletedMail = mbsync;
      onDeletedMailPost = mu;
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

      Service = {
        Environment = [ "GNUPGHOME=${config.programs.gpg.homedir}" ];
        ExecCondition = "${config.tilde.programs.gnupg.cardIsUnlockedScript}";
        ExecStart = "${pkgs.goimapnotify}/bin/goimapnotify";
        Restart = "on-failure";

        # Sandboxing.
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        NoNewPrivileges = true;
        PrivateUsers = true;
        RestrictNamespaces = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = "@system-service";
      };

      Install = { WantedBy = [ "default.target" ]; };
    };
  };
}
