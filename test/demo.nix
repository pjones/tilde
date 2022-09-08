{ config, ... }:
let user = import ./user.nix;
in
{
  imports = [
    ./vm.nix
  ];

  config = {
    networking.hostName = "tilde-demo";

    # KDE Plasma is memory hungry in a VM:
    virtualisation.memorySize = 6144; # MB

    tilde = {
      enable = true;
      putInWheel = true;
      xsession.enable = true;
    };

    home-manager.users.${config.tilde.username} = { ... }: {
      tilde.programs.emacs.enable = true;
      tilde.programs.gromit-mpx.enable = true;
      tilde.programs.haskell.enable = true;
    };
  };
}
