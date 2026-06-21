{ self, pkgs }:

let
  withXwininfo = pkgs.appendOverlays [
    (final: prev: {
      xorg = prev.xorg // {
        xwininfo = self.packages.${prev.stdenv.hostPlatform.system}.xwininfo-tests;
      };
    })
  ];

  testHelpers = ''
    def screenshot(file):
        import os.path;
        path = os.path.join(machine.out_dir, file) + ".png"
        machine.send_monitor_command(f"screendump {path} -f png")

    def superkey_start():
        with subtest("Start machines and prepare"):
            start_all()
            machine.wait_for_unit("multi-user.target")

        with subtest("Verify home-manager installed config files"):
            machine.succeed("test -L /home/pjones/.config/emacs/init.el")

        with subtest("Wait for Niri to start"):
            machine.wait_for_file("/run/user/1000/wayland-1")
            machine.wait_until_succeeds("pgrep waybar")
            machine.wait_for_unit("emacs", "pjones")
            machine.wait_for_file("/run/user/1000/emacs/server")
            machine.send_key("f1") # Must issue before wait_for_window
            machine.wait_for_file("/home/pjones/niri-socket")

    def superkey_screenshot(theme="dark"):
        with subtest(f"Screenshot: {theme}"):
            machine.send_key("f2")
            machine.wait_for_window("fastfetch")
            machine.sleep(5) # Need other windows to go away and settle
            screenshot(f"screenshot-{theme}")
            machine.sleep(1) # Need to be stable for the screenshot

    def superkey_lock():
        with subtest("Test screen locking"):
            machine.send_key("f3")
            machine.wait_until_succeeds("pgrep gtklock")
            machine.sleep(1)
            screenshot("lock")
            machine.send_chars("password")
            machine.send_key("ret")
            machine.wait_until_fails("pgrep gtklock")

    def superkey_switch_to_light_theme():
        with subtest("Switching to light theme"):
            machine.send_key("meta_l-spc")
            machine.sleep(1)
            machine.send_chars("light theme")
            machine.send_key("ret")
            machine.sleep(2)

    def superkey_exit():
        with subtest("Exit Niri"):
            machine.send_key("f4")
  '';

  linkNiriSock = pkgs.writeShellScriptBin "link-niri-socket" ''
    exec > >(systemd-cat -t link-niri -p emerg) 2>&1
    ln -nsf "$NIRI_SOCKET" /home/pjones/niri-socket
  '';

  test = withXwininfo.testers.runNixOSTest {
    name = "niri-test";

    qemu.package = pkgs.qemu;

    passthru.testHelpers = testHelpers;

    nodes = {
      machine =
        { pkgs, ... }:
        {
          imports = [
            self.nixosModules.test-wayland
            self.nixosModules.test-autologin
          ];

          environment.systemPackages = [
            linkNiriSock
            pkgs.fastfetch
          ];

          # OpenGL is not supported by display backend 'none'
          virtualisation.graphics = true;

          virtualisation.qemu.options = [
            "-spice port=0,disable-ticketing=on,image-compression=off,gl=on,rendernode=/dev/dri/by-path/pci-0000:c1:00.0-render,seamless-migration=on"
            "-device virtio-vga-gl,id=video0,max_outputs=1"
            #"-display spice-app,gl=on"
          ];

          home-manager.users.pjones =
            { ... }:
            {
              wayland.windowManager.niri.settings.binds = {
                "F1".spawn = [ "link-niri-socket" ];
                "F2".spawn = [ "stage-for-screenshot.sh" ];
                "F3".spawn = [ "test-lock-screen.sh" ];
                "F4".spawn = [ "check-kill-compositor.sh" ];
              };
            };
        };
    };

    testScript = ''
      ${testHelpers}
      superkey_start()
      superkey_screenshot("dark")
      superkey_lock()
      superkey_switch_to_light_theme()
      superkey_screenshot("light")
      superkey_exit()
    '';
  };
in
test.overrideTestDerivation (orig: {
  buildCommand = ''
    set -x
    export DISPLAY=:0
    ${orig.buildCommand}
  '';
})
