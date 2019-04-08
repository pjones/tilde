{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.pjones;

in
{
  config = mkIf cfg.isWorkstation {
    # Helpful packages:
    users.users.pjones.packages = with pkgs; [
      yubikey-personalization
      yubikey-personalization-gui
    ];

    # This allows GnuPG to see/read the Yubikey.
    services.pcscd.enable = true;

    # This might be obsolete now that pcscd is running.
    services.udev.extraRules = ''
      ATTRS{idVendor}=="1050", ATTRS{idProduct}=="0111", MODE="0660", GROUP="wheel", SYMLINK+="yubikey"
    '';
  };
}
