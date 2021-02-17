# Support for custom keyboards:
{ config, pkgs, lib, ... }:
let
  cfg = config.tilde.workstation.keyboard;

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
    sudo -u ${config.tilde.username} ${package}/bin/keyboard.sh "$@"
  '';

  deviceOpts = {
    options = {
      vendor = lib.mkOption {
        type = lib.types.str;
        example = "03EB";
        description = "USB vendor ID provided by lsusb";
      };

      product = lib.mkOption {
        type = lib.types.str;
        example = "2FEF";
        description = "USB product ID provided by lsusb";
      };
    };
  };

in
{
  options.tilde.workstation.keyboard = {
    enable = lib.mkEnableOption "Custom keyboard scripts";

    devices = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule deviceOpts);
      description = "List of keyboard devices";
      default = [
        { vendor = "feed"; product = "3060"; } # Dactyl Manuform Mini
        { vendor = "feed"; product = "0000"; } # Redox
      ];
    };
  };

  config = lib.mkIf false /* FIXME: cfg.enable */ {
    services.udev.extraRules =
      lib.concatMapStringsSep "\n"
        (kbd:
          let
            add = [
              ''SUBSYSTEMS=="usb"''
              ''ACTION=="add"''
              ''ATTRS{idVendor}=="${kbd.vendor}"''
              ''ATTRS{idProduct}=="${kbd.product}"''
              ''TAG+="uaccess"''
              ''RUN{builtin}+="uaccess"''
              ''RUN+="${script} add"''
            ];
            remove = [
              ''SUBSYSTEMS=="usb"''
              ''ACTION=="remove"''
              ''ATTRS{idVendor}=="${kbd.vendor}"''
              ''ATTRS{idProduct}=="${kbd.product}"''
              ''RUN+="${script} rm"''
            ];
          in
          lib.concatStringsSep "," add + "\n" + lib.concatStringsSep "," remove)
        cfg.devices;
  };
}
