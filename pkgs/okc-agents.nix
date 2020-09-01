{ rustPlatform
, fetchFromGitHub
, lib
}:
rustPlatform.buildRustPackage rec {
  pname = "okc-agents";
  version = "0.1.1";

  src = fetchFromGitHub {
    owner = "DDoSolitary";
    repo = pname;
    rev = "v${version}";
    sha256 = "0k90qsmvink3n0z7a4i6fm703hy45xkkbagids6p127xwki1zw3k";
  };

  cargoSha256 = "0llpqgrvl6qg9pzwfmr9x11mi4kdxc5gkaxbqf96bsaswa0fi3br";
  verifyCargoDeps = true;

  meta = with lib; {
    description = "A utility that makes OpenKeychain available in your Termux shell";
    homepage = "https://github.com/DDoSolitary/okc-agents";
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = with maintainers; [ pjones ];
  };
}
