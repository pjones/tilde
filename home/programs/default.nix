{ config
, lib
, ...
}:
{
  imports = [
    ./base.nix
    ./browser.nix
    ./direnv.nix
    ./emacs.nix
    ./firefox.nix
    ./git.nix
    ./gromit-mpx.nix
    ./gtk.nix
    ./haskell.nix
    ./konsole.nix
    ./man.nix
    ./mpd.nix
    ./oled-display.nix
    ./plasma.nix
    ./polybar.nix
    ./qt.nix
    ./shells.nix
    ./ssh.nix
    ./syncthing.nix
    ./xfce.nix
  ];
}
