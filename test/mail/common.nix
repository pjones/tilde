{ config, lib, pkgs, ... }:

let
  authDb = pkgs.writeTextFile {
    name = "passwd";

    # Password for the following mailbox is password
    text = ''
      example@example.com:{CRYPT}$2y$05$mMtTRsn0KID2QpH51xXwmexKtOIPaHzVB896QQDQuG0vifP50Gx7a::::::
    '';
  };

  passwordFile = "/var/lib/dovecot/passwd.txt";
in
{
  config = lib.mkMerge [
    (lib.mkIf config.tilde.mail.imap.enable {
      security.acme = {
        acceptTerms = true;
        defaults.email = "example@example.com";
      };

      tilde.mail.imap = {
        inherit passwordFile;
        debug = true;
        domain = "example.com";
      };

      # Put the fake password file in the right place:
      systemd.services.dovecot2.preStart = ''
        mkdir --parents "$(dirname "${passwordFile}")"
        install --mode=0440 --owner=vmail --group=vmail ${authDb} ${passwordFile}
      '';
    })
  ];
}
