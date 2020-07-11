# Support for custom keyboards:
{ config, pkgs, lib, ... }:
let
  cfg = config.pjones.workstation.keyboard;

  package = pkgs.stdenvNoCC.mkDerivation {
    name = "keyboard-script";
    phases = [ "unpackPhase" "installPhase" "fixupPhase" ];
    src = ./.;

    installPhase = ''
      mkdir -p $out/bin
      export nixpath=${pkgs.xorg.xinput}/bin:${pkgs.gnugrep}/bin:${pkgs.coreutils}/bin
      substituteAll ${../support/workstation/keyboard.sh} $out/bin/keyboard.sh
      chmod 0555 $out/bin/keyboard.sh
    '';
  };

  script = pkgs.writeShellScript "keyboard-setup" ''
    export PATH=/run/wrappers/bin:$PATH
    sudo -u pjones ${package}/bin/keyboard.sh "$@"
  '';

in
{
  options.pjones.workstation.keyboard = {
    enable = lib.mkEnableOption "Custom keyboard scripts";
  };

  config = lib.mkIf cfg.enable {
    services.udev.extraRules = ''
      ACTION=="add",    ATTRS{idVendor}=="feed", ATTRS{idProduct}=="3060", RUN+="${script} add"
      ACTION=="remove", ENV{PRODUCT}=="feed/3060/1", RUN+="${script} rm"
    '';
  };
}
