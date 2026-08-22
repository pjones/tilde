{ self, pkgs }:
let
  user = self.lib.test.user;
in
pkgs.testers.nixosTest {
  name = "greetd-test";

  nodes = {
    machine =
      { ... }:
      {
        imports = [
          self.nixosModules.test-wayland
        ];
      };
  };

  testScript = ''
    with subtest("Start machines and prepare"):
        start_all()
        machine.wait_for_unit("multi-user.target")

    with subtest("Console login"):
        machine.send_chars("${user.name}")
        machine.send_key("ret")
        machine.send_chars("password")
        machine.send_key("ret")

    with subtest("Wait for compositor to start"):
        machine.wait_for_file("/run/user/1000/wayland-1")
        machine.wait_until_succeeds("pgrep wayle")

    with subtest("Exit compositor"):
        machine.succeed("su - ${user.name} -c check-kill-compositor.sh")
  '';
}
