# Support for custom keyboards:
{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.pjones;

  package = pkgs.stdenvNoCC.mkDerivation {
    name = "keyboard-script";
    phases = [ "unpackPhase" "installPhase" "fixupPhase" ];
    src = ./.;

    installPhase = ''
      mkdir -p $out/bin
      install -m 0555 ${../../../support/workstation/keyboard.sh} $out/bin/keyboard.sh
    '';
  };

  script = pkgs.writeScript "keyboard-setup" ''
    sudo -u pjones ${package}/bin/keyboard.sh
  '';

in
{
  config = mkIf cfg.isWorkstation {
    services.udev.extraRules = ''
      ATTRS{idVendor}=="0xfeed", ATTRS{idProduct}=="0x3060", RUN+="${script}"
    '';
  };
}
