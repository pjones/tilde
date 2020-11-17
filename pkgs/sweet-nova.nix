{ stdenvNoCC
}:

stdenvNoCC.mkDerivation {
  pname = "sweet-nova";
  version = "git";
  src = (import ../nix/sources.nix).sweet-nova;
  phases = [ "unpackPhase" "installPhase" "fixupPhase" ];

  installPhase = ''
    ##########
    # Konsole:
    mkdir -p "$out/share/konsole/themes/sweet-nova"

    sed -E '/Opacity=/ d' \
      < kde/konsole/Sweet.colorscheme \
      > "$out/share/konsole/themes/sweet-nova/Sweet.colorscheme"

    ##########
    # SDDM:
    sddm="$out/share/sddm/themes/sweet-nova"
    mkdir -p "$sddm"
    cp -a kde/sddm/* "$sddm/"
    cp extras/Sweet-Wallpapers/Sweet-space.png "$sddm/assets/space.png"
    sed -Ei 's|^Background=.*|Background="assets/space.png"|' "$sddm/theme.conf"

    ##########
    # Kvantum:
    kvantum="$out/share/kvantum/Sweet-Nova"
    mkdir -p "$kvantum"
    cp kde/kvantum/Sweet.svg "$kvantum/Sweet-Nova.svg"
    cp kde/kvantum/Sweet-transparent-toolbar.kvconfig "$kvantum/Sweet-Nova-transparent-toolbar.kvconfig"

    sed -E \
      -e '/translucent_windows=/ d' \
      -e '/transparent_menutitle=/ d' \
      < kde/kvantum/Sweet.kvconfig \
      > "$kvantum/Sweet-Nova.kvconfig"

    ##########
    # GTK and others:
    mkdir -p "$out/share/themes/Sweet-Nova"
    cp -a \
      assets \
      gnome-shell \
      gtk-2.0 \
      gtk-3.0 \
      metacity-1 \
      xfwm4 \
      "$out/share/themes/Sweet-Nova"
  '';
}
