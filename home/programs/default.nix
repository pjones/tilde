{ config
, lib
, ...
}:
{
  imports = [
    ./base.nix
    ./direnv.nix
    ./emacs.nix
    ./firefox.nix
    ./git.nix
    ./gromit-mpx.nix
    ./konsole.nix
    ./man.nix
    ./mpd.nix
    ./neuron.nix
    ./oled-display.nix
    ./shells.nix
    ./ssh.nix
  ];
}
