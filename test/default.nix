{ sources ? import ../nix/sources.nix, pkgs ? import sources.nixpkgs { } }:
let
  virtual = import ./virtual.nix { inherit sources; };

  user = {
    name = "pjones";
    home = "/home/pjones";
  };

  xdo = "${pkgs.xdotool}/bin/xdotool";

in
pkgs.nixosTest {
  name = "${user.name}-account";

  nodes = {
    machine = { ... }@args: virtual.machine args // {
      services.xserver.displayManager.defaultSession = "xmonad";
      services.xserver.displayManager.sddm.autoLogin = {
        enable = true;
        user = user.name;
      };

      virtualisation.memorySize = 2048;

      home-manager.users.pjones = { ... }: {
        pjones.programs.mpd.enable = false;
        pjones.programs.neuron.enable = false;
        pjones.programs.oled-display.enable = false;
        services.syncthing.enable = false;
      };
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

    with subtest("Check xmonad started"):
        machine.wait_until_succeeds("pgrep xmonadrc")
        machine.sleep(3)

    with subtest("Launch terminal"):
        # FIXME: Update after fixing eterm not starting bug!
        # machine.send_key("mod4-ret")
        # machine.execute("su - ${user.name} -c 'DISPLAY=:0.0 eterm &'")
        machine.execute("su - ${user.name} -c 'DISPLAY=:0.0 xterm &'")
        machine.wait_for_window("term")

    with subtest("Wait to get a screenshot"):
        machine.sleep(3)
        machine.screenshot("screen")
  '';
}
