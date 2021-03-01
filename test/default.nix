{ sources ? import ../nix/sources.nix
, pkgs ? import sources.nixpkgs { }
}:
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
    tilde = { ... }: {
      imports = [ virtual.tilde ];

      services.xserver.displayManager.defaultSession = "xmonad";
      services.xserver.displayManager.autoLogin = {
        enable = true;
        user = user.name;
      };

      # Some extra RAM for X11:
      virtualisation.memorySize = 2048;

      # Disable some services that don't work in the test VM.
      home-manager.users.${user.name} = { pkgs, lib, ... }: {
        tilde.programs.mpd.enable = false;
        tilde.programs.neuron.enable = false;
        services.syncthing.enable = false;
        services.udiskie.enable = lib.mkForce false;

        # Force some packages to build to make sure they work even
        # though they were disabled above:
        home.packages = with pkgs; [
          haskellPackages.neuron
          mpd
          pjones.oled-display
          syncthing
          udiskie
        ];
      };

      environment.systemPackages = with pkgs; [
        neofetch
      ];
    };
  };

  testScript = ''
    start_all()

    # Prepare some directories for the tests:
    tilde.succeed("mkdir -m 0755 -p ${user.home}/notes/bookmarks")
    tilde.succeed("chown ${user.name}:root ${user.home}/notes/bookmarks")

    with subtest("Verify home-manager installed config files"):
        tilde.wait_for_unit("home-manager-${user.name}.service")
        tilde.succeed("test -L ${user.home}/.config/emacs/init.el")
        tilde.succeed("test -L ${user.home}/.xsession")

    with subtest("Verify activation script created some links"):
        tilde.succeed("test -L ${user.home}/.cache/emacs/bookmarks")

    with subtest("Cron job emulation"):
        tilde.require_unit_state("crontab-${user.name}-test-job.timer", "active")
        tilde.start_job("crontab-${user.name}-test-job.service")
        tilde.wait_for_file("/tmp/crontab-test-job")
        tilde.succeed("test $(stat --format=%U /tmp/crontab-test-job) = ${user.name}")

    with subtest("Wait for login"):
        tilde.wait_for_file("${user.home}/.Xauthority")
        tilde.succeed("xauth merge ${user.home}/.Xauthority")

    with subtest("Check xmonad started"):
        tilde.wait_until_succeeds("pgrep xmonadrc")
        tilde.sleep(3)

    with subtest("Launch terminal"):
        tilde.execute("su - ${user.name} -c 'DISPLAY=:0.0 konsole --hold -e neofetch &'")
        tilde.wait_for_window("konsole")

    with subtest("Wait to get a screenshot"):
        tilde.sleep(3)
        tilde.screenshot("screen")

    with subtest("Lock screen"):
        tilde.send_key("ctrl-alt-l")
        tilde.sleep(3)
        tilde.screenshot("lock")

    with subtest("Check mandb cache"):
        tilde.succeed("test -d ${user.home}/.cache/man/etc-profiles-per-user-${user.name}")
  '';
}
