{ config
, lib
, ...
}:
{
  imports = [
    ./base.nix
    ./browser.nix
    ./contacts.nix
    ./direnv.nix
    ./emacs.nix
    ./firefox.nix
    ./git.nix
    ./gromit-mpx.nix
    ./haskell.nix
    ./man.nix
    ./oled-display.nix
    ./shells.nix
    ./ssh.nix
    ./syncthing.nix
  ];
}
