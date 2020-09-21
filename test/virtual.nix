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

  machine = { config, lib, ... }: {
    imports = [
      ../nixos
      ../devices/generic-nixos.nix
    ];

    tilde.xsession.enable = true;

    users.users.${config.tilde.username}.password = "password";
    virtualisation.libvirtd.enable = lib.mkForce false;
    virtualisation.docker.enable = lib.mkForce false;

    home-manager.users.${config.tilde.username} = { ... }: {
      tilde.xsession.lock = {
        bluetooth.devices = [
          "BC:A8:A6:7D:A5:77"
        ];
      };
    };
  };
}
