{ pkgs, module }:
let
  user = import ../user.nix;

  testPackage = pkgs.writeShellApplication {
    name = "mail-test-script";
    text = builtins.readFile ./common.sh + builtins.readFile ./home.sh;
    runtimeInputs = with pkgs; [
      coreutils
    ];
  };
in
pkgs.testers.nixosTest {
  name = "tilde-mail-test";

  nodes = {
    machine = { ... }: {
      imports = [
        module
        ../../devices/generic-nixos.nix
        ./common.nix
      ];

      users.users.${user.name} = {
        password = user.password;
      };

      environment.systemPackages = [
        pkgs.jq
        testPackage
      ];

      security.sudo.wheelNeedsPassword = false;

      tilde = {
        enable = true;
        username = user.name;
        putInWheel = true;
        mail.imap.enable = true;
      };

      home-manager.users.${user.name} = { ... }: {
        tilde.mail = {
          enable = true;
          debug = true;
          mbsync.enable = true;
          msmtp.enable = true;
          mu.enable = true;

          accounts."example.com" = {
            default = true;

            imapServer = {
              hostname = "localhost";
              username = "example@example.com";
              passwordCmd = "echo password";
              serverCertFile = "/var/lib/acme/example.com/cert.pem";
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
      };
    };
  };

  testScript = ''
    with subtest("Start machines"):
        start_all()
        machine.wait_for_unit("multi-user.target")
        machine.wait_for_unit("dovecot.service")

        # Ensure tests can access the certificate:
        machine.succeed("${pkgs.acl}/bin/setfacl -R -m u:${user.name}:rX /var/lib/acme/example.com")

    with subtest("Log in"):
        machine.wait_until_tty_matches("1", "login: ")
        machine.send_chars("pjones\n")
        machine.wait_until_tty_matches("1", "Password: ")
        machine.send_chars("password\n")
        machine.wait_until_tty_matches("1", "\\n\\$\\s")

    with subtest("Mail configuration test"):
        machine.send_chars("mail-test-script\n")
        machine.wait_for_file("${user.home}/mail-test-success", 60)
  '';
}
