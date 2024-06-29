{ config, lib, ... }:
let user = import ./user.nix;
in
{
  imports = [
    ./vm.nix
  ];

  config = {
    networking.hostName = "tilde-demo";

    tilde = {
      enable = true;
      graphical.enable = true;
      putInWheel = true;
    };

    home-manager.users.${config.tilde.username} = { ... }: {
      tilde.programs.emacs.enable = true;
      tilde.programs.gromit-mpx.enable = true;
      tilde.programs.haskell.enable = true;
    };
  };
}
