{ self, module, pkgs }:

let
  withXwininfo = pkgs.appendOverlays [
    (final: prev: {
      xorg = prev.xorg // {
        xwininfo = self.inputs.superkey.packages.${prev.system}.xwininfo-tests;
      };
    })
  ];
in
withXwininfo.nixosTest {
  name = "tilde-screenshot";

  nodes = {
    machine = { config, pkgs, lib, ... }: {
      imports = [
        self.inputs.superkey.nixosModules.autologin
        self.inputs.superkey.nixosModules.qemu-sway
        module
        ../devices/generic-nixos.nix
      ];

      networking.hostName = "tilde";
      environment.systemPackages = [ pkgs.fastfetch ];

      tilde = {
        enable = true;
        graphical.enable = true;
      };

      home-manager.users.${config.tilde.username} = { ... }: {
        tilde.programs.emacs.enable = true;
      };
    };
  };

  testScript = ''
    with subtest("Start machines and prepare"):
        start_all()
        machine.wait_for_unit("multi-user.target")

    with subtest("Verify home-manager installed config files"):
        machine.succeed("test -L /home/pjones/.config/sway/config")

    with subtest("Wait for sway to start"):
        machine.wait_for_file("/run/user/1000/wayland-1")
        machine.wait_for_file("/tmp/sway-ipc.sock")
        machine.wait_until_succeeds("pgrep waybar")
        machine.wait_for_unit("emacs", "pjones")

    with subtest("Prepare for a screenshot"):
        machine.copy_from_host(
            "${self.inputs.superkey}/test/stage-for-screenshot.sh",
            "/tmp/stage.sh",
        )
        machine.succeed(
            "su - pjones -c 'swaymsg -t command exec bash /tmp/stage.sh'"
        )

    with subtest("Wait to get a screenshot"):
        machine.wait_for_window("fastfetch")
        machine.sleep(1)
        machine.screenshot("screen")

    with subtest("Exit sway"):
        machine.execute("su - pjones -c 'swaymsg -t command exit'")
        machine.wait_until_fails("pgrep -x sway")
        machine.wait_for_file("/tmp/sway-exit-ok")
  '';
}
