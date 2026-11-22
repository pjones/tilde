{ pkgs, self }:
let
  user = self.lib.test.user;

  testPackage = pkgs.writeShellApplication {
    name = "mail-test-script";
    text = builtins.readFile ./common.sh + builtins.readFile ./home.sh;
    runtimeInputs = with pkgs; [ coreutils ];
  };
in
pkgs.testers.nixosTest {
  name = "tilde-mail-home-test";

  nodes = {
    acme = { modulesPath, ... }: {
      imports = [
        (modulesPath + "/../tests/common/acme/server")
      ];
    };

    machine =
      { lib, ... }:
      {
        imports = [
          self.nixosModules.test
          self.nixosModules.imapd
          ./common.nix
        ];

        networking.hostName = "example";

        environment.systemPackages = [
          pkgs.jq
          testPackage
        ];

        tilde.programs.imapd.enable = true;

        home-manager.users.${user.name} =
          { ... }:
          {
            imports = [
              self.homeModules.mail
              self.homeModules.mbsync
              self.homeModules.msmtp
              self.homeModules.mu
            ];

            tilde = {
              programs.mbsync.enable = true;
              programs.msmtp.enable = true;
              programs.mu.enable = true;

              mail = {
                enable = true;
                debug = true;

                accounts."example.test" = {
                  default = true;

                  imapServer = {
                    hostname = "localhost";
                    username = "example@example.test";
                    passwordCmd = "echo password";
                    serverCertFile = "/var/lib/acme/example.test/cert.pem";
                  };

                  smtpServer = {
                    hostname = "localhost";
                    username = "example";
                    passwordCmd = "echo password";
                  };

                  domains."example.test" = {
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

        # Ensure tests can access the certificate:
        systemd.services."acme-order-renew-example.test".postStop = ''
          ${pkgs.acl}/bin/setfacl -R -m u:${user.name}:rX /var/lib/acme/example.test
        '';
      };
  };

  testScript = ''
    with subtest("Start machines"):
        start_all()
        machine.wait_for_unit("multi-user.target")
        acme.wait_for_open_port(443)
        machine.wait_for_unit("dovecot.service")

    with subtest("Log in"):
        machine.wait_until_tty_matches("1", "login: ")
        machine.send_chars("pjones\n")
        machine.wait_until_tty_matches("1", "Password: ")
        machine.send_chars("password\n")
        machine.wait_until_tty_matches("1", "\\n\\$\\s")

    with subtest("Mail configuration test"):
        machine.send_chars("mail-test-script\n")
        machine.wait_for_file("${user.home}/mail-test-success", 15)
  '';
}
