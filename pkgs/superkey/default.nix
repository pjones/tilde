{
  stdenvNoCC,
  lib,
  makeWrapper,
  coreutils,
  findutils,
  gawk,
  glib,
  gnugrep,
  jq,
  netcat,
  openssh,
  procps,
}:

let
  deps = [
    coreutils
    findutils
    gawk
    glib
    gnugrep
    jq
    netcat
    openssh
    procps
  ];

  path = lib.makeBinPath deps;
in
stdenvNoCC.mkDerivation {
  pname = "superkey";
  version = "0.1.0";
  src = ./.;

  buildInputs = [ makeWrapper ] ++ deps;

  installPhase = ''
    mkdir -p "$out/scripts" "$out/bin"

    while IFS= read -r -d "" file; do
      name=$(basename "$file")

      install --mode=0555 "$file" "$out/scripts/$name"

      makeWrapper "$out/scripts/$name" "$out/bin/$name" \
        --prefix PATH : "${path}"
    done < <(find . -type f -name '*.sh' -print0)
  '';
}
