{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.pjones;

  configFile = pkgs.writeText "mbsync-cfg" ''
    IMAPAccount devalot
    Host mail.pmade.com
    User pjones
    PassCmd "${pkgs.pass}/bin/pass show machines/mail.pmade.com/pjones"
    SSLType IMAPS
    SSLVersions TLSv1.2
    CertificateFile /etc/ssl/certs/ca-certificates.crt

    IMAPStore devalot-remote
    Account devalot

    MaildirStore devalot-local
    Path ~/mail/devalot/
    Inbox ~/mail/devalot/Inbox
    SubFolders Verbatim

    Channel devalot
    Master :devalot-remote:
    Slave :devalot-local:
    Expunge both
    Create Both
    Remove Both
    SyncState *
    Patterns *

    IMAPAccount rfa
    Host outlook.office365.com
    User peter.jones@rfa.sc.gov
    PassCmd "${pkgs.pass}/bin/pass show business/clients/south-carolina/outlook.com"
    SSLType IMAPS
    SSLVersions TLSv1.2
    CertificateFile /etc/ssl/certs/ca-certificates.crt
    PipelineDepth 1

    IMAPStore rfa-remote
    Account rfa

    MaildirStore rfa-local
    Path ~/mail/rfa/
    Inbox ~/mail/rfa/Inbox
    SubFolders Verbatim

    Channel rfa
    Master :rfa-remote:
    Slave :rfa-local:
    Expunge both
    Create Both
    Remove Both
    SyncState *
    Patterns INBOX Archive "Deleted Items" Drafts "Sent Items"
  '';

  script = pkgs.writeShellScriptBin "mbsync-pjones" ''
    # Make sure some directories exist:
    mkdir -p ~/mail/devalot
    mkdir -p ~/mail/rfa

    # Do the mail sync:
    mbsync --all

    # Keep mu from indexing my SPAM folder:
    touch ~/mail/devalot/Junk/.noindex
  '';
in
{
  #### Implementation:
  config = mkIf cfg.isWorkstation {
    users.users.pjones.packages = with pkgs; [
      isync
      mu
    ] ++ [ script ];

    home-manager.users.pjones = { ... }: {
      home.file.".mbsyncrc".source = "${configFile}";

      # emacsclient -e '(mu4e-update-index)'
    };
  };
}
