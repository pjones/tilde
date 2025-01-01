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

          accounts."example.com" = {
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

            domains."example.com".mailboxes = [
              "example"
              "other"
            ];
          };
        };
      };
    };
  };

  testScript = ''
    with subtest("Start machines"):
        start_all()
        machine.wait_for_unit("multi-user.target")

    with subtest("Mail configuration"):
        machine.succeed("su - ${user.name} -c ${mailCfgTest}")
  '';
}
