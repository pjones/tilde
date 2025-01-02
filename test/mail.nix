{ pkgs, module }:
let
  user = import ./user.nix;

  mailCfgTest = pkgs.writeShellScript "mailcfg-test" ''
    set -eux
    set -o pipefail

    test -e ~/.config/tilde/mail.json

    domain=$(
      jq --raw-output \
        '."example.com" | .imapServer | .domain' \
      <~/.config/tilde/mail.json
    )

    test "$domain" = "localhost"
  '';

  msmtpTest = pkgs.writeShellScript "msmtp-test" ''
    set -eux
    set -o pipefail

    send_msg() {
      local from=$1
      msmtp --pretend --from "$from" < ~/test.mail
    }

    main() {
      test -e ~/.config/msmtp/config
      test -e ~/test.mail
      send_msg "buddy@example.com" | grep "account chosen by envelope"
      send_msg "busted@localhost" | grep "falling back to default account"
    }

    main "$@"
  '';

  mbsyncTest = pkgs.writeShellScript "mbsync-test" ''
    set -eux
    set -o pipefail

    mkdir --parents ~/mail
    mbsync --list-stores example.com-local
  '';

  imapnotifyTest = pkgs.writeShellScript "imapnotify-test" ''
    set -eux
    set -o pipefail

    test -e ~/.config/tilde/mail.json

    host=$(
      jq --raw-output \
        '.configurations[] | .host' \
      <~/.config/goimapnotify/goimapnotify.yaml
    )

    test "$host" = "localhost"
  '';

  muTest = pkgs.writeShellScript "mu-test" ''
    set -eux
    set -o pipefail

    test -d ~/.cache/mu
  '';

  testMail = ''
    From: example@example.com
    To: other@example.com
    Subject: An Email
    Date: Wed Jan  1 02:00:11 PM CET 2025

    Hey there!
  '';
in
pkgs.nixosTest {
  name = "tilde-mail-test";

  nodes = {
    machine = { ... }: {
      imports = [
        module
        ../devices/generic-nixos.nix
      ];

      users.users.${user.name} = {
        password = user.password;
      };

      environment.systemPackages = [ pkgs.jq ];

      tilde = {
        enable = true;
        username = user.name;
      };

      home-manager.users.${user.name} = { ... }: {
        tilde.mail = {
          enable = true;
          imapnotify.enable = true;
          mbsync.enable = true;
          msmtp.enable = true;
          mu.enable = true;

          accounts."example.com" = {
            default = true;

            imapServer = {
              hostname = "localhost";
              username = "example";
              passwordCmd = "echo password";
            };

            smtpServer = {
              hostname = "localhost";
              username = "example";
              passwordCmd = "echo password";
            };

            domains."example.com" = {
              default = true;
              users = [
                "example"
                "other"
              ];
            };
          };
        };

        home.file."test.mail".text = testMail;
      };
    };
  };

  testScript = ''
    with subtest("Start machines"):
        start_all()
        machine.wait_for_unit("multi-user.target")

    with subtest("Mail configuration"):
        machine.succeed("su - ${user.name} -c ${mailCfgTest}")

    with subtest("msmtp configuration"):
        machine.succeed("su - ${user.name} -c ${msmtpTest}")

    with subtest("mbsync configuration"):
        machine.succeed("su - ${user.name} -c ${mbsyncTest}")

    with subtest("imapnotify configuration"):
        machine.succeed("su - ${user.name} -c ${imapnotifyTest}")

    with subtest("mu configuration"):
        machine.succeed("su - ${user.name} -c ${muTest}")
  '';
}
