{ ...
}:
let
  sources = import ../../nix/sources.nix;
in
{
  imports = [ "${sources."pjones/emacsrc"}/nix/home.nix" ];
}
