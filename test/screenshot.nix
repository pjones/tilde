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
    ${self.inputs.superkey.checks.x86_64-linux.sway.testHelpers}
    superkey_start()
    superkey_screenshot("dark")
    superkey_switch_to_light_theme()
    superkey_screenshot("light")
    superkey_exit()
  '';
}
