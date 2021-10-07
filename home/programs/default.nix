{ ...
}:
{
  imports = [
    ./clight.nix
    ./direnv.nix
    ./dunst.nix
    ./emacs.nix
    ./git.nix
    ./gromit-mpx.nix
    ./herbstluftwm.nix
    ./konsole.nix
    ./man.nix
    ./mpd.nix
    ./neuron.nix
    ./nixops.nix
    ./oled-display.nix
    ./polybar.nix
    ./rofi.nix
    ./shells.nix
    ./ssh.nix
    ./telegram.nix
  ];

  # Configure programs that don't need their own file:
  config = {
    # Chromium:
    # https://wiki.archlinux.org/index.php/Chromium#Dark_mode
    xdg.configFile."chromium-flags.conf".text = ''
      --force-dark-mode
      --enable-features=WebUIDarkMode
    '';
  };
}
