{
  modulesPath,
  config,
  lib,
  pkgs,
  ...
}:

let
  authDb = pkgs.writeTextFile {
    name = "passwd";

    # Password for the following mailbox is password
    text = ''
      example@example.test:{CRYPT}$2y$05$mMtTRsn0KID2QpH51xXwmexKtOIPaHzVB896QQDQuG0vifP50Gx7a::::::
    '';
  };

  passwordFile = "/var/lib/dovecot/passwd.txt";
in
{
  imports = [
    (modulesPath + "/../tests/common/acme/client")
  ];

  config = lib.mkMerge [
    (lib.mkIf config.tilde.programs.imapd.enable {
      tilde.programs.imapd = {
        inherit passwordFile;
        debug = true;
        domain = "example.test";
      };

      # Put the fake password file in the right place:
      systemd.services.dovecot.preStart =
        let
          user = config.services.dovecot2.settings.default_internal_user;
          group = config.services.dovecot2.settings.default_internal_group;
        in
        ''
          mkdir --parents "$(dirname "${passwordFile}")"
          install --mode=0440 --owner=${user} --group=${group} ${authDb} ${passwordFile}
        '';
    })
  ];
}
