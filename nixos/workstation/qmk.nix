{ config, pkgs, lib, ... }:
let
  cfg = config.tilde.workstation;

  # udev properties that need to be set for each keyboard:
  qmkUdevProps = [
    ''TAG+="uaccess"''
    ''SYMLINK+="ttyQMK"''
    ''GROUP:="input"''
    ''MODE:="0660"''
    ''ENV{ID_MM_DEVICE_IGNORE}="1"''
  ];

  # Build a udev rule for the following keybaord/chip:
  qmkRule = { vendor, product }:
    let props = [
      ''SUBSYSTEMS=="usb"''
      ''ATTRS{idVendor}=="${vendor}"''
      ''ATTRS{idProduct}=="${product}"''
    ] ++ qmkUdevProps;
    in lib.concatStringsSep "," props;

  # A list of keyboard chips that we want to build udev rules for:
  qmkChips = [
    { vendor = "03eb"; product = "2ff4"; }
  ];

  # Build one udev rule for each given chip:
  mkUdevRules = chips:
    lib.concatStringsSep "\n" (map qmkRule chips);
in
{
  config = lib.mkIf cfg.enable {
    services.udev.extraRules = mkUdevRules qmkChips;
  };
}
