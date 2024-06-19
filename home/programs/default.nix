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
    ./gtk.nix
    ./haskell.nix
    ./man.nix
    ./mpd.nix
    ./oled-display.nix
    ./qt.nix
    ./shells.nix
    ./ssh.nix
    ./syncthing.nix
  ];
}
