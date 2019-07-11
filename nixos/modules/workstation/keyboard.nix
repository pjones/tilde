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
      export nixpath=${pkgs.xorg.xinput}/bin:${pkgs.gnugrep}/bin:${pkgs.coreutils}/bin
      substituteAll ${../../../support/workstation/keyboard.sh} $out/bin/keyboard.sh
      chmod 0555 $out/bin/keyboard.sh
    '';
  };

  script = pkgs.writeScript "keyboard-setup" ''
    #!${pkgs.runtimeShell}
    export PATH=/run/wrappers/bin:$PATH
    sudo -u pjones ${package}/bin/keyboard.sh "$@"
  '';

in
{
  config = mkIf cfg.isWorkstation {
    services.udev.extraRules = ''
      ACTION=="add",    ATTRS{idVendor}=="feed", ATTRS{idProduct}=="3060", RUN+="${script} add"
      ACTION=="remove", ENV{PRODUCT}=="feed/3060/1", RUN+="${script} rm"
    '';
  };
}
