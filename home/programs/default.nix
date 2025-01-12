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
    ./gnupg.nix
    ./gromit-mpx.nix
    ./haskell.nix
    ./recoll.nix
    ./shells.nix
    ./ssh.nix
    ./syncthing.nix
  ];
}
