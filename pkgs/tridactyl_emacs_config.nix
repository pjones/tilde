{
  stdenvNoCC,
  src,
}:

stdenvNoCC.mkDerivation {
  inherit src;

  pname = "tridactyl_emacs_config";
  version = builtins.substring 0 7 src.rev;

  phases = [
    "unpackPhase"
    "installPhase"
    "fixupPhase"
  ];

  installPhase = ''
    mkdir -p $out/etc
    cp -a emacs_bindings $out/etc/
    sed -i -Ee 's/^ *command.*//' $out/etc/emacs_bindings
  '';
}
