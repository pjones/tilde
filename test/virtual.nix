# Create a virtual machine via NixOps:
{ sources ? import ../nix/sources.nix
}:
let
  user = import ./user.nix;
in
{
  network.description = "Account Testing VM";

  defaults = {
    deployment.targetEnv = "libvirtd";
    deployment.libvirtd.memorySize = 2048;
    deployment.libvirtd.baseImageSize = 50;
    security.sudo.wheelNeedsPassword = false;
  };

  tilde = { config, lib, ... }: {
    imports = [ ../devices/generic-nixos.nix ];
    networking.domain = "devalot.com";
    tilde.username = user.name;
    tilde.xsession.enable = true;

    users.users.${user.name}.password = user.password;
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
