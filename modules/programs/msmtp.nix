{ moduleWithSystem, ... }:
{
  flake.homeModules.msmtp = moduleWithSystem (
    { pkgs, ... }:
    { config, lib, ... }:

    let
      mailCfg = config.tilde.mail;
      cfg = config.tilde.programs.msmtp;

      smtpPort = acct: if acct.smtpServer.port != null then acct.smtpServer.port else 465;

      startTLS = acct: if acct.smtpServer.tls == "starttls" || smtpPort acct == 587 then "on" else "off";

      # A simple way to name accounts:
      accountName = acct: builtins.hashString "md5" acct.name;

      mkAccount =
        acct:
        let
          name = accountName acct;
        in
        ''
          account ${name}
          host ${acct.smtpServer.hostname}
          domain ${acct.smtpServer.domain}
          port ${builtins.toString (smtpPort acct)}
          auth on
          user ${acct.smtpServer.username}
          passwordeval ${acct.smtpServer.passwordCmd}
          tls on
          tls_starttls ${startTLS acct}
        ''
        + lib.concatMapStringsSep "\n" (domain: ''
          account ${domain.name} : ${name}
          from *@${domain.name}
        '') (builtins.attrValues acct.domains);

      mkConfig =
        accounts:
        let
          default = builtins.head (builtins.filter (a: a.default) accounts);
        in
        ''
          ${lib.concatMapStringsSep "\n" mkAccount (builtins.filter (a: a.msmtp) accounts)}
          account default : ${accountName default}
        '';
    in
    {
      options.tilde.programs.msmtp = {
        enable = lib.mkEnableOption "Generate msmtp configuration file.";
      };

      config = lib.mkIf (mailCfg.enable && cfg.enable) {
        assertions = [
          {
            assertion =
              let
                defaults = builtins.filter (a: a.default) (builtins.attrValues mailCfg.accounts);
              in
              builtins.length defaults == 1 && (builtins.head defaults).msmtp;
            message = ''
              The default mail account must have msmtp enabled if you also
              enable msmtp configuration generation.
            '';
          }
        ];

        home.packages = [ pkgs.msmtp ];

        xdg.configFile."msmtp/config".text = mkConfig (builtins.attrValues mailCfg.accounts);

        home.sessionVariables = {
          # FIXME: Are these used?  They aren't documented in the manual.
          MSMTP_QUEUE = "${config.xdg.dataHome}/msmtp/queue";
          MSMTP_LOG = "${config.xdg.dataHome}/msmtp/queue.log";
        };
      };
    }
  );
}
