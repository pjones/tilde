{ stdenvNoCC
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

  meta = with stdenvNoCC.lib; {
    description = "Color material cursors for your Linux desktop with cute animation.";
    homepage = "https://github.com/varlesh/oreo-cursors";
    license = licenses.gpl2;
    platforms = platforms.linux;
    maintainers = with maintainers; [ pjones ];
  };
}
