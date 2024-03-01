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
    ./dunst.nix
    ./emacs.nix
    ./firefox.nix
    ./git.nix
    ./gromit-mpx.nix
    ./gtk.nix
    ./haskell.nix
    ./herbstluftwm.nix
    ./man.nix
    ./mpd.nix
    ./oled-display.nix
    ./polybar.nix
    ./qt.nix
    ./screen-lock.nix
    ./shells.nix
    ./ssh.nix
    ./syncthing.nix
    ./wallpaper.nix
  ];
}
