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

    with subtest("Cron jobs should run as the tilde user"):
        machine.require_unit_state("crontab-${user.name}-test-job.timer", "active")
        machine.start_job("crontab-${user.name}-test-job.service")
        machine.wait_for_file("/tmp/crontab-test-job")
        machine.succeed("test $(stat --format=%U /tmp/crontab-test-job) = ${user.name}")

    with subtest("All NixOS machines should get a download dir clean job"):
        machine.succeed("mkdir -p ${user.home}/download")
        machine.succeed("touch --date '3 weeks ago' ${user.home}/download/should-be-removed")
        machine.succeed("touch --date '1 week ago' ${user.home}/download/should-be-kept")
        machine.succeed("chown -R ${user.name}:root ${user.home}/download")
        machine.require_unit_state("crontab-${user.name}-clean-download-directory.timer", "active")
        machine.start_job("crontab-${user.name}-clean-download-directory.service")
        machine.wait_for_job("crontab-${user.name}-clean-download-directory.service")
        machine.wait_until_fails("pgrep -u ${user.name} delete-older-files.sh")
        machine.succeed("test -e ${user.home}/download/should-be-kept")
        machine.succeed("test ! -e ${user.home}/download/should-be-removed")
  '';
}
