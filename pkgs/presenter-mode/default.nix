{ stdenvNoCC, glib }:

stdenvNoCC.mkDerivation rec {
  pname = "presenter-mode";
  version = "0.1.0";
  src = ./.;

  buildInputs = [ glib ];

  installPhase = ''
    export schema_dir="$out/share/gsettings-schema/${pname}-${version}/glib-2.0/schemas"
    mkdir -p "$out/bin" "$schema_dir"

    install --mode=0555 toggle-presenter-mode.sh "$out/bin/toggle-presenter-mode"
    substituteAllInPlace "$out/bin/toggle-presenter-mode"

    install \
      --mode=0400 \
      schema.xml \
      "$schema_dir/com.freerangebits.desktop.presenter-mode.gschema.xml"

    glib-compile-schemas --strict "$schema_dir"
  '';
}
