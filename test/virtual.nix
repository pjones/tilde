# Create a virtual machine via NixOps:
{ sources ? import ../nix/sources.nix
}:
{
  network.description = "Account Testing VM";

  defaults = {
    deployment.targetEnv = "libvirtd";
    deployment.libvirtd.memorySize = 2048;
    deployment.libvirtd.baseImageSize = 40;
    security.sudo.wheelNeedsPassword = false;
  };

  machine = { config, ... }: {
    imports = [
      ../nixos
      ../devices/generic-nixos.nix
    ];

    tilde.xsession.enable = true;
    users.users.${config.tilde.username}.password = "password";
  };
}
