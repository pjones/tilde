# There's No Place Like `~/`

<p align="center">
  <img src="./support/screenshot-dark.png"/>
</p>

## Reproducible Configuration

Thanks to [Nix][], [nixpkgs][], and [home-manager][] this repository
can reproduce a working desktop environment exactly as configured
without having to tweak files by hand or in GUI settings tools.

The screenshot above was taken automatically by a non-interactive test
running in an ephemeral virtual machine (`nix flake check`).

## Details

  * Linux Distribution: [NixOS][nix]

  * Terminal: [Emacs][] w/ libvterm

  * Compositor: [Niri][]

  * Status Bar: [Wayle][]

  * Notifications: [Sway Notification Center][swaync]

  * Screen Lock: [swayidle][] and [gtklock][]

  * Wallpaper Daemon: [wpaperd][]

  * Monospace Font: [Hermit](https://pcaro.es/p/hermit/)

  * Variable-spaced Font: [Atkinson Hyperlegible][hyperlegible]

## Try It Out

If you have [Nix][] installed and configured with flake support you
can run my configuration in a virtual machine on any Linux distro:

```sh
nix run github:pjones/tilde
```

Use the key binding `Super+Space` to start `rofi`.  Other key bindings
can be found in my [Wayland configuration][niricfg].

[emacs]: https://github.com/pjones/emacsrc
[gtklock]: https://github.com/jovanlanik/gtklock
[home-manager]: https://github.com/rycee/home-manager
[hyperlegible]: https://brailleinstitute.org/freefont
[niricfg]: modules/programs/niri.nix
[nix]: https://nixos.org/
[nixpkgs]: https://github.com/NixOS/nixpkgs
[swayidle]: https://github.com/swaywm/swayidle
[swaync]: https://github.com/ErikReider/SwayNotificationCenter
[wayle]: https://wayle.app/
[wpaperd]: https://github.com/danyspin97/wpaperd
