# There's No Place Like `~`

<p align="center">
  <img src="https://i.imgur.com/7tYFD0G.png"/>
</p>

(The screenshot above was taken at the end of the automated tests
running in an ephemeral virtual machine.)

## Reproducible Configuration

Thanks to [Nix][], [nixpkgs][], and [home-manager][] this repository
can reproduce a working desktop environment exactly as configured
without having to tweak files by hand or in GUI settings tools.

## Details

  * Linux Distribution: [NixOS][nix]

  * Window Manager: [XMonad](https://github.com/pjones/xmonadrc)

  * Terminal: [Emacs](https://github.com/pjones/emacsrc) with [`libvterm`](https://github.com/akermu/emacs-libvterm)

  * Status Bar: [Polybar](home/programs/polybar.nix)

  * Notifications: [Dunst](home/programs/dunst.nix)

  * Theme: [Sweet](https://github.com/EliverLara/Sweet)

  * Icons: [Elementary](https://github.com/elementary/icons)

  * Cursors: [Oreo Pink](https://github.com/varlesh/oreo-cursors)

  * Proportional Font: [Overpass](https://overpassfont.org/)

  * Monospace Font: [Hermit](https://pcaro.es/p/hermit/)

[nix]: https://nixos.org/
[nixpkgs]: https://github.com/NixOS/nixpkgs
[home-manager]: https://github.com/rycee/home-manager
