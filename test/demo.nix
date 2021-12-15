{ config, ... }:
let user = import ./user.nix;
in
{
  imports = [
    ./vm.nix
  ];

  config = {
    tilde = {
      enable = true;
      putInWheel = true;
      xsession.enable = true;
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
}
