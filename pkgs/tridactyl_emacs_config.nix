{ stdenvNoCC
, lib
, inputs
}:

stdenvNoCC.mkDerivation {
  pname = "tridactyl_emacs_config";
  version = builtins.substring 0 7 inputs.tridactyl_emacs_config.rev;

  src = inputs.tridactyl_emacs_config;
  phases = [ "unpackPhase" "installPhase" "fixupPhase" ];

  installPhase = ''
    mkdir -p $out/etc
    cp -a emacs_bindings $out/etc/
    sed -i -Ee 's/^ *command.*//' $out/etc/emacs_bindings
  '';
}
