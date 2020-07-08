# Create a virtual machine via NixOps:
{ sources ? import ../nix/sources.nix
, pkgs ? import sources.nixpkgs { }
}:
let
  home-manager-nixos = import "${sources.home-manager}/nixos";
in
{
  network.description = "Account Testing VM";

  defaults = {
    deployment.targetEnv = "libvirtd";
    deployment.libvirtd.memorySize = 2048;
    deployment.libvirtd.baseImageSize = 40;
    security.sudo.wheelNeedsPassword = false;
  };

  machine = { ... }: {
    imports = [
      home-manager-nixos
      ../.
    ];

    pjones = {
      putInWheel = true;
      isWorkstation = true;
      neuron.enable = true;
    };

    users.users.pjones = {
      password = "password";
    };
  };
}
