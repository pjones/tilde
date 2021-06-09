{ stdenvNoCC
, lib
, inkscape
, xcursorgen
}:
stdenvNoCC.mkDerivation rec {
  pname = "oreo-cursors";
  version = "git";
  src = (import ../nix/sources.nix).oreo-cursors;
  makeFlags = [ "PREFIX=$(out)" ];

  nativeBuildInputs = [
    inkscape
    xcursorgen
  ];

  meta = {
    description = "Color material cursors for your Linux desktop with cute animation.";
    homepage = "https://github.com/varlesh/oreo-cursors";
    license = lib.licenses.gpl2;
    platforms = lib.platforms.linux;
    maintainers = with lib.maintainers; [ pjones ];
  };
}
