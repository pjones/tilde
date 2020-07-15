{ config
, pkgs
, lib
, ...
}:
let
  cfg = config.pjones.workstation;
in
{
  options.pjones.workstation = {
    enable = lib.mkEnableOption ''
      Enable settings for workstations.

      A workstation is a machine that doesn't necessarily have a GUI
      but may nonetheless have features that are not available on a
      server-like machine.  For example, Bluetooth and printing.
    '';
  };

  config = lib.mkIf cfg.enable {
    # Some other modules to enable by default:
    pjones.workstation.yubikey.enable = lib.mkDefault true;
    pjones.workstation.keyboard.enable = lib.mkDefault true;

    # Bluetooth:
    services.blueman.enable = lib.mkDefault true;

    # Printing:
    services.printing = {
      enable = true;
      drivers = with pkgs; [
        cups-googlecloudprint
      ];
    };
  };
}
