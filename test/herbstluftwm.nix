{ pkgs, module }:
let
  user = import ./user.nix;

  # https://www.reddit.com/r/wallpapers/comments/ge4hrd/geometry/
  wallpaper = pkgs.fetchurl {
    url = "https://i.redd.it/tg9ac8kn10x41.jpg";
    sha256 = "0pb32hzrngl06c1icb2hmdq8ja7v1gc2m4ss32ihp6rk45c59lji";
  };
in
pkgs.nixosTest {
  name = "tilde-herbstluftwm-test";

  nodes = {
    machine = { lib, modulesPath, ... }: {
      imports = [
        (modulesPath + "/../tests/common/x11.nix")
        module
        ../devices/generic-nixos.nix
      ];

      services.xserver = {
        windowManager.icewm.enable = lib.mkForce false;
        windowManager.herbstluftwm.enable = true;
        windowManager.herbstluftwm.configFile = "${pkgs.pjones.hlwmrc}/config/autostart";
        displayManager.defaultSession = lib.mkForce "none+herbstluftwm";
      };

      test-support.displayManager.auto.user = user.name;
      tilde.username = user.name;

      home-manager.users.${user.name} = { pkgs, lib, ... }: {
        tilde.programs.konsole.enable = true;
      };

      environment.systemPackages = with pkgs; [
        feh
        neofetch
        xdotool
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
            "${wallpaper}",
            "/tmp/wallpaper.jpg",
        )
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
  '';
}
