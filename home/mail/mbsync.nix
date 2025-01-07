{ config, lib, pkgs, ... }:

let
  mailCfg = config.tilde.mail;
  cfg = mailCfg.mbsync;

  # All directories needed by mbsync.
  maildirs = map (acct: "${mailCfg.directory}/${acct.name}")
    (builtins.attrValues mailCfg.accounts);

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
in
{
  options.tilde.mail.mbsync = {
    enable = lib.mkEnableOption "Configure mbsync";
  };

  config = lib.mkIf (mailCfg.enable && cfg.enable) {
    home.packages = [ pkgs.isync ];

    xdg.configFile."isyncrc".text =
      lib.concatMapStringsSep "\n"
        mkAccount
        (builtins.filter (a: a.mbsync)
          (builtins.attrValues mailCfg.accounts));

    home.activation.mbsyncDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run mkdir --parents --mode=0700 ${lib.escapeShellArg mailCfg.directory}
      run mkdir --parents --mode=0700 ${lib.escapeShellArgs maildirs}
    '';
  };
}
