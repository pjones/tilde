{
  stdenvNoCC,
  makeWrapper,
  lib,
  procps,
  systemd,
}:

let
  path = lib.makeBinPath [
    procps
    systemd
  ];
in
stdenvNoCC.mkDerivation {
  name = "force-lock";
  src = ./.;
  dontBuild = true;
  buildInputs = [ makeWrapper ];

  installPhase = ''
    mkdir -p "$out/bin" "$out/wrapped"

    for file in *.sh; do
      name=$(basename "$file")
      install -m 0555 "$file" "$out/wrapped"

      makeWrapper "$out/wrapped/$name" "$out/bin/$name" \
        --prefix PATH : "${path}"
    done
  '';
}
