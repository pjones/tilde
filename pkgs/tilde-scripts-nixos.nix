{
  stdenvNoCC,
  lib,
  tildeInstallScripts,
  coreutils,
  findutils,
  gnugrep,
  python3,
}:
let
  path = lib.makeBinPath [
    coreutils
    findutils
    gnugrep
    python3
  ];
in
stdenvNoCC.mkDerivation {
  name = "tilde-scripts";
  dontUnpack = true;
  dontBuild = true;
  nativeBuildInputs = [ tildeInstallScripts ];

  installPhase = ''
    installScripts "$out" "${../scripts/nixos}" "${path}"
    patchShebangs "$out/scripts"
  '';
}
