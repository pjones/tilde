{ pkgs, user, ... }:
let
  dir = "/var/lib/bluetooth-device-status";

  script = pkgs.writeShellScript "lock-screen-inhibit-test" ''
    set -ue
    set -o pipefail

    # Should be active:
    systemctl --user show xautolock-session.service |
      grep -E '^ActiveState=active$'

    # Pretend that a Bluetooth device went online:
    sudo touch ${dir}/online

    # The service should go offline:
    sleep 1 &&
      systemctl --user show xautolock-session.service |
      grep -E '^ActiveState=inactive$'

    # Pretend that a Bluetooth device went offline:
    sudo rm ${dir}/online

    # The service should go back online:
    sleep 1 &&
      systemctl --user show xautolock-session.service |
      grep -E '^ActiveState=active$'

  '';

  testScript = ''
    with subtest("Bluetooth can inhibit the auto locker"):
        machine.copy_from_host(
            "${script}",
            "/tmp/lock-screen-inhibit-test",
        )
        machine.succeed("su - ${user.name} -c 'bash /tmp/lock-screen-inhibit-test'")
  '';
in
{
  inherit testScript;
}
