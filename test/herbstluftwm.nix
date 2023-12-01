{ pkgs, module }:
let
  user = import ./user.nix;
in
pkgs.nixosTest {
  name = "tilde-herbstluftwm-test";

  nodes = {
    machine = { pkgs, lib, modulesPath, ... }: {
      imports = [
        (modulesPath + "/../tests/common/x11.nix")
        module
        ../devices/generic-nixos.nix
      ];

      services.xserver.displayManager.gdm.enable = lib.mkForce false;
      test-support.displayManager.auto.user = user.name;
      users.users.${user.name}.password = user.password;

      tilde.xsession.enable = true;
      tilde.username = user.name;

      home-manager.users.${user.name} = { lib, ... }: {
        tilde.programs.emacs.enable = true;
      };

      environment.systemPackages = with pkgs; [
        neofetch
        xdotool
      ];
    };
  };

  testScript = ''
    with subtest("Start machines and prepare"):
        start_all()

    with subtest("Verify home-manager installed config files"):
        machine.wait_for_unit("home-manager-${user.name}.service")
        machine.succeed("test -L ${user.home}/.config/emacs/init.el")

    with subtest("Wait for login"):
        machine.wait_for_x()
        machine.wait_for_file("${user.home}/.Xauthority")
        machine.succeed("xauth merge ${user.home}/.Xauthority")

    with subtest("Check window manager started"):
        machine.wait_until_succeeds("pgrep herbstluftwm")
        machine.sleep(3)
        machine.copy_from_host(
            "${./stage-for-screenshot.sh}",
            "/tmp/stage.sh",
        )
        machine.succeed(
            "su - ${user.name} -c 'DISPLAY=:0 herbstclient keybind Control-Alt-s spawn /tmp/stage.sh'"
        )
        machine.sleep(1)
        machine.send_key("ctrl-alt-s")
        machine.wait_for_window(r"neofetch")

    with subtest("Wait to get a screenshot"):
        machine.sleep(3)
        machine.screenshot("screen")
  '';
}
