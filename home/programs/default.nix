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
    ./haskell.nix
    ./inhibit-lock-screen.nix
    ./konsole.nix
    ./man.nix
    ./mpd.nix
    ./neuron.nix
    ./oled-display.nix
    ./plasma.nix
    ./shells.nix
    ./ssh.nix
  ];
}
