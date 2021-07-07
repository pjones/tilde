{ sources ? import ../nix/sources.nix
, pkgs ? import sources.nixpkgs { }
}:
pkgs.nixosTest {
  name = "tilde-kmonad-test";

  nodes = {
    machine = { ... }: {
      imports = [ ../devices/generic-nixos.nix ];

      tilde.workstation.kmonad = {
        enable = true;
        keyboards.qemu = {
          device = "/dev/input/event0";
        };
      };
    };
  };

  testScript = ''
    with subtest("Start machines"):
        start_all()

    with subtest("Verify KMonad started"):
        machine.wait_for_unit("kmonad-qemu.service")
  '';
}
