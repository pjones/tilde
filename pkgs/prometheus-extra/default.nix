{
  stdenvNoCC,
  prometheus,
}:

stdenvNoCC.mkDerivation {
  name = "prometheus-extra";
  src = ./.;

  doCheck = true;

  buildInputs = [
    prometheus.cli
  ];

  checkPhase = ''
    promtool check rules alerts.yml
  '';

  installPhase = ''
    mkdir -p "$out"

    for file in *.yml; do
      install --mode=0444 "$file" "$out"
    done
  '';
}
