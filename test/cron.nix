{ sources ? import ../nix/sources.nix
, pkgs ? import sources.nixpkgs { }
}:
let
  user = import ./user.nix;
in
pkgs.nixosTest {
  name = "tilde-cron-test";

  nodes = {
    machine = { ... }: {
      imports = [ ../devices/generic-nixos.nix ];

      tilde = {
        username = user.name;

        crontab.test-job = {
          schedule = "minutely";
          script = "touch /tmp/crontab-test-job";
        };
      };
    };
  };

  testScript = ''
    with subtest("Start machines"):
        start_all()

    with subtest("Cron job emulation"):
        machine.require_unit_state("crontab-${user.name}-test-job.timer", "active")
        machine.start_job("crontab-${user.name}-test-job.service")
        machine.wait_for_file("/tmp/crontab-test-job")
        machine.succeed("test $(stat --format=%U /tmp/crontab-test-job) = ${user.name}")
  '';
}
