# Create a virtual machine via NixOps:
{ sources ? import ../nix/sources.nix
}:
let
  user = import ./user.nix;
in
{
  network.description = "Account Testing VM";

  defaults = { lib, ... }: {
    deployment.targetEnv = "libvirtd";
    networking.domain = "devalot.com";
    security.sudo.wheelNeedsPassword = false;

    tilde.username = user.name;
    users.users.${user.name}.password = user.password;

    virtualisation.libvirtd.enable = lib.mkForce false;
    virtualisation.docker.enable = lib.mkForce false;
  };

  desktop-testing = { config, lib, ... }: {
    imports = [ ../devices/generic-nixos.nix ];

    deployment.libvirtd.memorySize = 2048;
    deployment.libvirtd.baseImageSize = 50;

    tilde.xsession = {
      enable = true;
    };

    home-manager.users.${config.tilde.username} = { ... }: {
      tilde.programs.emacs.enable = true;
      tilde.programs.gromit-mpx.enable = true;

      tilde.xsession.lock = {
        bluetooth.devices = [
          "BC:A8:A6:7D:A5:77"
        ];
      };
    };
  };

  basic-testing = { lib, ... }: {
    imports = [ ../devices/generic-nixos.nix ];
  };
}
