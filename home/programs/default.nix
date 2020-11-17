{ ...
}:
{
  imports = [
    ./clight.nix
    ./direnv.nix
    ./dunst.nix
    ./emacs.nix
    ./git.nix
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
  ];

  # Configure programs that don't need their own file:
  config = {
    programs.mcfly = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
    };

    # Chromium:
    # https://wiki.archlinux.org/index.php/Chromium#Dark_mode
    xdg.configFile."chromium-flags.conf".text = ''
      --force-dark-mode
      --enable-features=WebUIDarkMode
    '';
  };
}
