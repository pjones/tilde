{
  stdenvNoCC,
  lib,
  tildeInstallScripts,
  coreutils,
}:
let
  path = lib.makeBinPath [
    coreutils
  ];
in
stdenvNoCC.mkDerivation {
  name = "tilde-scripts-browser";
  phases = [
    "installPhase"
    "fixupPhase"
  ];

  nativeBuildInputs = [ tildeInstallScripts ];

  installPhase = ''
    installScripts "$out" "${../scripts/browser}" "${path}"
  '';
}
