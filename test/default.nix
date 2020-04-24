{ sources ? import ../nix/sources.nix
, pkgs ? import sources.nixpkgs { }
}:

let
  home-manager-nixos =
    import "${sources.home-manager}/nixos";

in pkgs.nixosTest {
  name = "pjones-account";

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
    };
  };

  testScript = ''
    $machine->start;

    # Don't allow home-manager to run until the correct directories exist:
    $machine->stopJob("home-manager-pjones.service");
    $machine->succeed("mkdir -m 0755 -p /nix/var/nix/{profiles,gcroots}/per-user/pjones");
    $machine->succeed("chown pjones:root /nix/var/nix/{profiles,gcroots}/per-user/pjones");

    $machine->startJob("home-manager-pjones.service");
    $machine->waitForUnit("home-manager-pjones.service");
    $machine->succeed("test -L /home/pjones/.emacs");
  '';
}
