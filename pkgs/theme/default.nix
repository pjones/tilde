{
  lib,
  stdenvNoCC,
  ruby,
  colors,
}:

stdenvNoCC.mkDerivation {
  pname = "superkey-theme";
  version = "git";
  src = ./.;
  dontBuild = true;

  passthru = {
    # For a description of what the color names mean:
    #
    # https://github.com/chriskempson/base16/blob/main/styling.md
    colors = lib.importJSON colors;
  };

  buildInputs = [ ruby ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/theme
    cp waybar.css $out/theme
    ruby build.rb "${colors}" "$out/theme"

    runHook postInstall
  '';
}
