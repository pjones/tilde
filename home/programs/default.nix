{ config
, lib
, ...
}:
{
  imports = [
    ./base.nix
    ./beets.nix
    ./browser.nix
    ./contacts.nix
    ./direnv.nix
    ./emacs.nix
    ./firefox.nix
    ./git.nix
    ./gromit-mpx.nix
    ./haskell.nix
    ./man.nix
    ./shells.nix
    ./ssh.nix
    ./syncthing.nix
  ];
}
