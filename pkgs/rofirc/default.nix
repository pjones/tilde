{
  stdenvNoCC,
  lib,
  makeWrapper,
  bash,
  coreutils,
  rofi,
  superkey,
}:
let
  deps = [
    bash
    coreutils
    rofi
    superkey
  ];

  path = lib.makeBinPath deps;
in
stdenvNoCC.mkDerivation {
  name = "rofirc";
  src = ./.;
  phases = [
    "unpackPhase"
    "installPhase"
    "fixupPhase"
  ];
  buildInputs = [ makeWrapper ];

  installPhase = ''
    mkdir -p $out/wrapped $out/bin $out/etc $out/themes

    for file in bin/* ; do
      name=$(basename "$file")
      install -m 0550 "$file" "$out/wrapped"
      substituteAllInPlace "$out/wrapped/$name"

      makeWrapper "$out/wrapped/$name" "$out/bin/$name" \
        --prefix PATH : "${path}"
    done

    for file in themes/*; do
      install -m 0440 "$file" "$out/themes"
      substituteAllInPlace "$out/themes/$(basename "$file")"
    done

    install -m 0440 etc/config.rasi "$out/etc"
    substituteAllInPlace "$out/etc/config.rasi"
  '';
}
