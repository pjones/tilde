{ stdenvNoCC
}:

stdenvNoCC.mkDerivation {
  pname = "sweet-nova";
  version = "git";
  src = (import ../nix/sources.nix).sweet-nova;
  phases = [ "unpackPhase" "installPhase" "fixupPhase" ];

  installPhase = ''
    mkdir -p "$out/share/konsole/themes/sweet-nova"

    sed -E '/Opacity=/ d' \
      < kde/konsole/Sweet.colorscheme \
      > "$out/share/konsole/themes/sweet-nova/Sweet.colorscheme"

    mkdir -p "$out/share/sddm/themes/sweet-nova"
    cp -rpv kde/sddm/* "$out/share/sddm/themes/sweet-nova/"
  '';
}
