{ sources ? import ../nix/sources.nix
, pkgs ? import sources.nixpkgs { }
}:

let
  home-manager-nixos =
    import "${sources.home-manager}/nixos";

  user = {
    name = "pjones";
    home = "/home/pjones";
  };

  xdo = "${pkgs.xdotool}/bin/xdotool";

in pkgs.nixosTest {
  name = "${user.name}-account";

  nodes = {
    machine = {...}: {
      imports = [
        home-manager-nixos
        ../.
      ];

      pjones = {
        putInWheel = true;
        isWorkstation = true;
      };

      services.xserver.displayManager.defaultSession = "plasma+xmonad";
      services.xserver.displayManager.sddm.autoLogin = {
        enable = true;
        user = user.name;
      };

      virtualisation.memorySize = 1024;
    };
  };

  testScript = ''
    start_all()

    with subtest("Help home-manager get going"):
        machine.stop_job("home-manager-${user.name}.service")
        machine.succeed("mkdir -m 0755 -p /nix/var/nix/{profiles,gcroots}/per-user/${user.name}")
        machine.succeed("chown pjones:root /nix/var/nix/{profiles,gcroots}/per-user/${user.name}")
        machine.start_job("home-manager-${user.name}.service")

    with subtest("Verify home-manager installed config files"):
        machine.wait_for_unit("home-manager-${user.name}.service")
        machine.succeed("test -L ${user.home}/.emacs")
        machine.succeed("test -L ${user.home}/.xsession")

    with subtest("Wait for login"):
        machine.wait_for_file("${user.home}/.Xauthority")
        machine.succeed("xauth merge ${user.home}/.Xauthority")

    with subtest("Check plasmashell started"):
        machine.wait_until_succeeds("pgrep plasmashell")
        machine.wait_for_window("^Desktop ")
        machine.wait_until_succeeds("pgrep xmonadrc")

    with subtest("Run Konsole"):
        for i in range(0, 3):
            machine.execute("su - ${user.name} -c 'DISPLAY=:0.0 konsole &'")
        machine.wait_for_window("Konsole")

    with subtest("Wait to get a screenshot"):
        machine.execute(
            "${xdo} key Alt+F1 sleep 10"
        )
        machine.sleep(3)
        machine.screenshot("screen")
  '';
}
