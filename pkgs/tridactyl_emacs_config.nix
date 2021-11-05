{ stdenvNoCC
, lib
}:

let
  sources = import ../nix/sources.nix;
in

stdenvNoCC.mkDerivation {
  pname = "tridactyl_emacs_config";
  version = builtins.substring 0 7 sources.tridactyl_emacs_config.rev;

  src = sources.tridactyl_emacs_config;
  phases = [ "unpackPhase" "installPhase" "fixupPhase" ];

  installPhase = ''
    mkdir -p $out/etc
    cp -a emacs_bindings $out/etc/
    sed -i -Ee 's/^ *command.*//' $out/etc/emacs_bindings
  '';
}
