{ stdenv
, lib
, chromium
, fetchFromGitHub
, json-glib
, pkg-config
}:

stdenv.mkDerivation rec {
  pname = "chromium-launcher";
  version = "6";

  src = fetchFromGitHub {
    owner = "foutrelis";
    repo = pname;
    rev = "v${version}";
    sha256 = "1w3d1jn44k5hwda1yvdfpywl8ahymd54wgidgl4s8c72x3byfa90";
  };

  buildInputs = [
    json-glib
    pkg-config
  ];

  postPatch = ''
    substituteInPlace Makefile \
      --replace '/usr/local' "$out" \
      --replace '/usr/lib/$(CHROMIUM_NAME)/$(CHROMIUM_NAME)' "${chromium}/bin/chromium" \
      --replace '$(shell . /etc/os-release; echo $$NAME)' "NixOS"
  '';

  meta = with lib; {
    description = "Chromium launcher with support for Pepper Flash and custom user flags.";
    homepage = "https://github.com/foutrelis/chromium-launcher";
    license = licenses.isc;
    platforms = platforms.linux;
    maintainers = with maintainers; [ pjones ];
  };
}
