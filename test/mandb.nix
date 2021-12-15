{ pkgs, module }:
let
  user = import ./user.nix;
in
pkgs.nixosTest {
  name = "tilde-mandb-test";

  nodes = {
    machine = { ... }: {
      imports = [
        module
        ../devices/generic-nixos.nix
      ];

      tilde.username = user.name;

      home-manager.users.${user.name} = { ... }: {
        tilde.programs.man.enable = true;
      };
    };
  };

  testScript = ''
    with subtest("Start machines"):
        start_all()

    with subtest("Check mandb cache"):
        machine.wait_for_unit("home-manager-${user.name}.service")
        machine.wait_until_fails("pgrep mandb")
        machine.succeed("test -d ${user.home}/.cache/man/etc-profiles-per-user-${user.name}")
  '';
}
