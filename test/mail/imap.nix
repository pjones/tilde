{ pkgs, self }:

let
  testPackage = pkgs.writeShellApplication {
    name = "imap-test-script";
    text = builtins.readFile ./common.sh + builtins.readFile ./imap.sh;
    runtimeInputs = with pkgs; [
      coreutils
      dovecot
    ];
  };

in

pkgs.testers.nixosTest {
  name = "imap-server-test";

  nodes = {
    machine =
      { ... }:
      {
        imports = [
          self.nixosModules.test
          self.nixosModules.imapd
          (import ./common.nix)
        ];

        environment.systemPackages = [ testPackage ];
        tilde.programs.imapd.enable = true;
      };
  };

  testScript = ''
    with subtest("Start machines"):
        start_all()
        machine.wait_for_unit("multi-user.target")

    with subtest("Run test script"):
        machine.succeed("${testPackage}/bin/imap-test-script")
  '';
}
