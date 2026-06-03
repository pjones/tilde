{ pkgs, self }:

pkgs.testers.runNixOSTest {
  name = "tilde-boot-ssh-test";

  nodes = {
    machine =
      { ... }:
      {
        imports = [
          self.nixosModules.test
        ];

        tilde.boot-ssh = {
          enable = true;
          ssh.hostKey = ./ssh_test_key;
          ssh.authorizedKeys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJkM0cL5hyyKv0KMrZHIH+iYEMFyA4yryuCtznQG5KBT"
          ];
        };
      };
  };

  testScript = ''
    start_all()
    machine.wait_for_unit("multi-user.target")
  '';
}
