{ sources ? import ../nix/sources.nix
, pkgs ? import sources.nixpkgs { }
}:
let
  user = import ./user.nix;
in
pkgs.nixosTest {
  name = "tilde-herbstluftwm-test";

  nodes = {
    machine = { lib, ... }: {
      imports = [
        "${sources.nixpkgs}/nixos/tests/common/x11.nix"
        ../devices/generic-nixos.nix
      ];

      services.xserver = {
        displayManager.defaultSession = lib.mkForce "xsession";
        windowManager.icewm.enable = lib.mkForce false;

        # Add a custom desktop session just for this test:
        desktopManager.session = lib.singleton {
          name = "xsession";
          enable = true;
          start = "exit 1"; # Should never be called.
        };
      };

      test-support.displayManager.auto.user = user.name;

      tilde.username = user.name;
      tilde.xsession.fonts.enable = true;

      home-manager.users.${user.name} = { pkgs, lib, ... }: {
        tilde.programs.herbstluftwm.enable = true;
        tilde.programs.konsole.enable = true;
        tilde.programs.polybar.enable = true;
        tilde.xsession.lock.enable = true;
        tilde.xsession.wallpaper.enable = true;
      };

      environment.systemPackages = with pkgs; [
        neofetch
      ];
    };
  };

  testScript = ''
    with subtest("Start machines and prepare"):
        start_all()

    with subtest("Wait for login"):
        machine.wait_for_file("${user.home}/.Xauthority")
        machine.succeed("xauth merge ${user.home}/.Xauthority")

    with subtest("Check window manager started"):
        machine.wait_until_succeeds("pgrep herbstluftwm")
        machine.sleep(3)

    with subtest("Launch terminal"):
        machine.copy_from_host(
            "${./stage-for-screenshot.sh}",
            "/tmp/stage.sh",
        )
        machine.execute(
            "su - ${user.name} -c 'DISPLAY=:0 herbstclient keybind Control-Alt-s spawn /tmp/stage.sh'"
        )
        machine.sleep(1)
        machine.send_key("ctrl-alt-s")
        machine.wait_for_window("konsole")

    with subtest("Wait to get a screenshot"):
        machine.sleep(3)
        machine.screenshot("screen")

    with subtest("Lock screen"):
        machine.execute("loginctl lock-sessions")
        machine.sleep(3)
        machine.screenshot("lock")
  '';
}
