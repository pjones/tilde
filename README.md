# There's No Place Like `~/`

<p align="center">
  <img src="https://i.imgur.com/nnC3F5s.png"/>
</p>

(The screenshot above was taken at the end of the automated tests
running in an ephemeral virtual machine.)

## Reproducible Configuration

Thanks to [Nix][], [nixpkgs][], and [home-manager][] this repository
can reproduce a working desktop environment exactly as configured
without having to tweak files by hand or in GUI settings tools.

## Details

  * Linux Distribution: [NixOS][nix]

  * Window Manager: [Herbstluftwm](https://github.com/pjones/hlwmrc)

  * Terminal: Konsole with [tmux](https://github.com/pjones/tmuxrc)

  * Status Bar: [Polybar](home/programs/polybar.nix)

  * Notifications: [Dunst](home/programs/dunst.nix)

  * Theme: [Sweet](https://github.com/EliverLara/Sweet)

  * Icons: [Pop](https://github.com/pop-os/icon-theme)

  * Cursors: [Bibata](https://github.com/ful1e5/Bibata_Cursor)

  * Proportional Font: [Overpass](https://overpassfont.org/)

  * Monospace Font: [Hermit](https://pcaro.es/p/hermit/)

[nix]: https://nixos.org/
[nixpkgs]: https://github.com/NixOS/nixpkgs
[home-manager]: https://github.com/rycee/home-manager
