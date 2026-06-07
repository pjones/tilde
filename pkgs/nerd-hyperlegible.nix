{
  stdenvNoCC,
  atkinson-hyperlegible,
  nerd-font-patcher,
}:

stdenvNoCC.mkDerivation {
  pname = "nerd-hyperlegible";
  version = atkinson-hyperlegible.version;
  dontUnpack = true;
  dontBuild = true;

  buildInputs = [ nerd-font-patcher ];

  installPhase = ''
    dest="$out/share/fonts/opentype"
    mkdir -p "$dest"

    for file in ${atkinson-hyperlegible}/share/fonts/opentype/*.otf; do
      nerd-font-patcher \
        --outputdir "$dest" \
        --complete --no-progressbars \
        "$file"
    done
  '';
}
