{
  encryption-utils,
  lib,
  makeWrapper,
  qrencode,
  stdenvNoCC,
  writers,
}:

let
  pyScript = writers.writePython3 "wg-gen" {
    doCheck = false; # I don't use flake8
  } ./wg-gen.py;

  path = lib.makeBinPath [
    encryption-utils
    qrencode
  ];
in
stdenvNoCC.mkDerivation {
  name = "wg-gen";
  src = ./.;

  nativeBuildInputs = [
    makeWrapper
  ];

  installPhase = ''
    mkdir -p "$out/bin"

    for file in *.sh; do
      base=$(basename "$file")
      install --mode=0755 "$file" "$out/bin/.$base"

      makeWrapper "$out/bin/.$base" ""$out/bin/$base"" \
        --prefix PATH : "${path}"
    done

    (cd "$out/bin" &&
      ln -s "${pyScript}" wg-gen.py)
  '';
}
